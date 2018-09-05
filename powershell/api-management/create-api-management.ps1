# Verifying if user is currently logged on Azure.
# If it is not, then call Login-AzureRmAccount.
function Login
{
    $needLogin = $true
    Try 
    {
        $content = Get-AzureRmContext
        if ($content) 
        {
            $needLogin = ([string]::IsNullOrEmpty($content.Account))
        } 
    } 
    Catch 
    {
        if ($_ -like "*Login-AzureRmAccount to login*") 
        {
            $needLogin = $true
        } 
        else 
        {
            throw
        }
    }

    if ($needLogin)
    {
        # Authenticating user
        Login-AzureRmAccount 

        # Listing all subscriptions under the logged user
        Get-AzureRmSubscription

        # Requesting the desired SubscriptionId
        $subscriptionId = Read-Host -Prompt "SubscriptionId (Guid) you'd like to set as default"
        
        # Setting the default account
        $accountSetResult = Set-AzureRmContext -SubscriptionId $subscriptionId
        
        if($accountSetResult)
        {
            Write-Host "Done. The context is now set up to" $subscriptionId"."
        }
        else
        {
            throw
        }
    }
    else
    {
        Write-Host "User already logged. Information about the tenant can be seen below:"
        Write-Host "--------------------------------------------------------------------"
        (Get-AzureRmContext).Subscription
    }
}

function VerifyExistanceOfResourceGroup($resourceGroup)
{
    Try
    {
        $rgReturned = Get-AzureRmResource -ResourceName $resourceGroup
    }
    Catch
    {
        if([string]::IsNullOrEmpty($rgReturned))
        {
            return $false
        }
        else
        {
            return $true
        }
    }
}

function CreateResourceGroup($resourceGroup)
{
    # Requesting additional information
    $location = Read-Host "Please, inform the Azure region for this Resource Group"

    if([string]::IsNullOrEmpty($location) -or [string]::IsNullOrEmpty($resourceGroup))
    {
        return $false
    }
    else
    {
        try 
        {
            New-AzureRmResourceGroup -Name $resourceGroup -Location $location
            return $true
        }
        catch 
        { 
            return $false
        }
    }
}

function Main
{
    # Step 1 - Veryfing and logging user
    Login

    # Step 2 - Verify if a resource group exists. If not, creates a new one.
    $resourceGroup = Read-Host -Prompt "Resource Group name (where Api Management will seat)"
    $resourceGroupExists = VerifyExistanceOfResourceGroup($resourceGroup)

    if($resourceGroupExists)
    {
        Write-Host "Creating a new API Management service into" $resourceGroup"..."
        CreateApiManagement($resourceGroup)
        Write-Host "Done."
    }
    else
    {
        Write-Host "Hang on. First, we need to create a new Resource Group..."
        $rgCreationStatus = CreateResourceGroup($resourceGroup)

        if($rgCreationStatus)
        {
            Write-Host "Done. Now, creating the API Management..."

            $apimCreationStatus = CreateApiManagement($resourceGroup)

            if($apimCreationStatus)
            {
                Write-Host "Done."
            }
        }
        else
        {
            Write-Host "Ops! There was an error when we've tried to create the new Resource Group."
            Write-Host "Program will close."
        }
    }
}

# Calling the main function
Main