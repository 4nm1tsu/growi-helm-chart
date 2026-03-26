# helm-charts

Unofficial Growi helm charts repository.

## Charts

| Chart | Description |
|---|---|
| [growi](charts/growi/README.md) | GROWI - Team Knowledge Base (Wiki) |

## Usage

```bash
helm repo add 4nm1tsu https://4nm1tsu.github.io/helm-charts/
helm repo update
helm install my-growi 4nm1tsu/growi \
  --set growi.passwordSeed=$(openssl rand -hex 32) \
  --set growi.secretToken=$(openssl rand -hex 32)
```

