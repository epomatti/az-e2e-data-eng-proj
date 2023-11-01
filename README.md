# Azure End-To-End Data Engineering Project

Complete data ingestion, transformation and load using Azure services.

> Implementation reference from [this video][1].

Create the `.auto.tfvars` files and set the parameters as you prefer:

```sh
cp azure/
```

Create the resources on Azure:

```sh
terraform -chdir="azure" init
terraform -chdir="azure" apply -auto-approve
```

[1]: https://youtu.be/IaA9YNlg5hM?list=PL_ko60AZHL-pWXeO6YouiE-ZQlM02duKy
