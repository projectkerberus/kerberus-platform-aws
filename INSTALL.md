# Installer

## Description

The installer is composed of a Terraform recipe which installs and configure the following component on a Kubernetes cluster:

- [Crossplane](https://github.com/crossplane/crossplane), the [GCP](https://github.com/crossplane/provider-gcp) and [helm](https://github.com/crossplane-contrib/provider-helm) provider;
- installation of a Crossplane package for [GCP platform reference](https://github.com/idallaserra/platform-ref-gcp) defining the API and XRD for Networking, GKE, and CloudSQL resources;
- GCP service account with required permission for creating the resources;
- [Argo CD](https://argoproj.github.io/projects/argo-cd) for GitOps resources management with relative Ingress Controller.


## Requirements

### Kerberus Platform

To correctly install the platform there are some requirements:

1. [docker](https://www.docker.com/);
2. a Kubernetes cluster with default storage-class, ingress controller and, the relative `kubeconfig` file;
3. an AWS admin [shared credentials file](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)  (Since the Installer takes care of creating the necessary IAM account on AWS, admin permission is a must);

## Installation with Docker

1. Login to `ghcr.io`:
   ```shell
    export CR_PAT=YOUR_GITHUB_TOKEN
    echo $CR_PAT | docker login ghcr.io -u GITHUB_USERNAME --password-stdin
   ```
   > For more information about the github token please refer here: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-to-the-container-registry

2. Create a Github App on your organization:

    * Go to `https://github.com/organizations/<organization>/settings/apps/new`;

    * Populate the form field as follow:

      * `GitHub App name`: `Project Kerberus`
      * `Homepage URL`: `https://projectkerberus.io/`
      * Under section *Identifying and authorizing users*: 
        * `Callback URL`: `https://<kerberus-dashboard-fqdn>/api/auth/github/`
        * Checkbox `Expire user authorization tokens` need to be flagged
      * Under section *Webhook*:
        * Checkbox `Active` need to be deflagged
      * Under section *Repository permissions*:
        * This permission need to be "Read & write": `Actions`, `Administration`, `Checks`, `Contents`, `Deployments`, `Discussions`, `Environments`, `Issues`, `Organization packages`, `Packages`, `Pages`, `Pull requests`, `Webhooks`, `Projects`, `Secret scanning alerts`, `Secrets`, `Security events`, `Commit statuses` and `Workflows`;
        * This permission need to be "Read only": `Metadata` and `Dependabot alerts`;
        * This permission can be "No access": `Content references` and `Single file` .
      * The response of the question "Where can this GitHub App be installed?" should be "Only on this account"

    * Click on "Create GitHub App"

    * Under the *general* tab, click on "Generate a new client secret"

      > Please take note of this secret because we are going to use it later

    * Under the *general* tab, under the section *Private keys* click on "Generate a private key"

    * Under the *Install App* tab, click the green button "Install"

3. Create a folder (in this tutorial we will refer to them with the name of `data`) to store our files and the `terraform.tfstate`:

    ```shell
    mkdir data
    cd ./data
    ```

4. Inside the `data` folder do the following:

   * Copy your  `kubeconfig` file;

   * Copy your [shared credentials file](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html);

   * Copy and edit the `kerberus_dashboard_values.yaml` file
     ```shell
     cp ../terraform/files/kerberus_dashboard_values.yaml ./kerberus_dashboard_values.yaml
     vi kerberus_dashboard_values.yaml
     ```

   * create a file named `terraform.tfvars` containing at minimum the following variables:

    ```yaml
    # K8S vars
    path_kubeconfig       = "./data/<KUBECONFIG file name>"
    kerberus_k8s_endpoint = "<kubernetes api endpoint>"
   
    # Kerberus-Dashboard
    kerberus_dashboard_values_path = "./data/kerberus_dashboard_values.yaml"
   
    # AWS vars
    aws_profile                      = "<shared credentials profile name>"
    aws_shared_credentials_file_path = "./data/<shared credentials file>"
   
    # Argo vars
    argocd_url         = "<domain name of ARGOCD>"
   
    # GitHub Vars 
    github_app_id             = "<Github app id>"
    github_app_client_id      = "<Github app client id>"
    github_app_client_secret  = "<Github app client secret>"
    github_app_webhook_secret = "<Github app webhook secret>"
    github_app_private_key    = "<Github app private key>"
    ```

5. Review and check the execution plan:

    ```shell
    docker run --name=kerberus-plan --rm -v <abs-path-to-data-folder>/data:/kerberus-platform/data ghcr.io/projectkerberus/kerberus-platform-aws:0.2.0 plan -var-file=./data/terraform.tfvars
    ```

6. Apply the plan:

    ```bash
    docker run --name=kerberus-apply --rm -v <abs-path-to-data-folder>/data:/kerberus-platform/data ghcr.io/projectkerberus/kerberus-platform-aws:0.2.0 apply --auto-approve -var-file=./data/terraform.tfvars -state=./data/terraform.tfstate
    ```

7. If Terraform fails with the following error:
    ```bash
    ╷
    │ Error: failed to execute "/bin/bash":   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
    │                                  Dload  Upload   Total   Spent    Left  Speed
    28   225    0     0  100    63      0    170 --:--:-- --:--:-- --:--:--   170
    │ curl: (22) The requested URL returned error: 503
    │ Fail to retreive bearer token. Please check if https://ARGOCD_HOSTNAME is a valid endpoint
    │
    │
    │   with module.argocd.data.external.generate_argocd_token,
    │   on .terraform/modules/argocd/main.tf line 46, in data "external" "generate_argocd_token":
    │   46: data "external" "generate_argocd_token" {
    │
    ╵
    ```
    It's because Terraform needs to reach ArgoCD. For this reason please expose <https://ARGOCD_HOSTNAME>.

8. Run Terraform apply again:

    ```bash
    docker run --name=kerberus-apply --rm -v <abs-path-to-data-folder>/data:/kerberus-platform/data ghcr.io/projectkerberus/kerberus-platform-aws:0.2.0 apply --auto-approve -var-file=./data/terraform.tfvars -state=./data/terraform.tfstate
    ```

9. Expose <https://KERBERUS_DASHBOARD_HOSTNAME> and Enjoy! 

## Uninstall

```bash
docker run --name=kerberus-destroy --rm -v <abs-path-to-data-folder>/data:/kerberus-platform/data ghcr.io/projectkerberus/kerberus-platform-aws:0.2.0 destroy --auto-approve -var-file=./data/terraform.tfvars -state=./data/terraform.tfstate
```

Be careful, like explained in the [Crossplane documentation](https://crossplane.io/docs/v1.0/getting-started/install-configure.html#install-crossplane-cli) CRD resources are not removed, so additional command is required:

```shell
kubectl patch lock lock -p '{"metadata":{"finalizers": []}}' --type=merge
kubectl get crd -o name | grep crossplane.io | xargs kubectl delete
```
## Support

TBD
## Roadmap

TBD
## Contributing

Please refer to Contributing file in repository.

## License

See [LICENSE](./LICENSE) for full details.
