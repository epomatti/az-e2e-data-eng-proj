# Azure End-To-End Data Engineering Project

Complete data ingestion, transformation and load using Azure services.

> Implementation reference from [this video][1].

Create the `.auto.tfvars` files and set the parameters as you prefer:

```sh
cp azure/config/dev.tfvars azure/.auto.tfvars
```

Check your public IP address to be added in the firewalls allow rules:

```sh
dig +short myip.opendns.com @resolver1.opendns.com
```

Download the [dataset][2] and extract the files to the directory `./dataset/`.

Add your public IP address to the `public_ip_address_to_allow` variable.

Create the resources on Azure:

```sh
terraform -chdir="azure" init
terraform -chdir="azure" apply -auto-approve
```

If you're not using Synapse immediately, pause the Synapse SQL pool to avoid costs while setting up the infrastructure:

```sh
az synapse sql pool pause -n pool1 --workspace-name synw-olympics -g rg-olympics
```

[1]: https://youtu.be/IaA9YNlg5hM?list=PL_ko60AZHL-pWXeO6YouiE-ZQlM02duKy
[2]: https://www.kaggle.com/datasets/arjunprasadsarkhel/2021-olympics-in-tokyo
