{{- define "xrd.config-configmap" -}}
{{- if .Values.config -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "xrd.fullname" . }}-config
  namespace: {{ .Release.Namespace }}
  annotations:
    {{- include "xrd.commonAnnotations" . | nindent 4 }}
  labels:
    {{- include "xrd.commonLabels" . | nindent 4 }}
{{- if or .Values.config.username .Values.config.ascii .Values.config.script .Values.config.ztpIni }}
data:
  {{- if or .Values.config.ascii .Values.config.username }}
  startup.cfg: |
    {{- if .Values.config.username }}
      {{- if not .Values.config.password }}
        {{- fail "password must be specified if username specified" }}
      {{- end }}
    username {{ .Values.config.username }}
     group root-lr
     group cisco-support
     password {{ .Values.config.password }}
    !
    {{- end }}
    {{- if (get .Values.config "ascii") }}
    {{- tpl .Values.config.ascii . | default "" | nindent 4 }}
    {{- end }}
  {{- end }}
  {{- if .Values.config.script }}
  startup.sh: |
    {{- .Values.config.script | nindent 4 }}
  {{- end }}
  {{- if .Values.config.ztpIni }}
  ztp.ini: |
    {{- .Values.config.ztpIni | nindent 4 }}
  {{- end }}
{{- else }}
data: {}
{{- end -}}
{{- end -}}
{{- end -}}
