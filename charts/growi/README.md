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

### 1. Dependency update

```bash
helm dependency update .
```

### 2. Install

```bash
helm install my-growi . \
  --namespace growi --create-namespace \
  --set growi.passwordSeed=$(openssl rand -hex 32) \
  --set growi.secretToken=$(openssl rand -hex 32) \
  --set growi.siteUrl=https://growi.example.com \
  --set growi.trustProxy=true
```

> ⚠️ **`growi.passwordSeed` must never be changed after installation.**
> It is used to hash all user passwords in MongoDB. Changing it invalidates all existing passwords.

### 3. First run

On first access you will be redirected to `/installer` to complete the initial setup.

### 4. Run tests

```bash
helm test my-growi -n growi
```

---

## Upgrade

Always check the [GROWI Upgrade Guide](https://docs.growi.org/en/admin-guide/) before upgrading.

```bash
helm upgrade my-growi . \
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

### NFS Static Provisioning

Create directories on your NFS server first:

```bash
sudo mkdir -p /k8s/growi/{data,bulk-export,mongodb,elasticsearch}
sudo chmod 777 /k8s/growi/{data,bulk-export,mongodb,elasticsearch}
```

Apply PersistentVolumes (adjust NFS server IP and release name):

```yaml
# pv-growi-data
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-growi-data
spec:
  storageClassName: growi-data
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  nfs:
    server: 192.168.1.x
    path: /k8s/growi/data
---
# pv-growi-bulk-export
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-growi-bulk-export
spec:
  storageClassName: growi-bulk-export
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  nfs:
    server: 192.168.1.x
    path: /k8s/growi/bulk-export
---
# MongoDB PVC name = "<release-name>-mongodb"
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-growi-mongodb
spec:
  storageClassName: growi-mongodb
  capacity:
    storage: 8Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  claimRef:
    namespace: growi
    name: my-growi-mongodb        # ← <release-name>-mongodb
  nfs:
    server: 192.168.1.x
    path: /k8s/growi/mongodb
---
# ES PVC name = "es-data-<release-name>-elasticsearch-0"
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-growi-elasticsearch
spec:
  storageClassName: growi-elasticsearch
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  claimRef:
    namespace: growi
    name: es-data-my-growi-elasticsearch-0   # ← es-data-<release-name>-elasticsearch-0
  nfs:
    server: 192.168.1.x
    path: /k8s/growi/elasticsearch
```

Then set storageClass in values:

```yaml
persistence:
  data:
    storageClass: "growi-data"
  bulkExport:
    storageClass: "growi-bulk-export"

mongodb:
  persistence:
    storageClass: "growi-mongodb"

elasticsearch:
  persistence:
    storageClass: "growi-elasticsearch"
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

### Authentik OIDC

OIDC is configured via the GROWI Admin UI after deployment (`/admin/security`).

In Authentik, create an OAuth2/OpenID Connect provider with:

| Field | Value |
|---|---|
| Redirect URI | `https://growi.example.com/passport/oidc/callback` |

Then in GROWI Admin → Security Settings → OIDC tab:

| Field | Value |
|---|---|
| Issuer | `https://authentik.example.com/application/o/<slug>/` |
| Authorization Endpoint | `https://authentik.example.com/application/o/authorize/` |
| Token Endpoint | `https://authentik.example.com/application/o/token/` |
| User Info Endpoint | `https://authentik.example.com/application/o/userinfo/` |
| JWKS URL | `https://authentik.example.com/application/o/<slug>/jwks/` |
| Identifier | `sub` |
| username | `preferred_username` |
| name | `preferred_username` |
| email | `email` |

---

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
# On each node
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
