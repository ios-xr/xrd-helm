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
    {{- $flags := include "xrd.interfaces.linuxflags" . }}
    {{- if $flags }}
      {{- $interfaces = append $interfaces (printf "linux:eth0,%s" $flags) }}
    {{- else }}
      {{- $interfaces = append $interfaces "linux:eth0" }}
    {{- end }}
  {{- else if eq .type "multus" }}
    {{- $cniIndex = add1 $cniIndex }}
    {{- $flags := include "xrd.interfaces.linuxflags" . }}
    {{- if $flags }}
      {{- $interfaces = append $interfaces (printf "linux:net%d,%s" $cniIndex $flags) }}
    {{- else }}
      {{- $interfaces = append $interfaces (printf "linux:net%d" $cniIndex) }}
    {{- end }}
  {{- else }}
    {{- fail (printf "Invalid interface type %s" .type) }}
  {{- end }}
{{- end }}
{{- join ";" $interfaces }}
{{- end -}}

{{- define "xrd-cp.mgmtInterfaces" -}}
{{- /* Generate the XR_MGMT_INTERFACES environment variable content */ -}}
{{- $interfaces := list }}
{{- $cniIndex := atoi (include "xrd.interfaces.multusCount" .Values.interfaces) }}
{{- include "xrd.interfaces.checkDefaultCniCount" . -}}
{{- range .Values.mgmtInterfaces }}
  {{- if eq .type "defaultCni" }}
    {{- $flags := include "xrd.interfaces.linuxflags" . }}
    {{- if $flags }}
      {{- $interfaces = append $interfaces (printf "linux:eth0,%s" $flags) }}
    {{- else }}
      {{- $interfaces = append $interfaces "linux:eth0" }}
    {{- end }}
  {{- else if eq .type "multus" }}
    {{- $cniIndex = add1 $cniIndex }}
    {{- $flags := include "xrd.interfaces.linuxflags" . }}
    {{- if $flags }}
      {{- $interfaces = append $interfaces (printf "linux:net%d,%s" $cniIndex $flags) }}
    {{- else }}
      {{- $interfaces = append $interfaces (printf "linux:net%d" $cniIndex) }}
    {{- end }}
  {{- else }}
    {{- fail (printf "Invalid mgmt interface type %s" .type) }}
  {{- end }}
{{- end }}
{{- join ";" $interfaces }}
{{- end -}}
