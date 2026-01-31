{{/*
Expand the name of the chart.
*/}}
{{- define "belizechain.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "belizechain.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "belizechain.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "belizechain.labels" -}}
helm.sh/chart: {{ include "belizechain.chart" . }}
{{ include "belizechain.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "belizechain.selectorLabels" -}}
app.kubernetes.io/name: {{ include "belizechain.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "belizechain.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "belizechain.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
PostgreSQL connection string
*/}}
{{- define "belizechain.postgresConnectionString" -}}
{{- printf "postgresql://%s:%s@postgres.%s.svc.cluster.local:5432/%s" .Values.postgresql.config.username .Values.secrets.postgresPassword .Release.Namespace .Values.postgresql.config.database }}
{{- end }}

{{/*
Redis connection string
*/}}
{{- define "belizechain.redisConnectionString" -}}
{{- if .Values.secrets.redisPassword }}
{{- printf "redis://:%s@redis.%s.svc.cluster.local:6379/0" .Values.secrets.redisPassword .Release.Namespace }}
{{- else }}
{{- printf "redis://redis.%s.svc.cluster.local:6379/0" .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Blockchain RPC WebSocket URL
*/}}
{{- define "belizechain.blockchainRpcUrl" -}}
{{- printf "ws://belizechain-node.%s.svc.cluster.local:9944" .Release.Namespace }}
{{- end }}

{{/*
IPFS API URL
*/}}
{{- define "belizechain.ipfsApiUrl" -}}
{{- printf "http://ipfs.%s.svc.cluster.local:5001" .Release.Namespace }}
{{- end }}
