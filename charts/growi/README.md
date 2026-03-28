# GROWI Helm Chart

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/growi)](https://artifacthub.io/packages/search?repo=growi)

Helm chart for [GROWI](https://growi.org) v7.x — Team Knowledge Base (Wiki).

## Components

| Component | Image | Notes |
|---|---|---|
| GROWI App | `growilabs/growi:7` | Node.js wiki app |
| MongoDB | bitnami/mongodb ~18 | Primary datastore |
| Elasticsearch | `docker.elastic.co/elasticsearch/elasticsearch:9.0.1` | Full-text search |
| PDF Converter | `growilabs/pdf-converter:1` | Bulk page export to PDF |

> kuromoji / ICU Analysis plugins are automatically installed into Elasticsearch via initContainer.

---

## Prerequisites

- Kubernetes 1.25+
- Helm 3.14+ (MongoDB subchart requires OCI registry support)
- PersistentVolume provisioner

---

## Installation

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

> ⚠️ **`growi.passwordSeed` must never be changed after installation.**
> It is used to hash all user passwords in MongoDB. Changing it invalidates all existing passwords.

On first access you will be redirected to `/installer` to complete the initial setup.

---

## Upgrade

Always check the [GROWI Upgrade Guide](https://docs.growi.org/en/admin-guide/) before upgrading.

```bash
helm upgrade my-growi 4nm1tsu/growi \
  --namespace growi \
  --values my-values.yaml \
  --set growi.passwordSeed="<your-seed>" \
  --set growi.secretToken="<your-token>"
```

After upgrading, rebuild the Elasticsearch index:
**Admin → Full-text Search Management → Normalize Indices**

---

## Configuration Examples

### nginx Ingress + cert-manager

```yaml
growi:
  siteUrl: "https://growi.example.com"
  trustProxy: true

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
  hosts:
    - host: growi.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - hosts:
        - growi.example.com
      secretName: letsencrypt-cert-growi
```

### External MongoDB

```yaml
mongodb:
  enabled: false

growi:
  mongoUri: "mongodb://user:pass@my-mongo-host:27017/growi"
```

### External Elasticsearch

```yaml
elasticsearch:
  enabled: false

growi:
  elasticsearchUri: "http://my-es-host:9200/growi"
```

### File Upload to AWS S3

```yaml
growi:
  fileUpload: aws
  extraEnv:
    - name: AWS_ACCESS_KEY_ID
      valueFrom:
        secretKeyRef:
          name: my-aws-secret
          key: access-key-id
    - name: AWS_SECRET_ACCESS_KEY
      valueFrom:
        secretKeyRef:
          name: my-aws-secret
          key: secret-access-key
    - name: AWS_S3_BUCKET_NAME
      value: my-growi-bucket
    - name: AWS_S3_REGION
      value: ap-northeast-1
```

## Parameters

### GROWI App

| Parameter | Description | Default |
|---|---|---|
| `image.repository` | GROWI image | `growilabs/growi` |
| `image.tag` | Image tag | `"7"` |
| `replicaCount` | Number of replicas | `1` |
| `growi.passwordSeed` | Password hash seed (**required, never change**) | `""` |
| `growi.secretToken` | Cookie signing secret (**required**) | `""` |
| `growi.siteUrl` | Site URL (required behind proxy) | `""` |
| `growi.trustProxy` | Trust proxy headers | `false` |
| `growi.mongoUri` | MongoDB URI (auto-generated if empty) | `""` |
| `growi.elasticsearchUri` | ES URI (auto-generated if empty) | `""` |
| `growi.fileUpload` | Storage backend (`aws`/`gcs`/`azure`/`mongodb`/`local`) | `local` |
| `growi.forceWikiMode` | Force wiki mode (`public`/`private`) | `""` |
| `growi.openTelemetryEnabled` | Enable OpenTelemetry | `false` |
| `growi.extraEnv` | Extra environment variables | `[]` |
| `growi.extraEnvFrom` | Extra envFrom (SecretRef etc.) | `[]` |

### Persistence

| Parameter | Description | Default |
|---|---|---|
| `persistence.data.size` | GROWI data PVC size | `10Gi` |
| `persistence.data.storageClass` | Storage class | `""` |
| `persistence.bulkExport.size` | Bulk export temp PVC size | `2Gi` |

### Elasticsearch

| Parameter | Description | Default |
|---|---|---|
| `elasticsearch.enabled` | Deploy Elasticsearch | `true` |
| `elasticsearch.image.tag` | ES version | `9.0.1` |
| `elasticsearch.javaOpts` | Heap size | `-Xms256m -Xmx256m` |
| `elasticsearch.persistence.size` | PVC size | `10Gi` |
| `elasticsearch.sysctlInitContainer.enabled` | Auto-set `vm.max_map_count` | `true` |

### MongoDB

| Parameter | Description | Default |
|---|---|---|
| `mongodb.enabled` | Deploy MongoDB | `true` |
| `mongodb.persistence.size` | PVC size | `8Gi` |

### PDF Converter

| Parameter | Description | Default |
|---|---|---|
| `pdfConverter.enabled` | Deploy PDF Converter | `true` |

---

## Notes

### Helm Version Requirement

Helm **3.14+** is required because the MongoDB subchart is distributed via OCI registry (`oci://registry-1.docker.io/bitnamicharts`).

### vm.max_map_count

Elasticsearch requires `vm.max_map_count=262144`. A privileged initContainer sets this automatically when `elasticsearch.sysctlInitContainer.enabled=true`.

If your cluster policy prohibits privileged containers, configure nodes manually and disable the initContainer:

```bash
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

```yaml
elasticsearch:
  sysctlInitContainer:
    enabled: false
```

### PDF Converter

The PDF Converter uses puppeteer (headless Chromium) internally. This chart mounts a 256Mi tmpfs at `/dev/shm` to prevent Chromium from crashing due to shared memory limits in Kubernetes.

If you do not need bulk PDF export, you can disable it:

```yaml
pdfConverter:
  enabled: false
```

---

## License

MIT
