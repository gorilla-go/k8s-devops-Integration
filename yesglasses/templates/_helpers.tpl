{{- define "projectName" -}}
{{- default .Release.Name .Values.global.name -}}
{{- end -}}

{{- define "namespace" -}}
{{- default .Release.Namespace .Values.global.namespace -}}
{{- end -}}