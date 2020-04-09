# Deploy an Azure API Manager instance in Internal VNET mode with an Application Gateway
# serving as external interface and applying WAF as well. 

# This script uses the new AZ PowerShell cmdlets
# https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az?view=azps-1.6.0

# This script is based on Andrew Kelleher's script, available in his personal repository here:
# https://github.com/andrew-kelleher/AzureAPIMAppGW/blob/master/deployAPIM-AppGW.ps1#L11

# Login to Azure 
Connect-AzAccount

# Setting up the default subscription for the context
$subscriptionId = "your-subscription-guid-here"
Get-AzSubscription -Subscriptionid $subscriptionId | Select-AzSubscription

# If you don't have one, it creates a new resource group to hold the resources
$resGroupName = "your-rg-name"
$location = "eastus" # select your prefered region
New-AzResourceGroup -Name $resGroupName -Location $location

# If you're creating a new vnet, this is going to create a new subnet to hold up App Gateway service.
$appgatewaysubnet = New-AzVirtualNetworkSubnetConfig -Name "your-appgw-subnet" -AddressPrefix "10.0.0.0/24"

# If you're creating a new vnet, this is going to configure a new subnet for APIM service.
$apimsubnet = New-AzVirtualNetworkSubnetConfig -Name "your-apim-subnet" -AddressPrefix "10.0.1.0/24"

# If you don't have one, this is going to create a new vnet with two subnets.
# To get the info of your existing vnet, you can run "$vnet = Get-AzVirtualNetwork -Name your-vnet-name -ResourceGroupName your-rg-name" instead.
$vnet = New-AzVirtualNetwork -Name "your-vnet" -ResourceGroupName $resGroupName -Location $location -AddressPrefix "10.0.0.0/16" -Subnet $appgatewaysubnet,$apimsubnet

# Assign subnet variables
$appgatewaysubnetdata = $vnet.Subnets[0]
$apimsubnetdata = $vnet.Subnets[1]


# ------------- Deploy API Management  ------------- #

# Create an API Management VNET object
$apimVirtualNetwork = New-AzApiManagementVirtualNetwork -SubnetResourceId $apimsubnetdata.Id

# Create an API-M service inside the VNET
$apimServiceName = "your-apim-name"
$apimOrganization = "your company/org name"
$apimAdminEmail = "your-company-admin-email"
$apimService = New-AzApiManagement -ResourceGroupName $resGroupName -Location $location -Name $apimServiceName -Organization $apimOrganization -AdminEmail $apimAdminEmail -VirtualNetwork $apimVirtualNetwork -VpnType "Internal" -Sku "Developer"

# Specify cert configuration
$gatewayHostname = "api.your-domain.org"
$portalHostname = "portal.your-domain.org"
$gatewayCertCerPath = "C:\temp\apicert.cer"
$gatewayCertPfxPath = "C:\temp\apicert.pfx"
$portalCertPfxPath = "C:\temp\portalcert.pfx"
$gatewayCertPfxPassword = "password-for-your-apicert.pfx"
$portalCertPfxPassword = "password-for-your-apicert.cer"

$certPwd = ConvertTo-SecureString -String $gatewayCertPfxPassword -AsPlainText -Force
$certPortalPwd = ConvertTo-SecureString -String $portalCertPfxPassword -AsPlainText -Force

# Create and set the hostname configuration objects for the proxy and portal
$proxyHostnameConfig = New-AzApiManagementCustomHostnameConfiguration -Hostname $gatewayHostname -HostnameType Proxy -PfxPath $gatewayCertPfxPath -PfxPassword $certPwd
$portalHostnameConfig = New-AzApiManagementCustomHostnameConfiguration -Hostname $portalHostname -HostnameType Portal -PfxPath $portalCertPfxPath -PfxPassword $certPortalPwd

$apimService.ProxyCustomHostnameConfiguration = $proxyHostnameConfig
$apimService.PortalCustomHostnameConfiguration = $portalHostnameConfig
Set-AzApiManagement -InputObject $apimService


# ------------- Deploy Application Gateway  ------------- #

# Create a public IP address for the Application Gateway front-end
$publicip = New-AzPublicIpAddress -ResourceGroupName $resGroupName -name "your-appgw-pip" -location $location -AllocationMethod Dynamic

# Create Application Gateway configuration
# step 1 - create App GW IP config
$gipconfig = New-AzApplicationGatewayIPConfiguration -Name "gatewayIP" -Subnet $appgatewaysubnetdata

# step 2 - configure the front-end IP port for the public IP endpoint
$fp01 = New-AzApplicationGatewayFrontendPort -Name "frontend-port443" -Port 443

# step 3 - configure the front-end IP with the public IP endpoint
$fipconfig01 = New-AzApplicationGatewayFrontendIPConfig -Name "frontend1" -PublicIPAddress $publicip

# step 4 - configure certs for the App Gateway
$cert = New-AzApplicationGatewaySslCertificate -Name "apim-gw-cert" -CertificateFile $gatewayCertPfxPath -Password $certPwd
$certPortal = New-AzApplicationGatewaySslCertificate -Name "apim-portal-cert" -CertificateFile $portalCertPfxPath -Password $certPortalPwd

# step 5 - configure HTTP listeners for the App Gateway
$listener = New-AzApplicationGatewayHttpListener -Name "apim-gw-listener" -Protocol "Https" -FrontendIPConfiguration $fipconfig01 -FrontendPort $fp01 -SslCertificate $cert -HostName $gatewayHostname -RequireServerNameIndication true
$portalListener = New-AzApplicationGatewayHttpListener -Name "apim-portal-listener" -Protocol "Https" -FrontendIPConfiguration $fipconfig01 -FrontendPort $fp01 -SslCertificate $certPortal -HostName $portalHostname -RequireServerNameIndication true

# step 6 - create custom probes for API-M endpoints
$apimprobe = New-AzApplicationGatewayProbeConfig -Name "apim-gw-proxyprobe" -Protocol "Https" -HostName $gatewayHostname -Path "/status-0123456789abcdef" -Interval 30 -Timeout 120 -UnhealthyThreshold 8
$apimPortalProbe = New-AzApplicationGatewayProbeConfig -Name "apim-portal-probe" -Protocol "Https" -HostName $portalHostname -Path "/signin" -Interval 60 -Timeout 300 -UnhealthyThreshold 8

# step 7 - upload cert for SSL-enabled backend pool resources
$authcert = New-AzApplicationGatewayAuthenticationCertificate -Name "whitelistcert" -CertificateFile $gatewayCertCerPath

# step 8 - configure HTTPs backend settings for the App Gateway
$apimPoolSetting = New-AzApplicationGatewayBackendHttpSettings -Name "apim-gw-poolsetting" -Port 443 -Protocol "Https" -CookieBasedAffinity "Disabled" -Probe $apimprobe -AuthenticationCertificates $authcert -RequestTimeout 180
$apimPoolPortalSetting = New-AzApplicationGatewayBackendHttpSettings -Name "apim-portal-poolsetting" -Port 443 -Protocol "Https" -CookieBasedAffinity "Disabled" -Probe $apimPortalProbe -AuthenticationCertificates $authcert -RequestTimeout 180

# step 9a - configure back-end IP address pool with internal IP of API-M i.e. 10.0.1.5
$apimProxyBackendPool = New-AzApplicationGatewayBackendAddressPool -Name "apimbackend" -BackendIPAddresses $apimService.PrivateIPAddresses[0]

# step 9b - create sinkpool for API-M requests we want to discard 
$sinkpool = New-AzApplicationGatewayBackendAddressPool -Name "sinkpool"

# step 10 - create a routing rule to allow external Internet access to the developer portal
$rule01 = New-AzApplicationGatewayRequestRoutingRule -Name "apim-portal-rule" -RuleType Basic -HttpListener $portalListener -BackendAddressPool $apimProxyBackendPool -BackendHttpSettings $apimPoolPortalSetting

# step 11 - change App Gateway SKU and instances (# instances can be configured as required)
$sku = New-AzApplicationGatewaySku -Name "WAF_Medium" -Tier "WAF" -Capacity 1

# step 12 - configure WAF to be in prevention mode
$config = New-AzApplicationGatewayWebApplicationFirewallConfiguration -Enabled $true -FirewallMode "Detection" # It could be "Prevention" as well

# Deploy the App Gateway
$appgwName = "your-apim-app-gw"
$appgw = New-AzApplicationGateway -Name $appgwName -ResourceGroupName $resGroupName -Location $location -BackendAddressPools $apimProxyBackendPool, $sinkpool -BackendHttpSettingsCollection $apimPoolSetting, $apimPoolPortalSetting -FrontendIpConfigurations $fipconfig01 -GatewayIpConfigurations $gipconfig -FrontendPorts $fp01 -HttpListeners $listener, $portalListener -RequestRoutingRules $rule01 -Sku $sku -WebApplicationFirewallConfig $config -SslCertificates $cert, $certPortal -AuthenticationCertificates $authcert -Probes $apimprobe, $apimPortalProbe


# ----- Add path based routing rule for /external/* API URL's only ----- #

# Get existing Application Gateway config
$appgw = Get-AzApplicationGateway -ResourceGroupName $resGroupName -Name $appgwName
$listener = Get-AzApplicationGatewayHttpListener -Name "apim-gw-listener" -ApplicationGateway $appgw
$sinkpool = Get-AzApplicationGatewayBackendAddressPool -ApplicationGateway $appgw -Name "sinkpool"
$pool = Get-AzApplicationGatewayBackendAddressPool -ApplicationGateway $appgw -Name "apimbackend"
$poolSettings = Get-AzApplicationGatewayBackendHttpSettings -ApplicationGateway $appgw -Name "apim-gw-poolsetting"

# Add external path rule + map
$pathRule = New-AzApplicationGatewayPathRuleConfig -Name "external" -Paths "/external/*" -BackendAddressPool $pool -BackendHttpSettings $poolSettings
$appgw = Add-AzApplicationGatewayUrlPathMapConfig -ApplicationGateway $appgw -Name "external-urlpathmapconfig" -PathRules $pathRule -DefaultBackendAddressPool $sinkpool -DefaultBackendHttpSettings $poolSettings
$appgw = Set-AzApplicationGateway -ApplicationGateway $appgw

# Add external path-based routing rule
$pathmap = Get-AzApplicationGatewayUrlPathMapConfig -ApplicationGateway $appgw -Name "external-urlpathmapconfig"
$appgw = Add-AzApplicationGatewayRequestRoutingRule -ApplicationGateway $appgw -Name "apim-gw-external-rule01" -RuleType PathBasedRouting -HttpListener $listener -BackendAddressPool $Pool -BackendHttpSettings $poolSettings -UrlPathMap $pathMap
$appgw = Set-AzApplicationGateway -ApplicationGateway $appgw