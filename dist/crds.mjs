import * as cdk8splus from 'cdk8s-plus-33';
import * as cdk8s from 'cdk8s';
const outdir = '../dist/manifests/crds';
const suffix = '-crds.yaml';
const namespace = 'eevee-system';
const image = 'ghcr.io/eeveebot/crds:latest';
export class CrdJob extends cdk8s.Chart {
    constructor(scope, id, props = {
        disableResourceNameHashes: true,
        namespace: namespace,
    }) {
        super(scope, id, props);
        const crdJobRole = new cdk8splus.Role(this, 'crd-job-role');
        crdJobRole.allowReadWrite(cdk8splus.ApiResource.CUSTOM_RESOURCE_DEFINITIONS);
        const serviceAccount = new cdk8splus.ServiceAccount(this, 'crd-job-service-account');
        const roleBinding = new cdk8splus.RoleBinding(this, 'crd-job-role-binding', {
            metadata: {
                name: 'eevee-crd-job-rolebinding',
                namespace: namespace,
            },
            role: crdJobRole,
        });
        roleBinding.addSubjects(serviceAccount);
        const crdJob = new cdk8splus.Job(this, 'crd-job', {
            metadata: {
                labels: {
                    'eevee.bot/crds': 'true',
                },
            },
            automountServiceAccountToken: true,
            serviceAccount: serviceAccount,
            select: true,
            containers: [
                {
                    image: image,
                    envVariables: {
                        KUBE_IN_CLUSTER_CONFIG: cdk8splus.EnvValue.fromValue('true'),
                    },
                },
            ],
            ttlAfterFinished: cdk8s.Duration.seconds(600),
        });
    }
}
const app = new cdk8s.App({
    outputFileExtension: suffix,
    outdir: outdir,
});
new CrdJob(app, 'eevee');
app.synth();
