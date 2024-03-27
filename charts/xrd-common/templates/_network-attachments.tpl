{{- define "xrd.network-attachments" -}}
{{- range $idx, $intf := concat .Values.interfaces .Values.mgmtInterfaces }}
{{- if or (eq $intf.type "multus") (eq $intf.type "sriov") }}
---
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: {{ include "xrd.fullname" $ }}-{{ $idx }}
  namespace: {{ $.Release.Namespace }}
  annotations:
    {{- include "xrd.commonAnnotations" $ | nindent 4 }}
  labels:
    {{- include "xrd.commonLabels" $ | nindent 4 }}
spec:
  config: |-
    {
      "cniVersion": "0.3.1",
      "plugins": [
        {{- $intf.config | toPrettyJson | nindent 8 }}
      ]
    }
...
{{- end }}
{{- end -}}
{{- end -}}