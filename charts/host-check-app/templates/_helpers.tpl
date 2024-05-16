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
Standard labels
*/}}
{{- define "hostCheck.labels" -}}
helm.sh/chart: {{ include "hostCheck.chart" . }}
app.kubernetes.io/name: {{ include "hostCheck.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Runtime arguments. If both xrd-control-plane and xrd-vrouter are specified,
the argument is not set.
*/}}
{{- define "hostCheck.args" -}}
{{- if not .Values.platforms }}
  {{- fail "Platforms must be specified" }}
{{- end }}
{{- range $platform := .Values.platforms }}
{{- if and (not (eq $platform "xrd-control-plane")) (not (eq $platform "xrd-vrouter")) }}
  {{- fail "Invalid platform specified: must be one of xrd-control-plane or xrd-vrouter" }}
{{- end }}
{{- end }}
{{- $arg := "" }}
{{- if eq (len .Values.platforms) 1 }}
  {{- $arg = printf "-p%s" (.Values.platforms | first) }}
{{- end }}
{{- $arg }}
{{- end }}
