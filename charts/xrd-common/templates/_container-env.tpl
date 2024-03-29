{{- define "xrd.container-env" -}}
{{- /*
Generate the environment variables for XRd.

This template requires a dict as the argument with the following fields:
  - root: the root context
  - platformEnv: a dictionary of any platform-specific environment variables.
 */}}
{{- $root := .root }}
{{- $gen := dict }}

{{- /* Merge the additional env vars */}}
{{- if .platformEnv }}
  {{- $gen = merge $gen .platformEnv }}
{{- end }}

{{- /* Generate all common env vars with the normal root context */}}
{{- with .root }}
  {{- /* Set the env vars version being used */}}
  {{- $_ := set $gen "XR_ENV_VARS_VERSION" "1" }}

  {{- /* Set the disk usage limit to the size of the requested PV */}}
  {{- if .Values.persistence.enabled }}
    {{- /*
    Take the value, and the capitalized first letter of the size prefix so that
    it's a valid env var value, e.g. 123kb -> 123K, 234Mi -> 234M, 345G -> 345G, etc.
    */}}
    {{- $size := regexFind "[0-9]+" .Values.persistence.size }}
    {{- $suffix := .Values.persistence.size | trimPrefix $size | trunc 1 | upper }}
    {{- $xrSize := printf "%s%s" $size $suffix }}
    {{- $_ := set $gen "XR_DISK_USAGE_LIMIT" $xrSize }}
  {{- end }}

  {{- /* Generate config, script and ZTP env vars */}}
  {{- with .Values.config }}
    {{- if .ztpEnable }}
      {{- $_ := set $gen "XR_ZTP_ENABLE" "1" }}
    {{- end }}
    {{- if eq (include "xrd.hasConfig" $root) "true" }}
      {{- if or .ascii .username }}
        {{- $env := ternary "XR_EVERY_BOOT_CONFIG" "XR_FIRST_BOOT_CONFIG" (default false .asciiEveryBoot) }}
        {{- $_ := set $gen $env "/etc/xrd/startup.cfg" }}
      {{- end }}
      {{- if .script }}
        {{- $env := ternary "XR_EVERY_BOOT_SCRIPT" "XR_FIRST_BOOT_SCRIPT" (default false .scriptEveryBoot) }}
        {{- $_ := set $gen $env "/etc/xrd/startup.sh" }}
      {{- end }}
      {{- if .ztpIni }}
        {{- if not .ztpEnable }}
          {{- fail "ztpIni can only be specified if ztpEnable is set to true" }}
        {{- else }}
          {{- $_ := set $gen "XR_ZTP_ENABLE_WITH_INI" "/etc/xrd/ztp.ini" }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end -}}

  {{- /*
  Any explicit values in the advanced settings override values generated
  by the sections above.
  */}}
  {{- $envList := list -}}
  {{- $env := dict }}
  {{- /* Merge has left-preference */}}
  {{- $env := merge $env .Values.advancedSettings $gen }}

  {{- range $k, $v := $env }}
    {{- $entry := dict "name" $k "value" (toString $v) }}
    {{- $envList = append $envList $entry }}
  {{- end }}
  {{- if $envList }}
    {{- $envList | toYaml }}
  {{- end }}
{{- end }}
{{- end -}}