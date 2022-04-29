# The IR-mapping/ListAllEnvironments script

The aim of this script is to find and list all the machines that have an [integration runtime client](https://docs.microsoft.com/en-us/azure/data-factory/concepts-integration-runtime) installed. It uses the [Azure Rest APIs](https://docs.microsoft.com/en-us/rest/api/datafactory/) to iterate through all subscriptions available to the user.

When the script is done, a list of all inte nodes is exported in a CSV-file.

## The CSV-file

The file contains the following data:

- Subscription name
- Datafactory name
- IR-Name (Integration Runtime name)
- Node Name: The name of the node in Azure. Does not have to be the same as machine name
- Machine Name: The name of the server where the IR runtime client is installed.
- Status: Online or Offline
- Autoupdate: On means configured and you *should* be good to go
- Version Status:
  - UpToDate: No problems.
  - Expiring: the installed version will soon be out of support.
  - Expired: the installed version is not supported (good luck).
- Registered: The local date and time when the client was installed.
- Last Used: The local date and time when the client was last accessed.

What you need to look out for is expired versions in combination with active online nodes.

Consider removing/uninstalling inactive (last used) nodes.

## The script

In order to execute the script, you need to login with valid Azure credentials (usually your adm-account). You will only see data factories located in subscriptions you are allowed to (at least) `Read`. You also need to use PowerShell version 7.x. This does not work on Windows PowerShell (5.1).

Login will open a browser window and ask for your login, as normal. After login you can close the tab.

The script feeds back names of subscriptions and factores.

```
...
Looking in AzureSubscription1
Looking in Azure-Prod
Found node:  vmappne24
Looking in Azure-Test
Found node:  integration-test-001
Found node:  vmappne22
...
```

When the script is done a file called `Integration Runtime Nodes.csv` is saved in the same directory.

## Technical about the script

It uses the Azure Rest APIs and loops like this:

[Get Subscriptions](https://docs.microsoft.com/en-us/rest/api/resources/subscriptions/list)
- For each subscription ([Get all data factories](https://docs.microsoft.com/en-us/rest/api/resources/resources/list))
  - For each Datafactory ([Get all integration runtimes](https://docs.microsoft.com/en-us/rest/api/datafactory/integration-runtimes/list-by-factory))
    - For each Integration Runtime ([Get all Nodes and status](https://docs.microsoft.com/en-us/rest/api/datafactory/integration-runtimes/get-status))
      - For each Node (extract node info from Status response)

With each call (except the first one) the URL for the next call is constucted using the `id` property.

Here is an example of the response for getting all Data Factories in the DataAnalyticsDev subscription:

```JSON
{
    "value": [
        {
            "id": "/subscriptions/<subscriptionID>/resourceGroups/<resourcegroupname>/providers/Microsoft.DataFactory/factories/<datafactoryname>",
            "name": "<datafactoryname>",
            "type": "Microsoft.DataFactory/factories",
            "location": "eastus",
            "identity": {
                "principalId": "<GUID>",
                "tenantId": "<GUID>",
                "type": "SystemAssigned"
            }
        }
        ... More items
    ]
}
```

The ID-property can be used to get the next call; getting all the integration runtimes. Simply add `/integrationRuntimes` and the API-version ID at the end.

Only Self Hosted nodes are listed as those are the only ones we really care about.
