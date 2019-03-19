# Logging into Azure
Connect-AzAccount

# Creating global variables
$keyvaultname = 'your-key-vault-name'
$rgname = 'your-resource-group-name'
$location = 'your-location'
$aadclientsecret = ConvertTo-SecureString 'your-password-plain-text' -AsPlainText -Force
$appname = 'your-app-name'

# Deploying Resource Group
New-AzResourceGroup -Name $rgname -Location $location

# Deploying a new Azure Key Vault
New-AzKeyVault -Name $keyvaultname -ResourceGroupName $rgname -Location $location

# Enabling disk encryption into the Key Vault
Set-AzKeyVaultAccessPolicy -VaultName $keyvaultname -ResourceGroupName $rgname -EnabledForDiskEncryption

# Registering the virtual app into Azure Active Directory
$aadapp = New-AzADApplication -DisplayName $appname -HomePage 'your-url' -IdentifierUris 'your-uri' -Password $aadclientsecret

# Getting the registed AppId
$appid = $aadapp.ApplicationId

# Creating a Service Principal for our application
$aadserviceprincipal = New-AzADServicePrincipal -ApplicationId $appid

# Allowing encryption and decryption processess for the app within the Key Vault
Set-AzKeyVaultAccessPolicy -VaultName $keyvaultname -ServicePrincipalName $appid -PermissionsToKeys encrypt,decrypt -PermissionsToSecrets set

