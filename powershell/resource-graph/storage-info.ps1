# Getting authenticated
Connect-AzAccount

# Query 1 - Return 1 storage account from my subscriptions
Search-AzGraph -Query "where type =~ 'Microsoft.Storage/storageAccounts' | limit 1"

# Query 2 - Count the # of storage accounts within my subscriptions
$resourceType = 'Microsoft.Storage/storageAccounts'
$query = "where type =~ '$resourceType' | summarize count()"
Search-AzGraph -Query $query

# Query 3 - Count the # of storage accounts and segment by location
$resourceType = 'Microsoft.Storage/storageAccounts'
$query = "where type =~ '$resourceType' | summarize count() by location"
Search-AzGraph -Query $query

# Query 4 - Storing the results as objects
$resourceType = 'Microsoft.Storage/storageAccounts'
$query = "where type =~ '$resourceType' | limit 1"
$storageAccount = Search-AzGraph -Query $query
$storageAccount.GetType()

# Query 5 - Looking at query's result properties
$resourceType = 'Microsoft.Storage/storageAccounts'
$query = "where type =~ '$resourceType' | limit 1"
$storageAccount = Search-AzGraph -Query $query 
$storageAccount.properties

# Query 6 - Getting Resource Tags by Resource
$resourceType = 'Microsoft.Storage/storageAccounts'
$query = "where type =~ '$resourceType' | project name, tags" 
Search-AzGraph -Query $query

# Query 7 - Getting Resource Tags Schema
$resourceType = 'Microsoft.Storage/storageAccounts'
$query = "where type =~ '$resourceType' | project tags | summarize buildschema(tags)"
Search-AzGraph -Query $query

