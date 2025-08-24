# eevee Helm chart

## Add helm repo

```bash
helm repo add eevee https://helm.eevee.bot/
helm search repo eevee
```

## Configure values.yaml

See [charts/eevee/values.yaml](charts/eevee/valyes.yaml) for details

## Helm install

```bash
helm install --upgrade eevee eevee/eevee --values eevee-values.yaml
```
