{{/*
Expand the name of the chart.
*/}}
{{- define "hostCheck.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "hostCheck.fullname" -}}
{{- if contains .Chart.Name .Release.Name }}
  {{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
  {{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "hostCheck.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "hostCheck.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hostCheck.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Standard labels
*/}}
{{- define "hostCheck.labels" -}}
helm.sh/chart: {{ include "hostCheck.chart" . }}
{{ include "hostCheck.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Common labels for all mutable resources
*/}}
{{- define "hostCheck.commonLabels" -}}
{{- include "hostCheck.labels" . }}
{{- /* Merge has left-precedence (i.e. things in common override things in global). */}}
{{- $cLabels := merge .Values.commonLabels .Values.global.labels }}
{{- if $cLabels }}
{{ $cLabels | toYaml }}
{{- end }}
{{- end -}}

{{/*
Common labels for immutable resources
*/}}
{{- define "hostCheck.commonImmutableLabels" -}}
{{- include "hostCheck.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with (merge .Values.commonLabels .Values.global.labels) }}
{{ toYaml . }}
{{- end }}
{{- end -}}
