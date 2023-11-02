# Azure End-To-End Data Engineering Project

Complete data ingestion, transformation and load using Azure services.

> Implementation reference from [this video][1].

Create the `.auto.tfvars` files and set the parameters as you prefer:

```sh
cp azure/config/dev.tfvars azure/.auto.tfvars
```

The [dataset][2] is already available in the `./dataset/` directory and will be uploaded to the storage.

Create the resources on Azure:

```sh
terraform -chdir="azure" init
terraform -chdir="azure" apply -auto-approve
```

Trigger the pipeline to get the data into the stage filesystem:

```sh
az datafactory pipeline create-run \
    --resource-group rg-olympics \
    --name PrepareForDatabricks \
    --factory-name adf-olympics-sandbox
```

If you're not using Synapse immediately, pause the Synapse SQL pool to avoid costs while setting up the infrastructure:

```sh
az synapse sql pool pause -n pool1 --workspace-name synw-olympics -g rg-olympics
```

## Databricks

The previous Azure run should have created the `databricks/.auto.tfvars` file to configure Databricks.

Apply the Databricks configuration:

> 💡 If you haven't yet, you need to login to Databricks, which will create Key Vault policies.

```sh
terraform -chdir="databricks" init
terraform -chdir="databricks" apply -auto-approve
```

[1]: https://youtu.be/IaA9YNlg5hM?list=PL_ko60AZHL-pWXeO6YouiE-ZQlM02duKy
[2]: https://www.kaggle.com/datasets/arjunprasadsarkhel/2021-olympics-in-tokyo
