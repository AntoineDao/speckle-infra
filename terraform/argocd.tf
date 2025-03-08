provider "helm" {
  kubernetes {
    host                   = "https://${module.gke.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata.0.name
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = "7.8.9"

  values = [
    <<EOF
createAggregateRoles: false
controller:
  replicas: 1
  enableStatefulSet: true
  logFormat: json
  logLevel: info
  terminationGracePeriodSeconds: 25 # GKE Autopilot value
  resources:
    limits:
      cpu: 1
      memory: 1Gi
    requests:
      cpu: 1
      memory: 1Gi
  nodeSelector:
    cloud.google.com/gke-spot: "true"

global:
  format: json
  level: info

dex:
  enabled: false

redis:
  enabled: true
  nodeSelector:
    cloud.google.com/gke-spot: "true"
  terminationGracePeriodSeconds: 25 # GKE Autopilot value
  
server:
  replicas: 1
  autoscaling:
    enabled: false
  extraArgs:
    - --insecure

  logFormat: json
  logLevel: info

  resources:
    limits:
      cpu: 250m
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 512Mi

  nodeSelector:
    cloud.google.com/gke-spot: "true"
  
  terminationGracePeriodSeconds: 25 # GKE Autopilot value

  certificate:
    enabled: false

  ingress:
    enabled: false
    ingressClassName: nginx
    hostname: argocd.speckle.dev

  ingressGrpc:
    enabled: false

  # -- Deploy Argo CD Applications within this helm release
  # @default -- `[]` (See [values.yaml])
  ## Ref: https://github.com/argoproj/argo-cd/blob/master/docs/operator-manual/
  additionalApplications:
  - name: bootstrap
    namespace: argocd
    finalizers:
    - resources-finalizer.argocd.argoproj.io
    project: default
    source:
      repoURL: https://github.com/antoinedao/speckle-infra
      targetRevision: HEAD
      path: bootstrap
      directory:
        recurse: true
    destination:
      server: https://kubernetes.default.svc
      namespace: argocd
    syncPolicy:
      automated:
        prune: false
        selfHeal: false

  # -- Manage Argo CD configmap (Declarative Setup)
  ## Ref: https://github.com/argoproj/argo-cd/blob/master/docs/operator-manual/argocd-cm.yaml
  configEnabled: true
  # -- [General Argo CD configuration]

  # -- Whether or not to create the configmap. If false, it is expected the configmap will be created
  # by something else. Argo CD will not work if there is no configMap created with the name above.
  rbacConfigCreate: true

  clusterAdminAccess:
    enabled: true

  extensions:
    enabled: false

repoServer:
  logFormat: json
  logLevel: info

  nodeSelector:
    cloud.google.com/gke-spot: "true"

  terminationGracePeriodSeconds: 25 # GKE Autopilot value
  

## Argo Configs
configs:
  cm:
    # Argo CD instance label key
    application.instanceLabelKey: argocd.argoproj.io/instance
    server.rbac.log.enforce.enable: "false"
    exec.enabled: "false"
    admin.enabled: "true"
  rbac:
    {}

  ## - https://argo-cd.readthedocs.io/en/stable/operator-manual/security/#external-cluster-credentials
  clusterCredentials:
    []

  # -- Known Hosts configmap annotations
  knownHostsAnnotations: {}
  knownHosts:
    data:
      # -- Known Hosts
      # @default -- See [values.yaml]
      ssh_known_hosts: |
        bitbucket.org ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==
        github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
        github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
        github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
        gitlab.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFSMqzJeV9rUzU4kWitGjeR4PWSa29SPqJ1fVkhtj3Hw9xjLVXVYrU9QlYWrOLXBpQ6KWjbjTDTdDkoohFzgbEY=
        gitlab.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf
        gitlab.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsj2bNKTBSpIYDEGk9KxsGh3mySTRgMtXL583qmBpzeQ+jqCMRgBqB98u3z++J1sKlXHWfM9dyhSevkMwSbhoR8XIq/U0tCNyokEi/ueaBMCvbcTHhO7FcwzY92WK4Yt0aGROY5qX2UKSeOvuP4D6TPqKF1onrSzH9bx9XUf2lEdWT/ia1NEKjunUqu1xOB/StKDHMoX4/OKyIzuS0q/T1zOATthvasJFoPrAjkohTyaDUz2LN5JoH839hViyEG82yB+MjcFV5MU3N1l1QL3cVUCh93xSaua1N85qivl+siMkPGbO5xR/En4iEY6K2XPASUEMaieWVNTRCtJ4S8H+9
        ssh.dev.azure.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7Hr1oTWqNqOlzGJOfGJ4NakVyIzf1rXYd4d7wo6jBlkLvCA4odBlL0mDUyZ0/QUfTTqeu+tm22gOsv+VrVTMk6vwRU75gY/y9ut5Mb3bR5BV58dKXyq9A9UeB5Cakehn5Zgm6x1mKoVyf+FFn26iYqXJRgzIZZcZ5V6hrE0Qg39kZm4az48o0AUbf6Sp4SLdvnuMa2sVNwHBboS7EJkm57XQPVU3/QpyNLHbWDdzwtrlS+ez30S3AdYhLKEOxAG8weOnyrtLJAUen9mTkol8oII1edf7mWWbWVf0nBmly21+nZcmCTISQBtdcyPaEno7fFQMDD26/s0lfKob4Kw8H
        vs-ssh.visualstudio.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7Hr1oTWqNqOlzGJOfGJ4NakVyIzf1rXYd4d7wo6jBlkLvCA4odBlL0mDUyZ0/QUfTTqeu+tm22gOsv+VrVTMk6vwRU75gY/y9ut5Mb3bR5BV58dKXyq9A9UeB5Cakehn5Zgm6x1mKoVyf+FFn26iYqXJRgzIZZcZ5V6hrE0Qg39kZm4az48o0AUbf6Sp4SLdvnuMa2sVNwHBboS7EJkm57XQPVU3/QpyNLHbWDdzwtrlS+ez30S3AdYhLKEOxAG8weOnyrtLJAUen9mTkol8oII1edf7mWWbWVf0nBmly21+nZcmCTISQBtdcyPaEno7fFQMDD26/s0lfKob4Kw8H

  # -- TLS certificate configmap annotations
  tlsCertsAnnotations: {}
  # -- TLS certificate
  # @default -- See [values.yaml]
  tlsCerts:
    {}

  # -- Repository credentials to be used as Templates for other repos
  ## Creates a secret for each key/value specified below to create repository credentials
  credentialTemplates: {}

  # -- Repositories list to be used by applications
  ## Creates a secret for each key/value specified below to create repositories
  ## Note: the last example in the list would use a repository credential template, configured under "configs.repositoryCredentials".
  repositories:
    speckle-deployment-repository:
      url: git@github.com:antoinedao/speckle-infra

  secret:
    # -- Create the argocd-secret
    createSecret: true
    # -- Shared secret for authenticating GitHub webhook events
    githubSecret: ""

    # -- Bcrypt hashed admin password
    ## Argo expects the password in the secret to be bcrypt hashed. You can create this hash with
    ## `htpasswd -nbBC 10 "" $ARGO_PWD | tr -d ':\n' | sed 's/$2y/$2a/'`
    argocdServerAdminPassword: ""
    # -- Admin password modification time. Eg. `"2006-01-02T15:04:05Z"`
    # @default -- `""` (defaults to current time)
    argocdServerAdminPasswordMtime: ""

applicationSet:
  enabled: true
  name: applicationset-controller
  replicaCount: 1

  ## Webhook for the Git Generator
  ## Ref: https://argocd-applicationset.readthedocs.io/en/master/Generators-Git/#webhook-configuration)
  webhook:
    ingress:
      enabled: false

notifications:
  enabled: false
EOF
  ]
}


