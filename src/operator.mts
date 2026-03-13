import { Construct } from 'constructs';
import * as cdk8splus from 'cdk8s-plus-33';
import * as cdk8s from 'cdk8s';

import { eevee } from '@eeveebot/crds';

const outdir: string = '../dist/manifests/operator';
const suffix: string = '-operator.yaml';

const namespace: string = 'eevee-system';

const image: string = 'ghcr.io/eeveebot/operator:latest';

const httpApiPort: number = 9000;

export class Operator extends cdk8s.Chart {
  constructor(
    scope: Construct,
    id: string,
    props: cdk8s.ChartProps = {
      disableResourceNameHashes: true,
      namespace: namespace,
    }
  ) {
    super(scope, id, props);

    const operatorRole = new cdk8splus.Role(this, 'eevee-operator-role',
      {
        metadata: {
          name: 'eevee-operator-role',
          namespace: namespace,
          labels: {
            'eevee.bot/operator': 'true',
          },
        },
      }
    );

    const operatorClusterRole = new cdk8splus.ClusterRole(this, 'eevee-operator-cluster-role',
      {
        metadata: {
          name: 'eevee-operator-cluster-role',
          labels: {
            'eevee.bot/operator': 'true',
          },
        },
      }
    )

    operatorRole.allowReadWrite(
      cdk8splus.ApiResource.CONFIG_MAPS,
      cdk8splus.ApiResource.CRON_JOBS,
      cdk8splus.ApiResource.CUSTOM_RESOURCE_DEFINITIONS,
      cdk8splus.ApiResource.DEPLOYMENTS,
      cdk8splus.ApiResource.DAEMON_SETS,
      cdk8splus.ApiResource.JOBS,
      cdk8splus.ApiResource.LEASES,
      cdk8splus.ApiResource.PERSISTENT_VOLUME_CLAIMS,
      cdk8splus.ApiResource.PODS,
      cdk8splus.ApiResource.REPLICA_SETS,
      cdk8splus.ApiResource.SECRETS,
      cdk8splus.ApiResource.SERVICES,
      cdk8splus.ApiResource.STATEFUL_SETS,
      cdk8splus.ApiResource.INGRESSES,
      new eevee.ChatConnectionIrc.ApiResource,
      new eevee.IpcConfig.ApiResource,
      new eevee.Toolbox.ApiResource,
    );

    operatorRole.allowWatch(
      cdk8splus.ApiResource.CONFIG_MAPS,
      cdk8splus.ApiResource.CRON_JOBS,
      cdk8splus.ApiResource.CUSTOM_RESOURCE_DEFINITIONS,
      cdk8splus.ApiResource.DEPLOYMENTS,
      cdk8splus.ApiResource.DAEMON_SETS,
      cdk8splus.ApiResource.JOBS,
      cdk8splus.ApiResource.LEASES,
      cdk8splus.ApiResource.PERSISTENT_VOLUME_CLAIMS,
      cdk8splus.ApiResource.PODS,
      cdk8splus.ApiResource.REPLICA_SETS,
      cdk8splus.ApiResource.SECRETS,
      cdk8splus.ApiResource.SERVICES,
      cdk8splus.ApiResource.STATEFUL_SETS,
      cdk8splus.ApiResource.INGRESSES,
      new eevee.ChatConnectionIrc.ApiResource,
      new eevee.IpcConfig.ApiResource,
      new eevee.Toolbox.ApiResource,
    );

    operatorClusterRole.allowReadWrite(
      cdk8splus.ApiResource.CONFIG_MAPS,
      cdk8splus.ApiResource.CRON_JOBS,
      cdk8splus.ApiResource.CUSTOM_RESOURCE_DEFINITIONS,
      cdk8splus.ApiResource.DEPLOYMENTS,
      cdk8splus.ApiResource.DAEMON_SETS,
      cdk8splus.ApiResource.JOBS,
      cdk8splus.ApiResource.LEASES,
      cdk8splus.ApiResource.PERSISTENT_VOLUME_CLAIMS,
      cdk8splus.ApiResource.PODS,
      cdk8splus.ApiResource.REPLICA_SETS,
      cdk8splus.ApiResource.SECRETS,
      cdk8splus.ApiResource.SERVICES,
      cdk8splus.ApiResource.STATEFUL_SETS,
      cdk8splus.ApiResource.INGRESSES,
      new eevee.ChatConnectionIrc.ApiResource,
      new eevee.IpcConfig.ApiResource,
      new eevee.Toolbox.ApiResource,
    );

    operatorClusterRole.allowWatch(
      cdk8splus.ApiResource.CONFIG_MAPS,
      cdk8splus.ApiResource.CRON_JOBS,
      cdk8splus.ApiResource.CUSTOM_RESOURCE_DEFINITIONS,
      cdk8splus.ApiResource.DEPLOYMENTS,
      cdk8splus.ApiResource.DAEMON_SETS,
      cdk8splus.ApiResource.JOBS,
      cdk8splus.ApiResource.LEASES,
      cdk8splus.ApiResource.PERSISTENT_VOLUME_CLAIMS,
      cdk8splus.ApiResource.PODS,
      cdk8splus.ApiResource.REPLICA_SETS,
      cdk8splus.ApiResource.SECRETS,
      cdk8splus.ApiResource.SERVICES,
      cdk8splus.ApiResource.STATEFUL_SETS,
      cdk8splus.ApiResource.INGRESSES,
      new eevee.ChatConnectionIrc.ApiResource,
      new eevee.IpcConfig.ApiResource,
      new eevee.Toolbox.ApiResource,
    );

    operatorRole.allowRead(
      cdk8splus.ApiResource.INGRESS_CLASSES,
      cdk8splus.ApiResource.NAMESPACES,
      cdk8splus.ApiResource.NODES,
      cdk8splus.ApiResource.VOLUME_ATTACHMENTS,
    );

    const serviceAccount = new cdk8splus.ServiceAccount(
      this,
      'eevee-operator-service-account',
      {
        metadata: {
          name: 'eevee-operator-service-account',
          namespace: namespace,
          labels: {
            'eevee.bot/operator': 'true',
          },
        },
      }
    );

    const roleBinding = new cdk8splus.RoleBinding(
      this,
      'eevee-operator-role-binding',
      {
        metadata: {
          name: 'eevee-operator-role-binding',
          namespace: namespace,
          labels: {
            'eevee.bot/operator': 'true',
          },
        },
        role: operatorRole,
      }
    );

    roleBinding.addSubjects(serviceAccount);

    const clusterRoleBinding = new cdk8splus.ClusterRoleBinding(
      this,
      'eevee-operator-cluster-role-binding',
      {
        metadata: {
          name: 'eevee-operator-cluster-role-binding',
          labels: {
            'eevee.bot/operator': 'true',
          },
        },
        role: operatorClusterRole,
      }
    )

    clusterRoleBinding.addSubjects(serviceAccount);

    const operatorDeployment = new cdk8splus.Deployment(this, 'operator', {
      metadata: {
        name: 'operator',
        namespace: namespace,
        labels: {
          'eevee.bot/operator': 'true',
        },
      },
      automountServiceAccountToken: true,
      serviceAccount: serviceAccount,
      select: false,
      containers: [
        {
          name: 'operator',
          image: image,
          ports: [
            {
              name: 'http',
              protocol: cdk8splus.Protocol.TCP,
              number: httpApiPort,
            },
          ],
          envVariables: {
            KUBE_IN_CLUSTER_CONFIG: cdk8splus.EnvValue.fromValue('true'),
            WATCH_OTHER_NAMESPACES: cdk8splus.EnvValue.fromValue('false'),
          },
          securityContext: {
            user: 1000,
            group: 1000,
          },
        },
      ],
      replicas: 1,
    });

    operatorDeployment.exposeViaService({
      ports: [
        {
          port: httpApiPort,
          targetPort: httpApiPort,
        },
      ],
      serviceType: cdk8splus.ServiceType.CLUSTER_IP,
    });
  }
}

const app = new cdk8s.App({
  outputFileExtension: suffix,
  outdir: outdir,
});
new Operator(app, 'eevee');
app.synth();
