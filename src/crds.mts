import { Construct } from 'constructs';
import * as cdk8splus from 'cdk8s-plus-33';
import * as cdk8s from 'cdk8s';

import { eevee } from '@eeveebot/crds';

const outdir: string = '../dist/manifests/crds';
const suffix: string = '-crds.yaml';

const namespace: string = 'eevee-system';

const image: string = 'ghcr.io/eeveebot/crds:1.3.0';

export class CrdJob extends cdk8s.Chart {
  constructor(
    scope: Construct,
    id: string,
    props: cdk8s.ChartProps = {
      disableResourceNameHashes: true,
      namespace: namespace,
    }
  ) {
    super(scope, id, props);

    const crdJobRole = new cdk8splus.Role(this, 'crd-job-role');

    const crdJobClusterRole = new cdk8splus.ClusterRole(this, 'crd-job-cluster-role');

    crdJobRole.allowReadWrite(
      new eevee.BotModule.ApiResource,
      new eevee.IpcConfig.ApiResource,
    );

    crdJobClusterRole.allowReadWrite(
      cdk8splus.ApiResource.CUSTOM_RESOURCE_DEFINITIONS,
    );

    const serviceAccount = new cdk8splus.ServiceAccount(
      this,
      'crd-job-service-account'
    );

    const roleBinding = new cdk8splus.RoleBinding(
      this,
      'crd-job-role-binding',
      {
        metadata: {
          name: 'crd-job-role-binding',
          namespace: namespace,
        },
        role: crdJobRole,
      }
    );

    const clusterRoleBinding = new cdk8splus.ClusterRoleBinding(
      this,
      'crd-job-cluster-role-binding',
      {
        metadata: {
          name: 'crd-job-cluster-role-binding',
        },
        role: crdJobClusterRole,
      }
    );

    roleBinding.addSubjects(serviceAccount);
    clusterRoleBinding.addSubjects(serviceAccount);

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
          securityContext: {
            user: 1000,
            group: 1000,
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
