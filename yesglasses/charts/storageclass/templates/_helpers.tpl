# define storageclass tpl
{{- define "storageclass" -}}
{{- $projectName := include "projectName" . }}
{{- if eq .Values.global.mode "production" }}
{{- else }}
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: aws-ebs
  labels:
    com.{{ $projectName }}.storageclass: aws-ebs
provisioner: k8s.io/minikube-hostpath
allowVolumeExpansion: true
volumeBindingMode: Immediate
reclaimPolicy: Delete

---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: aws-s3
  labels:
    com.{{ $projectName }}.storageclass: aws-s3
provisioner: nfs.csi.k8s.io
allowVolumeExpansion: true
volumeBindingMode: Immediate
reclaimPolicy: Retain
{{- end }}
{{- end }}
