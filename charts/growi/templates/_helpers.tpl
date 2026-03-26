{{/*
Expand the name of the chart.
*/}}
{{- define "growi.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "growi.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart label string.
*/}}
{{- define "growi.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "growi.labels" -}}
helm.sh/chart: {{ include "growi.chart" . }}
{{ include "growi.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "growi.selectorLabels" -}}
app.kubernetes.io/name: {{ include "growi.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Elasticsearch fullname
*/}}
{{- define "growi.elasticsearch.fullname" -}}
{{- printf "%s-elasticsearch" (include "growi.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Elasticsearch labels
*/}}
{{- define "growi.elasticsearch.labels" -}}
helm.sh/chart: {{ include "growi.chart" . }}
{{ include "growi.elasticsearch.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "growi.elasticsearch.selectorLabels" -}}
app.kubernetes.io/name: {{ include "growi.name" . }}-elasticsearch
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
PDF Converter fullname
*/}}
{{- define "growi.pdfConverter.fullname" -}}
{{- printf "%s-pdf-converter" (include "growi.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
PDF Converter labels
*/}}
{{- define "growi.pdfConverter.labels" -}}
helm.sh/chart: {{ include "growi.chart" . }}
{{ include "growi.pdfConverter.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "growi.pdfConverter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "growi.name" . }}-pdf-converter
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
MongoDB URI: use provided value or auto-generate from bitnami subchart
*/}}
{{- define "growi.mongoUri" -}}
{{- if .Values.growi.mongoUri }}
{{- .Values.growi.mongoUri }}
{{- else if .Values.mongodb.enabled }}
{{- printf "mongodb://%s-mongodb:27017/growi" .Release.Name }}
{{- else }}
{{- fail "growi.mongoUri must be set when mongodb.enabled=false" }}
{{- end }}
{{- end }}

{{/*
Elasticsearch URI: use provided value or auto-generate
*/}}
{{- define "growi.elasticsearchUri" -}}
{{- if .Values.growi.elasticsearchUri }}
{{- .Values.growi.elasticsearchUri }}
{{- else if .Values.elasticsearch.enabled }}
{{- printf "http://%s:9200/growi" (include "growi.elasticsearch.fullname" .) }}
{{- else }}
{{- "" }}
{{- end }}
{{- end }}

{{/*
PDF Converter URI
*/}}
{{- define "growi.pdfConverterUri" -}}
{{- if .Values.pdfConverter.enabled }}
{{- printf "http://%s:%d" (include "growi.pdfConverter.fullname" .) (int .Values.pdfConverter.service.port) }}
{{- else }}
{{- "" }}
{{- end }}
{{- end }}

{{/*
ServiceAccount name
*/}}
{{- define "growi.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "growi.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Validate required values
*/}}
{{- define "growi.validateValues" -}}
{{- if not .Values.growi.passwordSeed }}
{{- fail "growi.passwordSeed is required. Generate with: openssl rand -hex 32" }}
{{- end }}
{{- if not .Values.growi.secretToken }}
{{- fail "growi.secretToken is required. Generate with: openssl rand -hex 32" }}
{{- end }}
{{- end }}
