{{- define "xrd.network-attachments" -}}
{{- $cniIndex := 0 }}
{{- range $intf := concat .Values.interfaces .Values.mgmtInterfaces }}
{{- if or (eq $intf.type "multus") (eq $intf.type "sriov") }}
---
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: {{ include "xrd.fullname" $ }}-{{ $cniIndex }}
  namespace: {{ $.Release.Namespace }}
  {{- if or (gt (len (include "xrd.commonAnnotations" $ | fromYaml)) 0) (eq $intf.type "sriov") }}
  annotations:
    {{- if eq $intf.type "sriov" }}
    k8s.v1.cni.cncf.io/resourceName: {{ $intf.resource }}
    {{- end }}
    {{- if gt (len (include "xrd.commonAnnotations" $ | fromYaml)) 0 }}
      {{- include "xrd.commonAnnotations" $ | nindent 4 }}
    {{- end }}
  {{- end }}
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
{{- $cniIndex = add1 $cniIndex}}
{{- end }}
{{- end -}}
{{- end -}}