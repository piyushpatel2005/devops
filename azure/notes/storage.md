# Azure Storage


Install Azure CLI on Windows or Linux and these commands can be checked.

```shell
az storage -h # get help for storage
az storage account -h # get help for storage account
az storage account check-name -n <storage_name> # check if storage account name is available
az storage account check-name -n <storage_name> -h # other options for available output
az storage account create -n <storage_name> -g <resource_group> --kind StorageV2 -o jsonc # create storage account
az storage account list -g <resource_group> -o table # output storage accounts in a resource group in table format
```

We can query for specific information using JMESPATH notation. This is a query language for JSON.

```shell
az storage account list -g <resource_group_name> -o json --query "[].name" # returns names in array format
az storage account list -g <resource_group_name> -o json --query "[].{name: name}" # returns names in object format
az storage account delete -g <resource_group_name> -n <storage_account> # delete a storage account
```

```shell
az storage account show -n <storage_name> -g <resource_group_name> -o jsonc --query "{name: name, accessTier: accessTier, enableHttpsTrafficOnly: enableHttpsTrafficOnly, tags: tags}"
az storage account update -h # see help for updating storage account
az storage account update -n <storage_name> -g <resource_group_name> --access-tier Cool # change access tier from Hot to cool, returns updated resource
az storage account update -n <storage_name> -g <resource_group_name> --https-only true # enable https only traffic
az storage account update -n <storage_name> -g <resource_group_name> --tags project1 teamB # add tags to storage account
```