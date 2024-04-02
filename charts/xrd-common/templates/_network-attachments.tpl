{{- define "xrd.network-attachments" -}}
{{- range $idx, $intf := concat .Values.interfaces .Values.mgmtInterfaces }}
{{- if eq $intf.type "multus" }}
---
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: {{ include "xrd.fullname" $ }}-{{ $idx }}
  namespace: {{ $.Release.Namespace }}
  {{- if gt (len (include "xrd.commonAnnotations" $ | fromYaml)) 0 }}
  annotations:
    {{- include "xrd.commonAnnotations" $ | nindent 4 }}
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
{{- end }}
{{- if eq $intf.type "sriov" }}
---
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: {{ include "xrd.fullname" $ }}-{{ $idx }}
  namespace: {{ $.Release.Namespace }}
  annotations:
    k8s.v1.cni.cncf.io/resourceName: {{ $intf.resource }}
    {{- include "xrd.commonAnnotations" $ | nindent 4 }}
  labels:
    {{- include "xrd.commonLabels" $ | nindent 4 }}
spec:
  config: |-
    {
      "cniVersion": "0.3.1",
      "name": "{{ include "xrd.fullname" $ }}-{{ $idx }}",
      {{- if not (and $intf.config $intf.config.type) }}
      "type": "sriov",
      {{- end }}
      {{- if $intf.config }}
      {{- if not ($intf.config.ipam) }}
      "ipam": {},
      {{- end }}
      {{- $intf.config | toPrettyJson | nindent 6 }}
      {{- else }}
      "ipam": {}
      {{- end }}
    }
...
{{- end }}
{{- end -}}
{{- end -}}