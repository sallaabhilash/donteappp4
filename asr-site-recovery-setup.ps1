# Azure Site Recovery setup sample for Azure VMs
# Customize the variable values for your subscription, resource groups, and VM names.

param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory=$true)]
    [string]$PrimaryResourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$RecoveryResourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$VaultName,

    [Parameter(Mandatory=$true)]
    [string]$VaultLocation,

    [Parameter(Mandatory=$true)]
    [string]$PrimaryVmName,

    [Parameter(Mandatory=$true)]
    [string]$PrimaryVmResourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$RecoveryVmResourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$RecoveryFabricName
)

Write-Host "Logging in to Azure..." -ForegroundColor Cyan
Connect-AzAccount | Out-Null
Set-AzContext -SubscriptionId $SubscriptionId

Write-Host "Creating recovery services vault..." -ForegroundColor Cyan
$vault = Get-AzRecoveryServicesVault -Name $VaultName -ResourceGroupName $PrimaryResourceGroup -ErrorAction SilentlyContinue
if (-not $vault) {
    $vault = New-AzRecoveryServicesVault -Name $VaultName -ResourceGroupName $PrimaryResourceGroup -Location $VaultLocation
}

Write-Host "Setting vault context..." -ForegroundColor Cyan
Set-AzRecoveryServicesVaultContext -Vault $vault

Write-Host "Creating replication policy..." -ForegroundColor Cyan
$policyName = "ASR-VM-Replication-Policy"
$policy = Get-AzRecoveryServicesAsrPolicy -Name $policyName -ErrorAction SilentlyContinue
if (-not $policy) {
    $policy = New-AzRecoveryServicesAsrPolicy -Name $policyName -ReplicationProviderName "HyperVReplicaAzure" `
        -RecoveryPointHistoryDuration 24 `
        -ApplicationConsistentSnapshotFrequencyInHours 4 `
        -ReplicationIntervalInSeconds 300
}

Write-Host "Enabling replication for VM '$PrimaryVmName'..." -ForegroundColor Cyan
$vm = Get-AzVM -ResourceGroupName $PrimaryVmResourceGroup -Name $PrimaryVmName
if (-not $vm) {
    throw "VM '$PrimaryVmName' not found in resource group '$PrimaryVmResourceGroup'."
}

$vmDisk = $vm.StorageProfile.OsDisk
$vmSource = Get-AzRecoveryServicesAsrAzureToAzureProtectedItem -VaultId $vault.ID -Name $PrimaryVmName -ErrorAction SilentlyContinue
if (-not $vmSource) {
    Enable-AzRecoveryServicesAsrReplication -AzureToAzureInputObject @{ 
        sourceResourceId = $vm.Id; 
        recoveryResourceGroupId = (Get-AzResourceGroup -Name $RecoveryResourceGroup).ResourceId; 
        recoveryVaultResourceId = $vault.Id; 
        policyId = $policy.Id; 
        recoveryFabricName = $RecoveryFabricName; 
    }
}

Write-Host "ASR setup complete. Review the vault and replication items in the Azure Portal." -ForegroundColor Green
