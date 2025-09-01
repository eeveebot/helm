# eevee Helm chart

> eevee, the lovable chatbot framework!

## What is eevee?

eevee is a microservices architecture chatbot framework that lives in k8s \
and consists of independent modules that communicate through a common message bus, NATS

---

## Helpful Links

| **Link**
| ---
| [**Homepage**](https://eevee.bot/)
| [**Documentation**](https://eevee.bot/docs)
| [**Helm Repo**](https://helm.eevee.bot)
| [**Helm Git Repo**](https://github.com/eeveebot/helm)
| [**MetaRepo**](https://github.com/eeveebot/eevee)
| [**Operator**](https://github.com/eeveebot/operator)
| [**Connector-IRC**](https://github.com/eeveebot/connector-irc)
| [**Toolbox**](https://github.com/eeveebot/toolbox)
| [**CLI**](https://github.com/eeveebot/cli)

---

## Getting Started

Check out [docs/helm](https://eevee.bot/docs/helm) for setup instructions.

## Add helm repo

```bash
helm repo add eevee https://helm.eevee.bot/
helm search repo eevee
```

## Configure values.yaml

See [charts/eevee/values.yaml](charts/eevee/values.yaml) for details on the core eevee chart

See [charts/eevee-crds/values.yaml](charts/eevee-crds/values.yaml) for details on the eeevee-crds chart

See [charts/eevee-operator/values.yaml](charts/eevee-operator/values.yaml) for details on the eeevee-operator chart

See [charts/eevee-bot/values.yaml](charts/eevee-bot/values.yaml) for details on the eeevee-bot chart

## Helm install

```bash
# The core "eevee" chart brings in "eevee-crds", "eevee-operator", and "eevee-bot" as dependencies
helm upgrade --install eevee eevee/eevee --values eevee-values.yaml

# Alternatively, install the component subcharts on their own
helm upgrade --install eevee-bot eevee/eevee-crds --values eevee-crds-values.yaml
helm upgrade --install eevee-operator eevee/eevee-operator --values eevee-operator-values.yaml
helm upgrade --install eevee-bot eevee/eevee-bot --values eevee-bot-values.yaml
```

---

## License

All eevee components are covered under `Attribution-NonCommercial-ShareAlike 4.0 International`

See [LICENSE](https://github.com/eeveebot/eevee/blob/main/LICENSE) for details.
