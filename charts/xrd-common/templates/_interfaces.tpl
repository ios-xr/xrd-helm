{{- /* Helper templates */ -}}

{{- define "xrd.interfaces.anyMultus" -}}
{{- /*
Returns a string equivalent to boolean true if there are any multus interfaces,
or an empty string otherwise.
*/ -}}
{{- $c := 0 }}
{{- range concat .Values.interfaces .Values.mgmtInterfaces }}
  {{- if eq .type "multus" }}
1
  {{- end }}
{{- end }}
{{- end -}}

{{- define "xrd.interfaces.anySRIOV" -}}
{{- /*
Returns a string equivalent to boolean true if there are any sriov network interfaces,
or an empty string otherwise.
*/ -}}
{{- range .Values.interfaces }}
  {{- if eq .type "sriov" }}
1
  {{- end }}
{{- end }}
{{- end -}}

{{- define "xrd.interfaces.sriovCount" -}}
{{- $c := 0 }}
{{- range .Values.interfaces }}
  {{- if eq .type "sriov" }}
    {{- $c = add1 $c }}
  {{- end }}
{{- end }}
{{- $c }}
{{- end -}}

{{- define "xrd.interfaces.checkDefaultCniCount" -}}
{{- $c := 0 }}
{{- range .Values.interfaces }}
  {{- if eq .type "defaultCni" }}
    {{- $c = add1 $c }}
  {{- end }}
{{- end }}
{{- range .Values.mgmtInterfaces }}
  {{- if eq .type "defaultCni" }}
    {{- $c = add1 $c }}
  {{- end }}
{{- end }}
{{- if gt $c 1 }}
  {{- fail "At most one defaultCni interface can be specified across both interfaces and mgmtInterfaces" }}
{{- end }}
{{- end -}}

{{- define "xrd.interfaces.linuxflags" -}}
{{- $flags := list }}
{{- $base := list "type" "config" "attachmentConfig" }}
{{- range $k, $v := . -}}
  {{- if eq $k "snoopIpv4Address" }}
    {{- if $v }}
      {{- $flags = append $flags "snoop_v4" }}
    {{- end }}
  {{- else if eq $k "snoopIpv4DefaultRoute" }}
    {{- if $v }}
      {{- $flags = append $flags "snoop_v4_default_route" }}
    {{- end }}
  {{- else if eq $k "snoopIpv6Address" }}
    {{- if $v }}
      {{- $flags = append $flags "snoop_v6" }}
    {{- end }}
  {{- else if eq $k "snoopIpv6DefaultRoute" }}
    {{- if $v }}
      {{- $flags = append $flags "snoop_v6_default_route" }}
    {{- end }}
  {{- else if eq $k "chksum" }}
    {{- if $v }}
      {{- $flags = append $flags "chksum" }}
    {{- end }}
  {{- else if eq $k "xrName" }}
    {{- if not (and (kindIs "string" $v) $v) }}
      {{- fail "If xrName is specified it must be a non-empty string" }}
    {{- end }}
    {{- $flags = append $flags (printf "xr_name=%s" $v) }}
  {{- else if not (has $k $base) }}
    {{- fail (printf "%s may not be specified for defaultCni or multus interfaces" $k) }}
  {{- end }}
{{- end }}
{{- join "," $flags }}
{{- end -}}

{{- define "xrd.interfaces.pciflags" -}}
{{- $flags := list }}
{{- $base := list "type" "config" }}
{{- range $k, $v := . -}}
  {{- if not (has $k $base) }}
    {{- fail (printf "%s may not be specified for pci interfaces" $k) }}
  {{- end }}
{{- end }}
{{- join "," $flags }}
{{- end -}}

{{- define "xrd.interfaces.sriovflags" -}}
{{- $flags := list }}
{{- $base := list "type" "config" "resource" }}
{{- range $k, $v := . -}}
  {{- if not (has $k $base) }}
    {{- fail (printf "%s may not be specified for sriov interfaces" $k) }}
  {{- end }}
{{- end }}
{{- join "," $flags }}
{{- end -}}

{{- define "xrd.podNetworkAnnotations" -}}
{{- $nets := list }}
{{- range $idx, $intf := concat .Values.interfaces .Values.mgmtInterfaces }}
  {{- if eq $intf.type "multus" }}
    {{- $netname := printf "%s-%d" (include "xrd.fullname" $) $idx }}
    {{- $intfname := printf "net%d" $idx }}
    {{- $entry := dict "name" $netname "interface" $intfname}}
    {{- if $intf.attachmentConfig }}
    {{- $entry = merge $entry $intf.attachmentConfig }}
    {{- end }}
    {{- $nets = append $nets $entry }}
  {{- end }}
  {{- if eq $intf.type "sriov" }}
    {{- $netname := printf "%s-%d" (include "xrd.fullname" $) $idx }}
    {{- $intfname := printf "net%d" $idx }}
    {{- $entry := dict "name" $netname "interface" $intfname}}
    {{- $nets = append $nets $entry }}
  {{- end }}
{{- end }}
{{- toPrettyJson $nets }}
{{- end }}
