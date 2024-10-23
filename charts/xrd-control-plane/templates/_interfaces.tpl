{{- define "xrd-cp.interfaces" -}}
{{- /* Generate the XR_INTERFACES environment variable content */ -}}
{{- $interfaces := list }}
{{- $hasPci := 0 }}
{{- $hasPciRange := 0 }}
{{- $cniIndex := 0 }}
{{- include "xrd.interfaces.checkDefaultCniCount" . -}}
{{- range .Values.interfaces }}
  {{- if eq .type "defaultCni" }}
    {{- if hasKey . "attachmentConfig" }}
      {{- fail "attachmentConfig may not be specified for defaultCni interfaces" }}
    {{- end }}
    {{- if hasKey . "resource" }}
      {{- fail "resource may not be specified for defaultCni interface types" }}
    {{- end }}
    {{- $flags := include "xrd.interfaces.linuxflags" . }}
    {{- if $flags }}
      {{- $interfaces = append $interfaces (printf "linux:eth0,%s" $flags) }}
    {{- else }}
      {{- $interfaces = append $interfaces "linux:eth0" }}
    {{- end }}
  {{- else if or (eq .type "multus") (eq .type "sriov") }}
    {{- $flags := include "xrd.interfaces.linuxflags" . }}
    {{- if eq .type "sriov" }}
      {{- if hasKey . "attachmentConfig" }}
        {{- fail "attachmentConfig may not be specified for sriov interface types" }}
      {{- end }}
      {{- if not (hasKey . "resource") }}
        {{- fail "Resource must be specified for sriov interface types" }}
      {{- end }}
    {{- else if hasKey . "resource" }}
      {{- fail "resource may not be specified for multus interface types" }}
    {{- end }}
    {{- if $flags }}
      {{- $interfaces = append $interfaces (printf "linux:net%d,%s" $cniIndex $flags) }}
    {{- else }}
      {{- $interfaces = append $interfaces (printf "linux:net%d" $cniIndex) }}
    {{- end }}
    {{- $cniIndex = add1 $cniIndex }}
  {{- else }}
    {{- fail (printf "Invalid interface type %s" .type) }}
  {{- end }}
{{- end }}
{{- join ";" $interfaces }}
{{- end -}}

{{- define "xrd-cp.mgmtInterfaces" -}}
{{- /* Generate the XR_MGMT_INTERFACES environment variable content */ -}}
{{- $interfaces := list }}
{{- $cniIndex := atoi (include "xrd.interfaces.cniCount" .) }}
{{- include "xrd.interfaces.checkDefaultCniCount" . -}}
{{- range .Values.mgmtInterfaces }}
  {{- if eq .type "defaultCni" }}
    {{- if hasKey . "attachmentConfig" }}
      {{- fail "attachmentConfig may not be specified for defaultCni mgmt interfaces" }}
    {{- end }}
    {{- if hasKey . "resource" }}
      {{- fail "resource may not be specified for defaultCni mgmt interface types" }}
    {{- end }}
    {{- $flags := include "xrd.interfaces.linuxflags" . }}
    {{- if $flags }}
      {{- $interfaces = append $interfaces (printf "linux:eth0,%s" $flags) }}
    {{- else }}
      {{- $interfaces = append $interfaces "linux:eth0" }}
    {{- end }}
  {{- else if or (eq .type "multus") (eq .type "sriov") }}
    {{- $flags := include "xrd.interfaces.linuxflags" . }}
    {{- if eq .type "sriov" }}
      {{- if hasKey . "attachmentConfig" }}
        {{- fail "attachmentConfig may not be specified for sriov mgmt interface types" }}
      {{- end }}
      {{- if not (hasKey . "resource") }}
        {{- fail "Resource must be specified for sriov mgmt interface types" }}
      {{- end }}
    {{- else if hasKey . "resource" }}
      {{- fail "resource may not be specified for multus mgmt interface types" }}
    {{- end }}
    {{- if $flags }}
      {{- $interfaces = append $interfaces (printf "linux:net%d,%s" $cniIndex $flags) }}
    {{- else }}
      {{- $interfaces = append $interfaces (printf "linux:net%d" $cniIndex) }}
    {{- end }}
    {{- $cniIndex = add1 $cniIndex }}
  {{- else }}
    {{- fail (printf "Invalid mgmt interface type %s" .type) }}
  {{- end }}
{{- end }}
{{- join ";" $interfaces }}
{{- end -}}
