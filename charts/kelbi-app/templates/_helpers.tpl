
{{/*
Expand the name of the chart.
*/}}
{{- define "kelbi-app.name" -}}
{{- $appName := default "" .Values.app.name -}}
{{- $override := default "" .Values.nameOverride -}}
{{- default .Chart.Name (default $appName $override) | trunc 63 | trimSuffix "-" }}
{{- end }}


{{- define "kelbi-app.ports" -}}

{{- $cfg := .Values.config -}}
{{ $svc := .Values.service }}

{{- if and $cfg $cfg.port -}}
- name: http
  port: {{ $cfg.port }}
  protocol: TCP
  targetPort: http
{{- end -}}

{{- range $svc.ports }}
- name: {{ .name }}
  port: {{ .port }}
  protocol: {{ .protocol }}
  targetPort: {{ .protocol }}
{{- end -}}

{{- end -}}

{{- define "kelbi-app.httpPort" -}}
{{- if .Values.config.port -}}
{{ .Values.config.port }}
{{- else if .Values.service.ports -}}
{{- (first .Values.service.ports).port -}}
{{- else -}}
""
{{- end -}}
{{- end -}}

{{/*
Render environment configuration for the container.
- If .Values.config.env is a string:
    - "configmap:<name>" => envFrom.configMapRef
    - otherwise => envFrom.secretRef (supports "secret:<name>" or plain name)
- If it's a list => render under env:
*/}}
{{- define "kelbi-app.containerEnv" -}}
{{- $env := .Values.config.env }}

{{- if and $env (kindIs "string" $env) }}

envFrom:
  {{- if hasPrefix "configmap:" $env }}
  - configMapRef:
      name: {{ trimPrefix "configmap:" $env }}
  {{- else }}
  - secretRef:
      name: {{ trimPrefix "secret:" $env }}
  {{- end }}

{{- else if $env }}

env:
{{ toYaml $env | nindent 2 }}

{{- end }}
{{- end }}


{{/*
Compute default HTTP health probes when http port exists and
probes are not explicitly provided in values.
Accepts the full context (.) and emits livenessProbe and readinessProbe YAML.
*/}}
{{- define "kelbi-app.healthProbes" -}}
{{- $httpPort := include "kelbi-app.httpPort" . -}}
{{- if and $httpPort (ne $httpPort "") -}}
{{- $hc := default dict .Values.health_check -}}
{{- $path := default "/" (get $hc "path") -}}
{{- $delay := default 5 (get $hc "initialDelaySeconds") -}}
{{- $period := default 10 (get $hc "periodSeconds") -}}
{{- if not .Values.livenessProbe -}}
livenessProbe:

  httpGet:
    path: {{ $path | quote }}
    port: http
  initialDelaySeconds: {{ $delay }}
  periodSeconds: {{ $period }}
{{- end -}}
{{- if not .Values.readinessProbe }}
readinessProbe:

  httpGet:
    path: {{ $path | quote }}
    port: http
  initialDelaySeconds: {{ $delay }}
  periodSeconds: {{ $period }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kelbi-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name (default .Values.app.name .Values.nameOverride) }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kelbi-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kelbi-app.labels" -}}
helm.sh/chart: {{ include "kelbi-app.chart" . }}
{{ include "kelbi-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kelbi-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kelbi-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "kelbi-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "kelbi-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
