# growi-helm-chart

Unofficial Growi helm charts repository.

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/growi)](https://artifacthub.io/packages/search?repo=growi)

## Charts

| Chart | Description |
|---|---|
| [growi](charts/growi/README.md) | GROWI - Team Knowledge Base (Wiki) |

## Usage

```bash
helm repo add 4nm1tsu https://4nm1tsu.github.io/growi-helm-chart/
helm repo update

helm install my-growi 4nm1tsu/growi \
  --namespace growi --create-namespace \
  --set growi.passwordSeed=$(openssl rand -hex 32) \
  --set growi.secretToken=$(openssl rand -hex 32) \
  --set growi.siteUrl=https://growi.example.com \
  --set growi.trustProxy=true
```
