########################################################
#
#                 Local Variables definition
#
#######################################################
locals {
  environment_suffix = var.environment == "prod" ? "prd" : "nprd"
  region_source      = replace(var.source_location, " ", "-")
  region_target      = replace(var.target_location, " ", "-")
}


locals {
  vault_name_template               = "vault-${var.vault_name}-${local.environment_suffix}-${random_string.unique_suffix.result}"
  site_recovery_fabric_name_source  = "srfab-${local.region_source}-${local.environment_suffix}"
  site_recovery_fabric_name_target  = "srfab-${local.region_target}-${local.environment_suffix}"
  protection_container_name_source  = "pc-src-${random_string.unique_suffix.result}"
  protection_container_name_target  = "pc-tgt-${random_string.unique_suffix.result}"
  replication_policy_name           = "rp-${local.environment_suffix}-${random_string.unique_suffix.result}"
  protection_container_mapping_name = "pcm-${local.environment_suffix}-${random_string.unique_suffix.result}"
  capacity_reservation_group_name   = "${var.replicated_vm_name}-crg-${local.environment_suffix}-${random_string.unique_suffix.result}"
  capacity_reservation_name         = "${local.capacity_reservation_group_name}-reservation"
  replicated_vm_name                = "${var.replicated_vm_name}-${local.environment_suffix}-${random_string.unique_suffix.result}"
}
locals {
  network_mapping_names = { for vm_name in keys(var.replicated_vms) : vm_name => "${vm_name}-network-mapping" }
}

########################################################
#
#                 Data sources
#
#######################################################

data "azurerm_subscription" "current" {}

data "azurerm_recovery_services_vault" "existing_vault" {
  count               = var.use_existing_vault ? 1 : 0
  name                = var.vault_name
  resource_group_name = var.vault_resource_group_name
  provider            = azurerm.target
}


resource "random_string" "unique_suffix" {
  length  = 8
  numeric = true
  special = false
  upper   = false
}

########################################################
#
#               Recovery Infrastructure
#
#######################################################

resource "azurerm_recovery_services_vault" "vault" {
  count = var.use_existing_vault ? 0 : 1
  name  = local.vault_name_template

  location            = var.target_location
  resource_group_name = var.target_resource_group_name
  sku                 = "Standard"
  tags                = var.tags
  provider            = azurerm.target
}

resource "azurerm_site_recovery_fabric" "source" {
  name                = local.site_recovery_fabric_name_source
  resource_group_name = var.target_resource_group_name
  recovery_vault_name = var.use_existing_vault ? data.azurerm_recovery_services_vault.existing_vault[0].name : azurerm_recovery_services_vault.vault[0].name
  location            = var.source_location
  provider            = azurerm.target


}

resource "azurerm_site_recovery_fabric" "target" {
  name                = local.site_recovery_fabric_name_target
  resource_group_name = var.target_resource_group_name
  recovery_vault_name = var.use_existing_vault ? data.azurerm_recovery_services_vault.existing_vault[0].name : azurerm_recovery_services_vault.vault[0].name
  location            = var.target_location
  provider            = azurerm.target


}

resource "azurerm_site_recovery_protection_container" "source" {
  name                 = local.protection_container_name_source
  resource_group_name  = var.target_resource_group_name
  recovery_vault_name  = var.use_existing_vault ? data.azurerm_recovery_services_vault.existing_vault[0].name : azurerm_recovery_services_vault.vault[0].name
  recovery_fabric_name = azurerm_site_recovery_fabric.source.name
  provider             = azurerm.target

}

resource "azurerm_site_recovery_protection_container" "target" {
  name                 = local.protection_container_name_target
  resource_group_name  = var.target_resource_group_name
  recovery_vault_name  = var.use_existing_vault ? data.azurerm_recovery_services_vault.existing_vault[0].name : azurerm_recovery_services_vault.vault[0].name
  recovery_fabric_name = azurerm_site_recovery_fabric.target.name
  provider             = azurerm.target


}
resource "azurerm_site_recovery_replication_policy" "policy" {
  name                                                 = local.replication_policy_name
  resource_group_name                                  = var.target_resource_group_name
  recovery_vault_name                                  = var.use_existing_vault ? data.azurerm_recovery_services_vault.existing_vault[0].name : azurerm_recovery_services_vault.vault[0].name
  recovery_point_retention_in_minutes                  = var.recovery_point_retention_in_minutes
  application_consistent_snapshot_frequency_in_minutes = var.application_consistent_snapshot_frequency_in_minutes
  provider                                             = azurerm.target

}

resource "azurerm_site_recovery_protection_container_mapping" "mapping" {
  name                                      = local.protection_container_mapping_name
  resource_group_name                       = var.target_resource_group_name
  recovery_vault_name                       = var.use_existing_vault ? data.azurerm_recovery_services_vault.existing_vault[0].name : azurerm_recovery_services_vault.vault[0].name
  recovery_fabric_name                      = azurerm_site_recovery_fabric.source.name
  recovery_source_protection_container_name = azurerm_site_recovery_protection_container.source.name
  recovery_target_protection_container_id   = azurerm_site_recovery_protection_container.target.id
  recovery_replication_policy_id            = azurerm_site_recovery_replication_policy.policy.id
  provider                                  = azurerm.target

}

resource "random_string" "storage_account_name" {
  length  = 16
  special = false
  upper   = false
  numeric = true
  lower   = true
}

resource "azurerm_storage_account" "staging" {
  name                     = "sa${random_string.storage_account_name.result}${local.environment_suffix}"
  resource_group_name      = var.target_resource_group_name
  location                 = var.source_location
  account_tier             = "Standard"
  account_replication_type = var.staging_replication_type
  provider                 = azurerm.target
}

resource "azurerm_site_recovery_network_mapping" "network_mapping" {
  # Only create network mapping if the source and target locations are different
  count = var.source_location != var.target_location ? length(local.network_mapping_names) : 0

  name                        = local.network_mapping_names[count.index]
  resource_group_name         = azurerm_recovery_services_vault.vault[0].resource_group_name
  recovery_vault_name         = azurerm_recovery_services_vault.vault[0].name
  source_recovery_fabric_name = azurerm_site_recovery_fabric.source.name
  target_recovery_fabric_name = azurerm_site_recovery_fabric.target.name
  source_network_id           = var.replicated_vms[local.network_mapping_names[count.index]].source_network_id
  target_network_id           = var.replicated_vms[local.network_mapping_names[count.index]].target_network_id
  provider                    = azurerm.target
}

########################################################
#
#                Capacity Reservation
#
#######################################################

resource "azurerm_capacity_reservation_group" "shared_cr_group" {
  count = var.create_capacity_reservation_group == true ? 1 : 0

  name                = local.capacity_reservation_group_name
  location            = var.target_location
  resource_group_name = var.target_resource_group_name
  provider            = azurerm.target
  tags                = var.tags
}


resource "azurerm_capacity_reservation" "per_vm" {
  for_each                      = { for vm in var.replicated_vms : vm.key => vm.vm_id if vm.create_capacity_reservation == true }
  name                          = "${each.key}-capacity-reservation-${local.environment_suffix}-${random_string.unique_suffix.result}"
  capacity_reservation_group_id = var.existing_capacity_reservation_group_id != "" ? var.existing_capacity_reservation_group_id : azurerm_capacity_reservation_group.shared_cr_group[0].id

  sku {
    name     = each.value.capacity_reservation_sku
    capacity = 1
  }

  tags     = var.tags
  provider = azurerm.target
}

########################################################
#
#                Replicated VM
#
#######################################################


resource "azurerm_site_recovery_replicated_vm" "replicated_vm" {
  for_each = var.replicated_vms


  name                                         = "${each.key}-${local.environment_suffix}-${random_string.unique_suffix.result}"
  resource_group_name                          = azurerm_recovery_services_vault.vault[0].resource_group_name
  recovery_vault_name                          = var.use_existing_vault ? data.azurerm_recovery_services_vault.existing_vault[0].name : azurerm_recovery_services_vault.vault[0].name
  source_recovery_fabric_name                  = azurerm_site_recovery_fabric.source.name
  source_vm_id                                 = each.value.vm_id
  recovery_replication_policy_id               = azurerm_site_recovery_replication_policy.policy.id
  target_resource_group_id                     = each.value.target_resource_group_id
  target_recovery_fabric_id                    = azurerm_site_recovery_fabric.target.id
  target_recovery_protection_container_id      = azurerm_site_recovery_protection_container.target.id
  source_recovery_protection_container_name    = azurerm_site_recovery_protection_container.source.name
  target_capacity_reservation_group_id         = each.value.create_capacity_reservation == true ? azurerm_capacity_reservation.per_vm[each.key].capacity_reservation_group_id : null
  target_availability_set_id                   = each.value.target_availability_set_id
  target_zone                                  = each.value.target_zone
  target_edge_zone                             = each.value.target_edge_zone
  target_network_id                            = each.value.target_network_id
  target_proximity_placement_group_id          = each.value.target_proximity_placement_group_id
  target_boot_diagnostic_storage_account_id    = each.value.target_boot_diagnostic_storage_account_id
  target_virtual_machine_scale_set_id          = each.value.target_virtual_machine_scale_set_id
  test_network_id                              = each.value.test_network_id
  multi_vm_group_name                          = each.value.multi_vm_group_name

  dynamic "managed_disk" {
    for_each = { for disk in each.value.managed_disks : disk.disk_id => disk }

    content {
      disk_id                           = managed_disk.value.disk_id
      staging_storage_account_id        = azurerm_storage_account.staging.id
      target_resource_group_id          = each.value.target_resource_group_id
      target_disk_type                  = managed_disk.value.disk_type
      target_replica_disk_type          = managed_disk.value.replica_disk_type
      target_disk_encryption_set_id     = managed_disk.value.target_disk_encryption_set_id
    }
  }

  dynamic "network_interface" {
    for_each = { for nic in each.value.network_interfaces : nic.network_interface_id => nic }

    content {
      source_network_interface_id     = network_interface.value.network_interface_id
      target_subnet_name              = network_interface.value.target_subnet_name
      target_static_ip                = network_interface.value.target_static_ip
      recovery_public_ip_address_id   = network_interface.value.recovery_public_ip_address_id
      failover_test_static_ip         = network_interface.value.failover_test_static_ip
      failover_test_subnet_name       = network_interface.value.failover_test_subnet_name
      failover_test_public_ip_address_id = network_interface.value.failover_test_public_ip_address_id
    }
  }

  provider = azurerm.target

 depends_on = [azurerm_site_recovery_network_mapping.network_mapping]

  timeouts {
    create = "5h30m"
    update = "2h"
    delete = "20m"
  }
}



