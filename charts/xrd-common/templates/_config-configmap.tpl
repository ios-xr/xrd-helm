{{- define "xrd.config-configmap" -}}
{{- if eq (include "xrd.hasConfig" .) "true" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "xrd.fullname" . }}-config
  namespace: {{ .Release.Namespace }}
  {{- if gt (len (include "xrd.commonAnnotations" $ | fromYaml)) 0 }}
  annotations:
    {{- include "xrd.commonAnnotations" . | nindent 4 }}
  {{- end }}
  labels:
    {{- include "xrd.commonLabels" . | nindent 4 }}
data:
  {{- if or .Values.config.ascii .Values.config.username }}
  startup.cfg: |
    {{- if .Values.config.username }}
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
{{- end -}}
{{- end -}}
