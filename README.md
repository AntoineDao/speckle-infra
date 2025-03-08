# Speckle Infra

This repository contains the infrastructure code to deploy a production ready Speckle server.

## Architecture

### CI/CD

#### Helm

Helm charts are built, versioned and published to a Helm repository using GitHub Actions. The Helm repository is hosted on GitHub Pages. Here is the action we use for this: https://github.com/helm/chart-releaser-action



## Getting Started

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)

### GKE Cluster Setup
We set up a GKE AutoPilot cluster to limit costs to actually running containers. This will also create an initial ArgoCD deployment that will look at the `bootstrap` directory to start creating apps. We will keep controlling ArgoCD config from terraform to avoid any drift in configuration.

To create the cluster, run the following commands:

```bash
cd terraform
terraform init
terraform apply
```

> {!Note} Change the `project` variable in `terraform/variables.tf` to match your project.

You can then get the cluster credentials by running:

```bash
gcloud container clusters get-credentials speckle-cluster --region europe-southwest1
```

### ArgoCD Setup
ArgoCD is a GitOps tool that will manage the deployment of the Speckle server. We will use it to deploy the Speckle server and its dependencies.

You can bootstrap the ArgoCD controlled applications by creating the ApplicationSet in the `bootstrap` directory. This application set will look at everything in the `kubernetes` folder and create ArgoCD applications using parameters from the folder paths. We currently only have one deployment but this could be extended so ArgoCD would deploy to multiple regions or environments.

Here is the command to bootstrap the ArgoCD applications:

```bash
kubectl apply -f bootstrap
```


Get the ArgoCD password by running:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

You can then access the ArgoCD dashboard by running:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

You can then login to the ArgoCD dashboard by visiting `localhost:8080` and using the username `admin` and the password you got earlier.