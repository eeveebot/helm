# eevee Helm chart

[github/eeveebot/helm](https://github.com/eeveebot/helm)

[github/eeveebot/eevee](https://github.com/eeveebot/eevee)

[eevee.bot](https://eevee.bot)

[eevee.bot/docs](https://eevee.bot/docs)

## Add helm repo

```bash
helm repo add eevee https://helm.eevee.bot/
helm search repo eevee
```

## Configure values.yaml

See [charts/eevee/values.yaml](charts/eevee/values.yaml) for details

## Helm install

```bash
helm install --upgrade eevee eevee/eevee --values eevee-values.yaml
```
