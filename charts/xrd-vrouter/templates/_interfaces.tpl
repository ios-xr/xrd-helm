{{- define "xrd-vr.interfaces" -}}
{{- /* Generate the XR_INTERFACES environment variable content */ -}}
{{- $interfaces := list }}
{{- $hasPci := 0 }}
{{- $hasNetwork := 0 }}
{{- $hasPciRange := 0 }}
{{- $cniIndex := 0 }}
{{- include "xrd.interfaces.checkDefaultCniCount" . -}}
{{- range .Values.interfaces }}
  {{- if eq .type "pci" }}
    {{- if hasKey . "attachmentConfig" }}
      {{- fail "attachmentConfig may not be specified for PCI interfaces" }}
    {{- end }}
    {{- $flags := include "xrd.interfaces.pciflags" . }}
    {{- if $hasPciRange }}
      {{- fail "If a pci interface range (i.e. with 'first' or 'last' config) is specified, no other pci interfaces may be specified" }}
    {{- end }}
    {{- if hasKey .config "device" }}
      {{- if or (hasKey .config "first") (hasKey .config "last") }}
        {{- fail "Cannot specify 'device' and either 'first' or 'last' for PCI interfaces" }}
      {{- end }}
      {{- $hasPci = 1 }}
      {{- if $flags }}
        {{- $interfaces = append $interfaces (printf "pci:%s,%s" .config.device $flags) }}
      {{- else }}
        {{- $interfaces = append $interfaces (printf "pci:%s" .config.device) }}
      {{- end }}
    {{- else if or (hasKey .config "first") (hasKey .config "last") }}
      {{- if and (hasKey .config "first") (hasKey .config "last") }}
        {{- fail "Cannot specify both 'first' and 'last' for PCI interface" }}
      {{- end }}
      {{- $hasPciRange = 1 }}
      {{- if or $hasPci $hasNetwork }}
        {{- fail "If a pci interface range (i.e. with 'first' or 'last' config) is specified, no other pci interfaces (including networks) may be specified" }}
      {{- end }}
      {{- $config := "" }}
      {{- if .config.last }}
        {{- $config = printf "last%v" .config.last }}
      {{- else if .config.first }}
        {{- $config = printf "last%v" .config.first }}
      {{- end }}
      {{- if $flags }}
        {{- $interfaces = append $interfaces (printf "pci-range:%s,%s" $config $flags) }}
      {{- else }}
        {{- $interfaces = append $interfaces (printf "pci-range:%s" $config) }}
      {{- end }}
    {{- else }}
      {{- fail "Must specify one of 'device', 'first', or 'last' for PCI interfaces" }}
    {{- end }}
  {{- else if eq .type "sriov" }}
    {{- if hasKey . "attachmentConfig" }}
      {{- fail "attachmentConfig may not be specified for net-attach-def interface types" }}
    {{- end }}
    {{- $hasNetwork = 1}}
    {{- if $hasPciRange }}
      {{- fail "If a pci interface range (i.e. with 'first' or 'last' config) is specified, no other pci interfaces (including networks) may be specified" }}
    {{- end }}
    {{- if not (hasKey . "resource") }}
      {{- fail "Resource must be specified for net-attach-def network types" }}
    {{- end }}
    {{- $interfaces = append $interfaces (printf "net-attach-def:%s" .resource) }}
  {{- else }}
    {{- fail (printf "Invalid interface type %s" .type) }}
  {{- end }}
{{- end }}
{{- join ";" $interfaces }}
{{- end -}}

{{- define "xrd-vr.mgmtInterfaces" -}}
{{- /* Generate the XR_MGMT_INTERFACES environment variable content */ -}}
{{- $interfaces := list }}
{{- $cniIndex := atoi (include "xrd.interfaces.multusCount" .Values.interfaces) }}
{{- if gt (len .Values.mgmtInterfaces) 1 }}
  {{- fail "Only one management interface can be specified on XRd vRouter" }}
{{- end }}
{{- include "xrd.interfaces.checkDefaultCniCount" . -}}
{{- range .Values.mgmtInterfaces }}
  {{- if eq .type "defaultCni" }}
    {{- if (hasKey . "xrName") }}
      {{- fail "xrName may not be specified for interfaces on XRd vRouter" }}
    {{- end }}
    {{- $flags := include "xrd.interfaces.linuxflags" . }}
    {{- if $flags }}
      {{- $interfaces = append $interfaces (printf "linux:eth0,%s" $flags) }}
    {{- else }}
      {{- $interfaces = append $interfaces "linux:eth0" }}
    {{- end }}
  {{- else if eq .type "multus" }}
    {{- $cniIndex = add1 $cniIndex }}
    {{- if (hasKey . "xrName") }}
      {{- fail "xrName may not be specified for interfaces on XRd vRouter" }}
    {{- end }}
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
