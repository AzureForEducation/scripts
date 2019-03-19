# Logging into Azure
Connect-AzAccount

# Defining global variables
$keyvaultname = 'your-keyvault-name'
$rgname = 'your-resource-group-name'
$aadclientsecret = 'your-client-secret'
$vmname = 'your-vm-name'
$appid = 'your-app-id'

# Getting KeyVault values
$keyvault = Get-AzKeyVault -VaultName $keyvaultname -ResourceGroupName $rgname
$keyvaulturi = $keyvault.VaultUri
$keyvaultresourceid = $keyvault.ResourceId

# Encrypting the SO Disk
Set-AzVMDiskEncryptionExtension -ResourceGroupName $rgname -VMName $vmname -AadClientID $appid -AadClientSecret $aadclientsecret -DiskEncryptionKeyVaultUrl $keyvaulturi -DiskEncryptionKeyVaultId $keyvaultresourceid

# Encrypting the Data disk
Set-AzVMDiskEncryptionExtension -ResourceGroupName $rgname -VMName $vmname -AadClientID $appid -AadClientSecret $aadclientsecret -DiskEncryptionKeyVaultUrl $keyvaulturi -DiskEncryptionKeyVaultId $keyvaultresourceid -VolumeType Data

# Getting the status of the encryption process
Get-AzVMDiskEncryptionStatus -VMName $vmname -ResourceGroupName $rgname