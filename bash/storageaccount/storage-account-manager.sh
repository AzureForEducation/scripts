#!/bin/bash

#############################################################################################
# Functions area                                                                            #                                                        
#############################################################################################

#############################################################################################
# "CreateNewStorageAccount" function.                                                       #
# Parameters expected:                                                                      #
#   - ResourceGroup: the resource group name.                                               #
#   - Location: Azure datacenter where the storage accounts will seat.                      #
#   - StorageAccountName: the storage account name.                                         #
#   - AccessTier: the access tier for that storage.                                         #
#   - Kind: the storage account kind.                                                       #
#   - SKU: storage account SKU.                                                             #
#############################################################################################
function CreateNewStorageAccount()
{
    echo "This module creates a new storage account."
    echo "If you are in the wrong place please type Ctrl + C."
    
    echo ""
    read -p "Resource Group name: " resourcegroup
    read -p "Location: " location
    read -p "Storage Account name: " storageaccountname
    read -p "Access Tier: " accesstier
    read -p "Kind: " kind
    read -p "SKU: " sku

    echo ""
    echo "Do you confirm the data informed? Type 'Y' for 'Yes' or 'N' for 'No'"
    echo "----------------------------------------------------------------------"
    echo "RG:" $resourcegroup
    echo "Location:" $location
    echo "Storage Account name:" $storageaccountname
    echo "Access Tier:" $accesstier
    echo "Kind:" $kind
    echo "SKU:" $sku
    echo ""

    read -p "Confirm? " confirmation

    if [ "$confirmation" = "N" ]
        then
            until [ "$confirmation" = "Y" ]
                do
                    echo ""
                    read -p "Resource Group name: " resourcegroup
                    read -p "Location: " location
                    read -p "Storage Account name: " storageaccountname
                    read -p "Access Tier: " accesstier
                    read -p "Kind: " kind
                    read -p "SKU: " sku

                    echo ""
                    echo "Do you confirm the data informed? Type 'Y' for 'Yes' or 'N' for 'No'"
                    echo "----------------------------------------------------------------------"
                    echo "RG:" $resourcegroup
                    echo "Location:" $location
                    echo "Storage Account name:" $storageaccountname
                    echo "Access Tier:" $accesstier
                    echo "Kind:" $kind
                    echo "SKU:" $sku
                    echo ""

                    read -p "Confirm? " confirmation
                done
        else
            if [ "$confirmation" = "Y" ]
                then
                    echo "New storage account: running requirements..."
                    
                    # Verify if the resource group already exists
                    rgreturned=$(az storage account list --output tsv --query "[?name == '$resourcegroup'].id")
                    
                    # If not, create a new one.
                    if [ -z "$rgreturned" ]
                        then
                            CreateNewResourceGroup $resourcegroup $location
                    fi

                    # Creating the storage account
                    echo "Creating storage account..."
                    az storage account create \
                        --resource-group $resourcegroup \
                        --location $location \
                        --name $storageaccountname \
                        --access-tier $accesstier \
                        --kind $kind \
                        --sku $sku
                    echo "Done."
                    echo ""

                    # Listing existing storage accounts
                    az storage account list --output table

                else
                    # Error
                    echo "Error: Parameter invalid."
                    exit 1
            fi
        fi
}

############################################################################################
# "CreateNewResourceGroup" function.                                                       #
# Parameters expected:                                                                     #
#   - ResourceGroup: the resource group name to be created.                                #
#   - Location: Azure datacenter where the storage accounts will seat.                     #
############################################################################################
function CreateNewResourceGroup()
{
    echo "Resource Group doesn't exists. Creating a new one..."
    az group create \
        -g $1 \
        -l $2
    echo "Done."
}

############################################################################################
# "UpdateStorageAccountProperties" function.                                               #
# Parameters expected:                                                                     #
#   - No parameters expected.                                                              #
############################################################################################
function UpdateStorageAccountProperties()
{
    # Listing existing storage accounts
    echo "Retrieving existing storage accounts..."
    echo ""
    az storage account list --output table
    echo ""

    # Getting storage account name and resource group
    read -p "Storage Account name to be updated: " storageaccounttobeupdated
    read -p "Resource Group where this storage seats: " rgtobeupdated
    echo ""

    # Showing options to update an existing storage account
    echo "Which aspect(s) would you like to update in this storage account?"
    echo ""

    # Properties values
    read -p "Access Tier? Inform the new value: " newaccesstier
    read -p "SKU? Inform the new value: " newsku
    echo ""

    # Posting the confirmation message
    echo "The storage account" $storageaccounttobeupdated "will be updated with the following data."
    echo "------------------------------------------------------------------------------------------"
    echo "Access Tier:" $newaccesstier
    echo "SKU:" $newsku
    echo ""
    
    read -p "Would you like to proceed? 'Y' for 'Yes' and 'N' for 'No': " updateconfirmation

    # Validating the response
    if [ "$updateconfirmation" = "N" ]
        then
            echo "Ok. Canceling the update process..."
            exit 1
        else
            if [ "$updateconfirmation" = "Y" ]
                then
                    if [ -z $storageaccounttobeupdated ]
                        then
                            echo "Storage Account name is null or doesn't exists. Exiting..."
                            exit 1
                        else
                            echo "Updating the storage account..."
                            az storage account update \
                                --name $storageaccounttobeupdated \
                                -g $rgtobeupdated \
                                --access-tier $newaccesstier \
                                --sku $newsku
                            echo "Done."
                            echo ""
                            az storage account list -o table
                    fi
                else
                    echo "Option invalid. Exiting..."
                    exit 1
            fi
    fi 
}

############################################################################################
# "RemoveStorageAccount" function.                                                         #
# Parameters expected:                                                                     #
#   - No parameters expected.                                                              #
############################################################################################
function RemoveStorageAccount()
{
    # Listing existing storage accounts
    echo "Retrieving existing storage accounts..."
    echo ""
    az storage account list --output table
    echo ""

    # Getting storage account name and resource group
    read -p "Storage Account name (to be deleted): " storageaccounttobedeleted
    read -p "Resource Group where this storage seats: " rgtobedeleted
    echo ""

    # Posting the confirmation message
    echo "The storage account" $storageaccounttobedeleted "and its data will be permanentely deleted."
    read -p "Would you like to proceed? 'Y' for 'Yes' and 'N' for 'No': " deleteconfirmation

    # Validating the response
    if [ "$deleteconfirmation" = "N" ]
        then
            echo "Ok. Canceling the deleting process..."
            exit 1
        else
            if [ "$deleteconfirmation" = "Y" ]
                then
                    if [ -z $storageaccounttobedeleted ]
                        then
                            echo "Storage Account name is null or doesn't exists. Exiting..."
                            exit 1
                        else
                            echo "Deleting the storage account..."
                            az storage account delete \
                                --name $storageaccounttobedeleted \
                                -g $rgtobedeleted 
                            echo "Done."
                            echo ""
                            az storage account list -o table
                    fi
                else
                    echo "Option invalid. Exiting..."
                    exit 1
            fi
    fi 
}

############################################################################################
# "Main" function.                                                                         #
############################################################################################
function Main()
{
    #Exhibiting options
    echo ""
    echo "#########################################"
    echo "#     Azure Storage Account Manager     #"
    echo "#########################################"
    echo ""
    echo "Please, select what you would like to by selecting one of the options below:"
    echo "1. Create a new storage account"
    echo "2. Update properties in an existing storage account"
    echo "3. Remove an existing storage account"
    echo ""

    #Reading selected option
    read -p "Please, type 1, 2 or 3 for selection: " option

    #Validating the typed value and calling functions properly
    if [ $option -ge 1 -a $option -le 3 ]
        then
            case $option in
                1)
                    CreateNewStorageAccount;;
                2)
                    UpdateStorageAccountProperties;;
                3)
                    RemoveStorageAccount;;
            esac
        else
            echo "The option informed isn't valid."
            exit 1
    fi
}

############################################################################################
# Main area                                                                                #
############################################################################################
Main