{{/*
Expand the name of the chart.
*/}}
{{- define "xrd.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "xrd.fullname" -}}
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
{{- define "xrd.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "xrd.selectorLabels" -}}
app.kubernetes.io/name: {{ include "xrd.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Standard labels
*/}}
{{- define "xrd.labels" -}}
helm.sh/chart: {{ include "xrd.chart" . }}
{{ include "xrd.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Common labels for all mutable resources
*/}}
{{- define "xrd.commonLabels" -}}
{{- include "xrd.labels" . }}
{{- /* Merge has left-precedence (i.e. things in common override things in global). */}}
{{- $cLabels := merge .Values.commonLabels .Values.global.labels }}
{{- if $cLabels }}
{{ $cLabels | toYaml }}
{{- end }}
{{- end -}}

{{/*
Common labels for immutable resources
*/}}
{{- define "xrd.commonImmutableLabels" -}}
{{- include "xrd.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with (merge .Values.commonLabels .Values.global.labels) }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{/*
Common annotations for all resources
*/}}
{{- define "xrd.commonAnnotations" -}}
{{- /* Merge has left-precedence. */}}
{{- $cAnnotations := merge .Values.commonAnnotations .Values.global.annotations }}
{{- if $cAnnotations }}
{{- $cAnnotations | toYaml }}
{{- end }}
{{- end -}}

{{- /* Misc helpers */ -}}
{{- define "xrd.toMiB" -}}
{{- /*
Convert a k8s resource specification of Mi or Gi into MiB for XR env vars.
*/ -}}
{{- if hasSuffix "Mi" . -}}
{{ trimSuffix "Mi" . }}
{{- else if hasSuffix "Gi" . -}}
{{ . | trimSuffix "Gi" | trim | int | mul 1024 | toString }}
{{- end -}}
{{- end -}}

{{- define "xrd.hasConfig" -}}
{{- if and (not .Values.config.username) (.Values.config.password) }}
{{- fail "username must be specified if password specified" }}
{{- end }}
{{- if and (.Values.config.username) (not .Values.config.password) }}
{{- fail "password must be specified if username specified" }}
{{- end }}
{{- $out := "false" }}
{{- if or .Values.config.username .Values.config.ascii .Values.config.script .Values.config.ztpIni -}}
{{- $out = "true" }}
{{- end -}}
{{ $out }}
{{- end -}}

{{- define "xrd.sriovConfig" -}}
{{- $config := dict "cniVersion" "0.3.1" }}
{{- if .config }}
{{- merge $config (.config | toPrettyJson) }}
{{- end }}
{{- if not (and .config .config.type) }}
{{- $config = set $config "type" "host-device" }}
{{- end }}
{{ $config }}
{{- end -}}