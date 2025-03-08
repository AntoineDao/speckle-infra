{{/*
Expand the name of the chart.
*/}}
{{- define "speckle-server.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "speckle-server.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
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
{{- define "speckle-server.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "speckle-server.labels" -}}
helm.sh/chart: {{ include "speckle-server.chart" . }}
{{ include "speckle-server.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "speckle-server.selectorLabels" -}}
app.kubernetes.io/name: {{ include "speckle-server.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "speckle-server.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "speckle-server.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}




{{/*
Generate the environment variables for Speckle server and Speckle objects deployments
*/}}
{{- define "speckle-server.deploymentEnv" -}}
{{- if .Values.ingress.enabled }}
- name: CANONICAL_URL
  {{- if .Values.ssl_canonical_url }}
  value: https://{{ .Values.domain }}
  {{- else }}
  value: http://{{ .Values.domain }}
  {{- end }}
{{- else -}}
- name: CANONICAL_URL
  value: http://localhost
{{- end }}

- name: PORT
  value: {{ .Values.service.port | quote }}
- name: LOG_LEVEL
  value: {{ .Values.server.logLevel }}
- name: LOG_PRETTY
  value: {{ .Values.server.logPretty | quote }}

- name: FRONTEND_ORIGIN
  {{- if .Values.ssl_canonical_url }}
  value: https://{{ .Values.domain }}
  {{- else }}
  value: http://{{ .Values.domain }}
  {{- end }}

- name: ENABLE_FE2_MESSAGING
  value: {{ .Values.server.enableFe2Messaging | quote }}

- name: FF_AUTOMATE_MODULE_ENABLED
  value: {{ .Values.global.featureFlags.automateModule.enabled | quote }}

- name: FF_WORKSPACES_MODULE_ENABLED
  value: {{ .Values.global.featureFlags.workspacesModule.enabled | quote }}

- name: FF_NO_PERSONAL_EMAILS_ENABLED
  value: {{ .Values.global.featureFlags.noPersonalEmails.enabled | quote }}

- name: FF_WORKSPACES_SSO_ENABLED
  value: {{ .Values.global.featureFlags.workspacesSSO.enabled | quote }}

- name: FF_WORKSPACES_NEW_PLANS_ENABLED
  value: {{ .Values.global.featureFlags.workspacesNewPlan.enabled | quote }}

{{- if .Values.global.featureFlags.workspacesModule.enabled }}
- name: LICENSE_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ .Values.global.featureFlags.workspacesModule.secretName }}
      key: "license_token"
{{- end }}

- name: FF_MULTIPLE_EMAILS_MODULE_ENABLED
  value: {{ .Values.global.featureFlags.multipleEmailsModule.enabled | quote }}

- name: FF_GATEKEEPER_MODULE_ENABLED
  value: {{ .Values.global.featureFlags.gatekeeperModule.enabled | quote }}

- name: FF_BILLING_INTEGRATION_ENABLED
  value: {{ .Values.global.featureFlags.billingIntegration.enabled | quote }}

- name: FF_WORKSPACES_MULTI_REGION_ENABLED
  value: {{ .Values.global.featureFlags.workspacesMultiRegion.enabled | quote }}

- name: FF_FORCE_ONBOARDING
  value: {{ .Values.global.featureFlags.forceOnboarding | quote }}

{{- if .Values.global.featureFlags.billingIntegration.enabled }}
- name: STRIPE_API_KEY
  valueFrom:
    secretKeyRef:
      name: "{{ default .Values.secretName .Values.server.billing.secretName }}"
      key: stripe_api_key

- name: STRIPE_ENDPOINT_SIGNING_KEY
  valueFrom:
    secretKeyRef:
      name: "{{ default .Values.secretName .Values.server.billing.secretName }}"
      key: stripe_endpoint_signing_key

- name: WORKSPACE_GUEST_SEAT_STRIPE_PRODUCT_ID
  value: {{ .Values.global.featureFlags.billingIntegration.products.workspaceGuestSeat.id | quote }}

- name: WORKSPACE_MONTHLY_GUEST_SEAT_STRIPE_PRICE_ID
  value: {{ .Values.global.featureFlags.billingIntegration.products.workspaceMonthlyGuestSeat.monthlyPriceID | quote }}

- name: WORKSPACE_YEARLY_GUEST_SEAT_STRIPE_PRICE_ID
  value: {{ .Values.global.featureFlags.billingIntegration.products.workspaceYearlyGuestSeat.yearlyPriceID | quote }}

- name: WORKSPACE_STARTER_SEAT_STRIPE_PRODUCT_ID
  value: {{ .Values.global.featureFlags.billingIntegration.products.workspaceStarterSeat.id | quote }}

- name: WORKSPACE_MONTHLY_STARTER_SEAT_STRIPE_PRICE_ID
  value: {{ .Values.global.featureFlags.billingIntegration.products.workspaceMonthlyStarterSeat.monthlyPriceID | quote }}

- name: WORKSPACE_YEARLY_STARTER_SEAT_STRIPE_PRICE_ID
  value: {{ .Values.global.featureFlags.billingIntegration.products.workspaceYearlyStarterSeat.yearlyPriceID | quote }}

- name: WORKSPACE_PLUS_SEAT_STRIPE_PRODUCT_ID
  value: {{ .Values.global.featureFlags.billingIntegration.products.workspacePlusSeat.id | quote }}

- name: WORKSPACE_MONTHLY_PLUS_SEAT_STRIPE_PRICE_ID
  value: {{ .Values.global.featureFlags.billingIntegration.products.workspaceMonthlyPlusSeat.monthlyPriceID | quote }}

- name: WORKSPACE_YEARLY_PLUS_SEAT_STRIPE_PRICE_ID
  value: {{ .Values.global.featureFlags.billingIntegration.products.workspaceYearlyPlusSeat.yearlyPriceID | quote }}

- name: WORKSPACE_BUSINESS_SEAT_STRIPE_PRODUCT_ID
  value: {{ .Values.global.featureFlags.billingIntegration.products.workspaceBusinessSeat.id | quote }}

- name: WORKSPACE_MONTHLY_BUSINESS_SEAT_STRIPE_PRICE_ID
  value: {{ .Values.global.featureFlags.billingIntegration.products.workspaceMonthlyBusinessSeat.monthlyPriceID | quote }}

- name: WORKSPACE_YEARLY_BUSINESS_SEAT_STRIPE_PRICE_ID
  value: {{ .Values.global.featureFlags.billingIntegration.products.workspaceYearlyBusinessSeat.yearlyPriceID | quote }}

{{- end }}

{{- if (or .Values.global.featureFlags.automateModule.enabled .Values.global.featureFlags.workspacesSso.enabled) }}
- name: ENCRYPTION_KEYS_PATH
  value: /encryption-keys/keys.json
{{- end }}

{{- if .Values.global.featureFlags.automateModule.enabled }}
- name: SPECKLE_AUTOMATE_URL
  value: {{ .Values.global.featureFlags.automateModule.url | quote }}
{{- end }}

- name: ONBOARDING_STREAM_URL
  value: {{ .Values.server.onboarding.stream_url }}
- name: ONBOARDING_STREAM_CACHE_BUST_NUMBER
  value: {{ .Values.server.onboarding.stream_cache_bust_number | quote }}

- name: SESSION_SECRET
  valueFrom:
    secretKeyRef:
      name: "{{ default .Values.secretName .Values.server.sessionSecret.secretName }}"
      key: {{ default "session_secret" .Values.server.sessionSecret.secretKey }}

- name: FILE_SIZE_LIMIT_MB
  value: {{ .Values.file_size_limit_mb | quote }}

- name: MAX_PROJECT_MODELS_PER_PAGE
  value: {{ .Values.server.max_project_models_per_page | quote }}

- name: MAX_OBJECT_SIZE_MB
  value: {{ .Values.server.max_object_size_mb | quote }}

- name: MAX_OBJECT_UPLOAD_FILE_SIZE_MB
  value: {{ .Values.server.max_object_upload_file_size_mb | quote }}

  {{- if .Values.server.migration.movedFrom }}
- name: MIGRATION_SERVER_MOVED_FROM
  value: {{ .Values.server.migration.movedFrom }}
  {{- end }}

  {{- if .Values.server.migration.movedTo }}
- name: MIGRATION_SERVER_MOVED_TO
  value: {{ .Values.server.migration.movedTo }}
  {{- end }}

{{- if .Values.server.asyncRequestContext.enabled }}
- name: ASYNC_REQUEST_CONTEXT_ENABLED
  value: {{ .Values.server.asyncRequestContext.enabled | quote }}
{{- end}}

# *** Gendo render module ***
- name: FF_GENDOAI_MODULE_ENABLED
  value: {{ .Values.global.featureFlags.gendoAIModule.enabled | quote }}

{{- if .Values.global.featureFlags.gendoAIModule.enabled }}
- name: GENDOAI_KEY
  valueFrom:
    secretKeyRef:
      name: {{ default .Values.secretName .Values.global.featureFlags.gendoAIModule.key.secretName }}
      key: {{ .Values.global.featureFlags.gendoAIModule.key.secretKey }}

- name: GENDOAI_API_ENDPOINT
  value: {{ .Values.global.featureFlags.gendoAIModule.apiUrl | quote }}

- name: GENDOAI_CREDIT_LIMIT
  value: {{ .Values.global.featureFlags.gendoAIModule.creditLimit | quote }}

- name: RATELIMIT_GENDO_AI_RENDER_REQUEST
  value: {{ .Values.global.featureFlags.gendoAIModule.ratelimiting.renderRequest | quote }}

- name: RATELIMIT_GENDO_AI_RENDER_REQUEST_PERIOD_SECONDS
  value: {{ .Values.global.featureFlags.gendoAIModule.ratelimiting.renderRequestPeriodSeconds | quote }}

- name: RATELIMIT_BURST_GENDO_AI_RENDER_REQUEST
  value: {{ .Values.global.featureFlags.gendoAIModule.ratelimiting.burstRenderRequest | quote }}

- name: RATELIMIT_GENDO_AI_RENDER_REQUEST_BURST_PERIOD_SECONDS
  value: {{ .Values.global.featureFlags.gendoAIModule.ratelimiting.burstRenderRequestPeriodSeconds | quote }}
{{- end }}

# *** Redis ***
- name: REDIS_URL
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secretName  }}
      key: {{ default "redis_url" .Values.redis.connectionString.secretKey }}


{{- if .Values.preview_service.dedicatedPreviewsQueue }}
- name: PREVIEW_SERVICE_REDIS_URL
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secretName .Values.redis.previewServiceConnectionString.secretName }}
      key: {{ default "preview_service_redis_url" .Values.redis.previewServiceConnectionString.secretKey }}
{{- end }}

# *** PostgreSQL Database ***
- name: POSTGRES_URL
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secretName }}
      key: {{ default "postgres_url" .Values.db.connectionString.secretKey }}
      
- name: POSTGRES_MAX_CONNECTIONS_SERVER
  value: {{ .Values.db.maxConnectionsServer | quote }}
- name: POSTGRES_CONNECTION_CREATE_TIMEOUT_MILLIS
  value: {{ .Values.db.connectionCreateTimeoutMillis | quote }}
- name: POSTGRES_CONNECTION_ACQUIRE_TIMEOUT_MILLIS
  value: {{ .Values.db.connectionAcquireTimeoutMillis | quote }}

{{- if .Values.db.knexAsyncStackTraces.enabled }}
- name: KNEX_ASYNC_STACK_TRACES_ENABLED
  value: {{ .Values.db.knexAsyncStackTraces.enabled | quote }}
{{- end}}

{{- if .Values.db.knexImprovedTelemetryStackTraces }}
- name: KNEX_IMPROVED_TELEMETRY_STACK_TRACES
  value: {{ .Values.db.knexImprovedTelemetryStackTraces | quote }}
{{- end}}

- name: PGSSLMODE
  value: "{{ .Values.db.PGSSLMODE }}"

{{- if .Values.db.useCertificate }}
- name: NODE_EXTRA_CA_CERTS
  value: "/postgres-certificate/ca-certificate.crt"
{{- end }}

{{- if .Values.server.fileUploads.enabled }}
{{ else }}
- name: DISABLE_FILE_UPLOADS
  value: "true"
{{ end }}

{{- if .Values.server.adminOverride.enabled }}
- name: ADMIN_OVERRIDE_ENABLED
  value: "true"
{{- end }}

{{- if .Values.server.weeklyDigest.enabled }}
- name: WEEKLY_DIGEST_ENABLED
  value: "true"
{{- end }}

{{- if (quote .Values.server.monitoring.mp.enabled) }}
- name: ENABLE_MP
  value: {{ .Values.server.monitoring.mp.enabled | quote }}
{{- end }}

- name: NODE_TLS_REJECT_UNAUTHORIZED
  value: {{ .Values.tlsRejectUnauthorized | quote }}

# *** S3 Object Storage ***
{{- if (or .Values.s3.configMap.enabled .Values.s3.endpoint) }}
{{- $s3values := ((include "server.s3Values" .) | fromJson ) }}
- name: S3_ENDPOINT
  value: {{ $s3values.endpoint }}
- name: S3_ACCESS_KEY
  value: {{ $s3values.access_key }}
- name: S3_BUCKET
  value: {{ $s3values.bucket }}
- name: S3_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secretName }}
      key: {{ default "s3_secret_key" .Values.s3.secret_key.secretKey }}
- name: S3_CREATE_BUCKET
  value: "{{ .Values.s3.create_bucket }}"
- name: S3_REGION
  value: "{{ .Values.s3.region }}"

{{- end }}

# *** Authentication ***

# Local Auth
- name: STRATEGY_LOCAL
  value: "{{ .Values.server.auth.local.enabled }}"

# Google Auth
{{- if .Values.server.auth.google.enabled }}
- name: STRATEGY_GOOGLE
  value: "true"
- name: GOOGLE_CLIENT_ID
  value: {{ .Values.server.auth.google.client_id }}
- name: GOOGLE_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ default .Values.secretName .Values.server.auth.google.clientSecret.secretName }}
      key: {{ default "google_client_secret" .Values.server.auth.google.clientSecret.secretKey }}
{{- end }}

# Github Auth
{{- if .Values.server.auth.github.enabled }}
- name: STRATEGY_GITHUB
  value: "true"
- name: GITHUB_CLIENT_ID
  value: {{ .Values.server.auth.github.client_id }}
- name: GITHUB_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ default .Values.secretName .Values.server.auth.github.clientSecret.secretName }}
      key: {{ default "github_client_secret" .Values.server.auth.github.clientSecret.secretKey }}
{{- end }}

# AzureAD Auth
{{- if .Values.server.auth.azure_ad.enabled }}
- name: STRATEGY_AZURE_AD
  value: "true"
- name: AZURE_AD_ORG_NAME
  value: {{ .Values.server.auth.azure_ad.org_name }}
- name: AZURE_AD_IDENTITY_METADATA
  value: {{ .Values.server.auth.azure_ad.identity_metadata }}
- name: AZURE_AD_ISSUER
  value: {{ .Values.server.auth.azure_ad.issuer }}
- name: AZURE_AD_CLIENT_ID
  value: {{ .Values.server.auth.azure_ad.client_id }}
- name: AZURE_AD_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ default .Values.secretName .Values.server.auth.azure_ad.clientSecret.secretName }}
      key: {{ default "azure_ad_client_secret" .Values.server.auth.azure_ad.clientSecret.secretKey }}
{{- end }}


# OpenID Connect Auth
{{- if .Values.server.auth.oidc.enabled }}
- name: STRATEGY_OIDC
  value: "true"
- name: OIDC_NAME
  value: {{ .Values.server.auth.oidc.name }}
- name: OIDC_DISCOVERY_URL
  value: {{ .Values.server.auth.oidc.discovery_url }}
- name: OIDC_CLIENT_ID
  value: {{ .Values.server.auth.oidc.client_id }}
- name: OIDC_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ default .Values.secretName .Values.server.auth.oidc.clientSecret.secretName }}
      key: {{ default "oidc_client_secret" .Values.server.auth.oidc.clientSecret.secretKey }}
{{- end }}


# *** Email ***

{{- if .Values.server.email.enabled }}
- name: EMAIL
  value: "true"
- name: EMAIL_HOST
  value: "{{ .Values.server.email.host }}"
- name: EMAIL_PORT
  value: "{{ .Values.server.email.port }}"
- name: EMAIL_USERNAME
  value: "{{ .Values.server.email.username }}"
- name: EMAIL_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ default .Values.secretName .Values.server.email.password.secretName }}
      key: {{ default "email_password" .Values.server.email.password.secretKey }}
- name: EMAIL_FROM
  value: "{{ .Values.server.email.from }}"
{{- end }}

# *** Newsletter ***
{{- if .Values.global.featureFlags.mailchimp.enabled }}
- name: MAILCHIMP_ENABLED
  value: "true"
- name: MAILCHIMP_API_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.global.featureFlags.mailchimp.secretName }}
      key: mailchimp_api_key
- name: MAILCHIMP_SERVER_PREFIX
  value: "{{ .Values.global.featureFlags.mailchimp.serverPrefix}}"

- name: MAILCHIMP_NEWSLETTER_LIST_ID
  value: "{{ .Values.global.featureFlags.mailchimp.newsletterListId}}"

- name: MAILCHIMP_ONBOARDING_LIST_ID
  value: "{{ .Values.global.featureFlags.mailchimp.onboardingListId}}"

- name: MAILCHIMP_ONBOARDING_JOURNEY_ID
  value: "{{ .Values.global.featureFlags.mailchimp.onboardingJourneyId}}"

- name: MAILCHIMP_ONBOARDING_STEP_ID
  value: "{{ .Values.global.featureFlags.mailchimp.onboardingStepId}}"
{{- end }}

# Monitoring - Apollo
{{- if .Values.server.monitoring.apollo.enabled }}
- name: APOLLO_GRAPH_ID
  value: {{ .Values.server.monitoring.apollo.graph_id }}
- name: APOLLO_SCHEMA_REPORTING
  value: "true"
- name: APOLLO_GRAPH_VARIANT
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
- name: APOLLO_SERVER_ID
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: APOLLO_SERVER_PLATFORM
  value: "kubernetes/deployment"
- name: APOLLO_KEY
  valueFrom:
    secretKeyRef:
      name: {{ default .Values.secretName .Values.server.monitoring.apollo.key.secretName }}
      key: {{ default "apollo_key" .Values.server.monitoring.apollo.key.secretKey }}
{{- end }}

# Rate Limiting

- name: RATELIMITER_ENABLED
  value: "{{ .Values.server.ratelimiting.enabled }}"

{{- if .Values.server.ratelimiting.all_requests }}
- name: RATELIMIT_ALL_REQUESTS
  value: "{{ .Values.server.ratelimiting.all_requests }}"
{{- end }}
{{- if .Values.server.ratelimiting.burst_all_requests }}
- name: RATELIMIT_BURST_ALL_REQUESTS
  value: "{{ .Values.server.ratelimiting.burst_all_requests }}"
{{- end }}
{{- if .Values.server.ratelimiting.user_create }}
- name: RATELIMIT_USER_CREATE
  value: "{{ .Values.server.ratelimiting.user_create }}"
{{- end }}
{{- if .Values.server.ratelimiting.burst_user_create }}
- name: RATELIMIT_BURST_USER_CREATE
  value: "{{ .Values.server.ratelimiting.burst_user_create }}"
{{- end }}
{{- if .Values.server.ratelimiting.stream_create }}
- name: RATELIMIT_STREAM_CREATE
  value: "{{ .Values.server.ratelimiting.stream_create }}"
{{- end }}
{{- if .Values.server.ratelimiting.burst_stream_create }}
- name: RATELIMIT_BURST_STREAM_CREATE
  value: "{{ .Values.server.ratelimiting.burst_stream_create }}"
{{- end }}
{{- if .Values.server.ratelimiting.commit_create }}
- name: RATELIMIT_COMMIT_CREATE
  value: "{{ .Values.server.ratelimiting.commit_create }}"
{{- end }}
{{- if .Values.server.ratelimiting.burst_commit_create }}
- name: RATELIMIT_BURST_COMMIT_CREATE
  value: "{{ .Values.server.ratelimiting.burst_commit_create }}"
{{- end }}
{{- if .Values.server.ratelimiting.post_getobjects_streamid }}
- name: RATELIMIT_POST_GETOBJECTS_STREAMID
  value: "{{ .Values.server.ratelimiting.post_getobjects_streamid }}"
{{- end }}
{{- if .Values.server.ratelimiting.burst_post_getobjects_streamid }}
- name: RATELIMIT_BURST_POST_GETOBJECTS_STREAMID
  value: "{{ .Values.server.ratelimiting.burst_post_getobjects_streamid }}"
{{- end }}
{{- if .Values.server.ratelimiting.post_diff_streamid }}
- name: RATELIMIT_POST_DIFF_STREAMID
  value: "{{ .Values.server.ratelimiting.post_diff_streamid }}"
{{- end }}
{{- if .Values.server.ratelimiting.burst_post_diff_streamid }}
- name: RATELIMIT_BURST_POST_DIFF_STREAMID
  value: "{{ .Values.server.ratelimiting.burst_post_diff_streamid }}"
{{- end }}
{{- if .Values.server.ratelimiting.post_objects_streamid }}
- name: RATELIMIT_POST_OBJECTS_STREAMID
  value: "{{ .Values.server.ratelimiting.post_objects_streamid }}"
{{- end }}
{{- if .Values.server.ratelimiting.burst_post_objects_streamid }}
- name: RATELIMIT_BURST_POST_OBJECTS_STREAMID
  value: "{{ .Values.server.ratelimiting.burst_post_objects_streamid }}"
{{- end }}
{{- if .Values.server.ratelimiting.get_objects_streamid_objectid }}
- name: RATELIMIT_GET_OBJECTS_STREAMID_OBJECTID
  value: "{{ .Values.server.ratelimiting.get_objects_streamid_objectid }}"
{{- end }}
{{- if .Values.server.ratelimiting.burst_get_objects_streamid_objectid }}
- name: RATELIMIT_BURST_GET_OBJECTS_STREAMID_OBJECTID
  value: "{{ .Values.server.ratelimiting.burst_get_objects_streamid_objectid }}"
{{- end }}
{{- if .Values.server.ratelimiting.get_objects_streamid_objectid_single }}
- name: RATELIMIT_GET_OBJECTS_STREAMID_OBJECTID_SINGLE
  value: "{{ .Values.server.ratelimiting.get_objects_streamid_objectid_single }}"
{{- end }}
{{- if .Values.server.ratelimiting.burst_get_objects_streamid_objectid_single }}
- name: RATELIMIT_BURST_GET_OBJECTS_STREAMID_OBJECTID_SINGLE
  value: "{{ .Values.server.ratelimiting.burst_get_objects_streamid_objectid_single }}"
{{- end }}
{{- if .Values.server.ratelimiting.post_graphql }}
- name: RATELIMIT_POST_GRAPHQL
  value: "{{ .Values.server.ratelimiting.post_graphql }}"
{{- end }}
{{- if .Values.server.ratelimiting.burst_post_graphql }}
- name: RATELIMIT_BURST_POST_GRAPHQL
  value: "{{ .Values.server.ratelimiting.burst_post_graphql }}"
{{- end }}
{{- if .Values.server.ratelimiting.get_auth }}
- name: RATELIMIT_GET_AUTH
  value: "{{ .Values.server.ratelimiting.get_auth }}"
{{- end }}
{{- if .Values.server.ratelimiting.burst_get_auth }}
- name: RATELIMIT_BURST_GET_AUTH
  value: "{{ .Values.server.ratelimiting.burst_get_auth }}"
{{- end }}
{{- if .Values.openTelemetry.tracing.url }}
- name: OTEL_TRACE_URL
  value: {{ .Values.openTelemetry.tracing.url | quote }}
{{- end }}
{{- if .Values.openTelemetry.tracing.key }}
- name: OTEL_TRACE_KEY
  value: {{ .Values.openTelemetry.tracing.key | quote }}
{{- end }}
{{- if .Values.openTelemetry.tracing.value }}
- name: OTEL_TRACE_VALUE
  value: {{ .Values.openTelemetry.tracing.value | quote }}
{{- end }}
{{- if .Values.global.featureFlags.workspacesMultiRegion.enabled }}
- name: MULTI_REGION_CONFIG_PATH
  value: "/multi-region-config/multi-region-config.json"
{{- end }}
{{- end }}
