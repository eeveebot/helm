# eevee Helm chart

> eevee, the lovable chatbot framework!

## Helpful Links

[**Homepage**](https://eevee.bot/)

[**Helm Repo**](https://helm.eevee.bot)

[**Documentation**](https://eevee.bot/docs)

[**MetaRepo**](https://github.com/eeveebot/eevee)

[**Operator**](https://github.com/eeveebot/operator)

[**Connector-IRC**](https://github.com/eeveebot/connector-irc)

[**Toolbox**](https://github.com/eeveebot/toolbox)

[**CLI**](https://github.com/eeveebot/cli)

## Getting Started

Check out [quickstart/gettting-started](https://eevee.bot/docs/quickstart/getting-started/) for setup instructions.

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

## License

All eevee components are covered under `Attribution-NonCommercial-ShareAlike 4.0 International`

See [LICENSE](https://github.com/eeveebot/eevee/blob/main/LICENSE) for details.
