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

function Main
{
    Login
}

Main