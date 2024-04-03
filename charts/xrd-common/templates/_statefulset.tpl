{{- define "xrd.statefulset" -}}
{{- /*
Generate the statefulset for XRd.

This template requires a dict as the argument with the following fields:
  - root: the root context.
  - environment: a dictionary of any platform-specific environment variables.
  - resources: a dict containing container resource settings.
 */}}
{{- $root := .root }}
{{- $resources := .resources }}
{{- $platformEnv := .environment }}
{{- with .root }}
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ include "xrd.fullname" . }}
  namespace: {{ .Release.Namespace }}
  {{- if or (gt (len (include "xrd.commonAnnotations" . | fromYaml)) 0) .Values.annotations }}
  annotations:
    {{- include "xrd.commonAnnotations" . | nindent 4 }}
    {{- with .Values.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- end }}
  labels:
    {{- include "xrd.commonLabels" . | nindent 4 }}
    {{- with .Values.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  replicas: 1
  serviceName: {{ include "xrd.fullname" . }}
  selector:
    matchLabels:
      {{- include "xrd.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      annotations:
        {{- if gt (len (include "xrd.commonAnnotations" . | fromYaml)) 0}}
        {{- include "xrd.commonAnnotations" . | nindent 8 }}
        {{- end }}
        {{- if or (include "xrd.interfaces.anyMultus" .) (include "xrd.interfaces.anySRIOV" .) }}
        k8s.v1.cni.cncf.io/networks: |-
          {{- include "xrd.podNetworkAnnotations" . | nindent 10 }}
        {{- end }}
        {{- with .Values.podAnnotations }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      labels:
        {{- include "xrd.commonLabels" . | nindent 8 }}
        {{- with .Values.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
    spec:
      {{- if .Values.hostNetwork }}
      hostNetwork: true
      {{- end }}
      volumes:
      {{- if eq (include "xrd.hasConfig" .) "true" }}
      - name: config
        configMap:
          name: {{ include "xrd.fullname" . }}-config
          items:
          {{- if or .Values.config.username .Values.config.ascii }}
          - key: startup.cfg
            path: startup.cfg
          {{- end }}
          {{- if .Values.config.script }}
          - key: startup.sh
            path: startup.sh
            mode: 0744
          {{- end }}
          {{- if .Values.config.ztpIni }}
          - key: ztp.ini
            path: ztp.ini
          {{- end }}
      {{- end }}
      {{- if and .Values.persistence.enabled .Values.persistence.existingClaim }}
      - name: xr-storage
        persistentVolumeClaim:
          claimName: {{ .Values.persistence.existingClaim | quote }}
      {{- end }}
      {{- range .Values.extraHostPathMounts }}
      - name: {{ include "xrd.fullname" $root }}-hostmount-{{ .name }}
        hostPath:
          path: {{ .hostPath | quote }}
          {{- if .create }}
          type: DirectoryOrCreate
          {{- else }}
          type: Directory
          {{- end }}
      {{- end }}
      {{- if (include "xrd.interfaces.anySRIOV" .) }}
      - downwardAPI:
          items:
          - fieldRef:
              fieldPath: metadata.annotations['k8s.v1.cni.cncf.io/network-status']
            path: pod-networks
        name: net-stat-annotation
      {{- end }}
      {{- if .Values.extraVolumes }}
      {{- toYaml .Values.extraVolumes | nindent 6 }}
      {{- end }}
      containers:
      {{- $repo := required "Image repository must be specified" .Values.image.repository }}
      {{- $tag := required "Image tag must be specified" .Values.image.tag }}
      - image: {{ printf "\"%s:%s\"" $repo $tag }}
        {{- if $resources }}
        resources:
          {{- $resources | toYaml | nindent 10 }}
        {{- end }}
        name: main
        securityContext:
        {{- toYaml .Values.securityContext | nindent 10 }}
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        tty: true
        stdin: true
        env:
          {{- $envArgs := dict "root" . "platformEnv" $platformEnv }}
          {{- include "xrd.container-env" $envArgs | nindent 8 }}
        volumeMounts:
        {{- if eq (include "xrd.hasConfig" $root) "true" }}
        - mountPath: /etc/xrd
          name: config
          readOnly: true
        {{- end }}
        {{- if .Values.persistence.enabled }}
        - mountPath: /xr-storage
          name: xr-storage
        {{- end }}
        {{- range .Values.extraHostPathMounts }}
        - mountPath: {{ .mountPath | default .hostPath }}
          name: {{include "xrd.fullname" $root }}-hostmount-{{ .name }}
        {{- end }}
        {{- if .Values.extraVolumeMounts }}
        {{- toYaml .Values.extraVolumeMounts | nindent 8 }}
        {{- end }}
        {{- if (include "xrd.interfaces.anySRIOV" .) }}
        - mountPath: /etc/pod-networks
          name: net-stat-annotation
        {{- end }}
      {{- with .Values.image.pullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 6 }}
      {{- end }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 6 }}
      {{- end }}
      {{- with .Values.podSpecExtra }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
  {{- with .Values.persistence }}
  {{- if and .enabled (not .existingClaim) }}
  volumeClaimTemplates:
  - metadata:
      name: xr-storage
      {{- if or (gt (len (include "xrd.commonAnnotations" $root | fromYaml)) 0) .annotations }}
      annotations:
        {{- include "xrd.commonAnnotations" $root | nindent 8 }}
        {{- if .annotations }}
        {{- toYaml .annotations | nindent 8 }}
        {{- end }}
      {{- end }}
      labels:
        {{- include "xrd.commonImmutableLabels" $root | nindent 8 }}
    spec:
      accessModes:
      {{- .accessModes | toYaml | nindent 6 }}
      {{- if .selector }}
      selector:
        {{- .selector | toYaml | nindent 8 }}
      {{- end }}
      resources:
        requests:
          storage: {{ .size | quote }}
      {{- if .existingVolume }}
      volumeName: {{ .existingVolume | quote }}
      {{- end }}
      {{- /* N.B. Missing SC definition is different to empty string definition! */}}
      {{- if hasKey . "storageClass" }}
      storageClassName: {{ .storageClass | quote }}
      {{- end }}
      {{- if .dataSource }}
      dataSource:
        {{- toYaml .dataSource | nindent 8 }}
      {{- end }}
  {{- end }}
  {{- end }}
{{- end -}}
{{- end -}}
