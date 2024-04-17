########################################################
#
#                 Outputs
#
########################################################

output "environment_suffix" {
  description = "The suffix for the environment based on the 'prod' or non-prod status."
  value       = local.environment_suffix
}

output "region_source" {
  description = "The source Azure region with spaces replaced by hyphens."
  value       = local.region_source
}

output "region_target" {
  description = "The target Azure region with spaces replaced by hyphens."
  value       = local.region_target
}

output "vault_name" {
  description = "The name of the recovery services vault."
  value       = var.use_existing_vault ? var.vault_name : local.vault_name_template
}

output "site_recovery_fabric_name_source" {
  description = "The name of the source site recovery fabric."
  value       = local.site_recovery_fabric_name_source
}

output "site_recovery_fabric_name_target" {
  description = "The name of the target site recovery fabric."
  value       = local.site_recovery_fabric_name_target
}

output "protection_container_name_source" {
  description = "The name of the source protection container."
  value       = local.protection_container_name_source
}

output "protection_container_name_target" {
  description = "The name of the target protection container."
  value       = local.protection_container_name_target
}

output "replication_policy_name" {
  description = "The name of the replication policy."
  value       = local.replication_policy_name
}

output "protection_container_mapping_name" {
  description = "The name of the protection container mapping."
  value       = local.protection_container_mapping_name
}

output "network_mapping_names" {
  description = "A map containing VM names and their associated network mapping names."
  value       = local.network_mapping_names
}

output "capacity_reservation_group_name" {
  description = "The name of the capacity reservation group."
  value       = local.capacity_reservation_group_name
}

output "shared_capacity_reservation_group_id" {
  description = "The ID of the shared capacity reservation group, if created."
  value       = var.create_capacity_reservation_group ? azurerm_capacity_reservation_group.shared_cr_group[0].id : ""
  sensitive   = false
}

output "replicated_vm_names" {
  description = "A map containing VM names and their associated replicated VM names."
  value = { for vm_name, vm in var.replicated_vms : vm_name => "${vm_name}-${local.environment_suffix}-${random_string.unique_suffix.result}" }
}

output "storage_account_name" {
  description = "The name of the staging storage account for replication."
  value       = azurerm_storage_account.staging.name
}

output "replicated_vms_info" {
  description = "Information about the replicated VMs."
  value = [for vm_name in keys(var.replicated_vms) : {
    vm_name                       = vm_name
    replicated_vm_id              = azurerm_site_recovery_replicated_vm.replicated_vm[vm_name].id
    target_capacity_reservation_group_id = azurerm_site_recovery_replicated_vm.replicated_vm[vm_name].target_capacity_reservation_group_id
  }]
}

output "individual_capacity_reservation_ids" {
  description = "The IDs of individual capacity reservations if they are created per VM."
  value = {
    for vm_name, vm in var.replicated_vms :
    vm_name => (vm.create_capacity_reservation == true && can(azurerm_capacity_reservation.per_vm[vm_name]))
      ? azurerm_capacity_reservation.per_vm[vm_name].id
      : ""
  }
  sensitive = false
}
