# Speckle Infra

This repository contains the infrastructure code to deploy a production ready Speckle server.

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



## Architecture

### CI/CD

#### Helm

Helm charts are built, versioned and published to a Helm repository using GitHub Actions. The Helm repository is hosted on GitHub Pages. Here is the action we use for this: https://github.com/helm/chart-releaser-action


### ArgoCD
The Github Action workflow in `.github/workflows/on-helm-chart-release.yml` will trigger on the release of a new Helm chart in this repository. It will then look through all references to the matching application in the `kubernetes` directory and update the ArgoCD application with the new Helm chart version.

An ApplicationSet in the `bootstrap` directory will create ArgoCD applications for each application in the `kubernetes` directory. The folder structure will determine so key information that can be used to deploy the applications in different contexts.

> `kubernetes/<app>/<cloud-provider>/<region>/<environment>/<namespace>`

Anything in the folder will be deployed, it could be raw Kubernetes objects, ArgoCD applications, Helm charts or Kustomize overlays. The `ApplicationSet` will look at the folder structure and create ArgoCD applications based on the parameters in the folder structure.

### Terraform
Terraform is used to set up the GKE cluster and the initial ArgoCD deployment. We use Terraform to manage the infrastructure and the ArgoCD configuration. We use the `terraform` directory to store the Terraform code.

### Future Improvements
- **Secrets Management**: We could use a tool like Sealed Secrets to encrypt secrets in the Git repository. We could also make use of whatever secrets management tool is available in the cloud provider.
- **Multiple Environments**: the folder stru

### Production Ready Speckle Server
There are quite a few things missing from this initial set up of the server. I definitely got lost in the weeds of setting up the infrastructure, CI/CD and refactoring the Speckle Server helm chart but didn't get to the actual Speckle server deployment. Unfortunately I spent too much time refactoring and got to the point where the Redis connection string is not being accepted... I could spend more time debugging but I think I have spent enough time on this. The main point is that we can see the CI/CD system and cloud infrastructure set up and ready to deploy the Speckle server.


Here are some things that need to be done to make this production ready:

- **Ingresses**: We need to set up ingresses for the Speckle server. This would require setting up cert-manager to manage TLS certificates and deciding on an ingress controller (let's say Nginx). We would also need to set up the DNS records to point to the ingress. This would be done with Terraform and Google Domains + Google Cloud DNS.
- **Replicas**: set up at least 2 replicas per server deployment and ensure pod disruption budgets are set up to avoid downtime during upgrades.
- **Backups**: Set up backups for the Postgres Database. I would probably use a managed database here rather than one running on the cluster.
- **Horizontal Scaling**: Enable the horizontal pod autoscaling for the Speckle server. This would require setting up the metrics server. Speckle server is a good candidate (as far as I know) because it mostly scales with requests.
- **Monitoring**: We would need to set up monitoring for the Speckle server. This would include setting up Prometheus and Grafana to monitor the server and setting up alerts in Google Cloud Monitoring or Alertmanager. I would focus on these metrics:
  - CPU and Memory usageL check for high usage above 90% over a 5 or 10 minute period
  - Request latency: I am not sure what the current latency objective is but I would set up alerts for latency above the 90th percentile
  - Error rate: I would specifically look for 500 errors
  - Synthetic monitoring: I would set up synthetic monitoring to ping the public url of the speckle server and alert if it goes down. This would ensure the full stack of DNS, ingress and the server is working. I would also set up separate montioring for the ingress itself.
- **Canary Deployments**: To ensure smooth upgrades and automatic roll-backs in case of deployment errors I would set up Argo Rollouts to run incremental rollouts using canary strategies. 
- **SQL Migrations**: I recommend _never_ allowing destructive migrations unless a feature has not been used for a few releases. This will ensure that we can run upgrades and rollback automatically safely

### Speckle Helm Chart Refactor
As mentioned above I spent a lot of time refactoring. The main reason for this was to make the chart more modular (ie: one chart per core service) and easier to deploy and compose in different environments. If I had more time I would have created an umbrella chart to group and version speckle server and other associated services.

Second I decided to refactor the feature flag system to include an "enabled" field and add configuration for that feature in the same place to make the values file more readable.

Here is an example for the billing integration set up:

```yaml
global:
  featureFlags:
    billingIntegration:
      enabled: false
      # This is a secret which should contain the following keys: 
      # stripe_api_key, stripe_endpoint_signing_key
      secretName: speckle-server-billing
      products:
        workspaceGuestSeat:
          id: some-random-id
          monthlyPriceID: some-random-id
          yearlyPriceID: some-random-id
        workspaceStarterSeat:
          id: some-random-id
          monthlyPriceID: some-random-id
          yearlyPriceID: some-random-id
        workspacePlusSeat:
          id: some-random-id
          monthlyPriceID: some-random-id
          yearlyPriceID: some-random-id
        workspaceBusinessSeat:
          id: some-random-id
          monthlyPriceID: some-random-id
          yearlyPriceID: some-random-id
```

I also decided to remove the Cilium Network Policies because they are very "opinionated" for a helm chart that is meant to be shared with an open source community. This is something I would then add in a wrapper chart or better in the `kubernetes` directory as raw Kubernetes objects specific to each application, region, cloud and environment.

Finally I chose to remove the secrets from the service accounts as this is now a legacy practice from Kubernetes 1.29 and above ([link](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/#auto-generated-legacy-serviceaccount-token-clean-up)).

### Multi Cloud Infrastructure

The configuration in this repository allows for the deployment of the Speckle server and other components (preview, import and automate services) to mutliple cloud providers and regions. The `kubernetes` directory is structured in a way that allows for the deployment of the same application to different cloud providers, regions and environments.

In order for the Speckle server to communicate with services running in other kubernetes clusters we would have to set up a secure connection between these services. Unfortunately Digital Ocean does not have any readily available VPN services available (that I know of...) so the next best solution will be to get services to communicate accross clusters through the public internet but using mTLS (mutual TLS) to authenticate and encrypt communication between the services. We could use Istio to achieve this (maybe a bit overkill), targetted proxy sidecars or just build in certificate management into the services themselves.

<img width="1320" alt="image" src="https://github.com/user-attachments/assets/5b2d8b88-6147-4f33-b238-c6cc44753f95" />

Deploying to other cloud providers would also allow us to make use of different node types (with GPUs or running Windows). 

Given the existing mono-helm-chart structure in specklesystems/speckle-server we would have to refactor the chart into multiple independent charts. This would allow us 

#### Non-Functional Considerations
- **Infrastructure Interdependency**: I had a quick scim through the codebase and I can't find examples of a the services sharing databases, redis queues or buckets. It looks like they mostly communicate back and forth with the speckle server and use queues that are only used by that service. If I have missed a case where there is shared infrastructure then we would have to plan some work to split them out before we can deploy to multiple clusters.
- **Logging and Monitoring Infrastructure**: Logging and Monitoring solutions differ accross cloud providers. We could set up open source solutions like prometheus, ELK etc... on each cluster but we would run the risk of not having a central place to look at logs and metrics. This could also cause issues with duplication of configuration and resources. I would recommend agreeing on a centralised solution that all logs and metrics can be sent to.
- 

One of the non-functional considerations here is for logging and metrics. 

