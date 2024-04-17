variable "enable_telemetry" {
  description = "Enable telemetry for the module."
  type        = bool
  default     = false

}
variable "source_location" {
  type        = string
  description = "The source Azure region where the VM is located."
}

variable "target_location" {
  type        = string
  description = "The Azure Region for the target resources."
}



# Vault Configuration
variable "use_existing_vault" {
  type        = bool
  description = "Set to true if using an existing Recovery Services Vault."
  default     = false
}

# Resource Group Configuration
variable "vault_resource_group_name" {
  type        = string
  description = "The name of the resource group where the target vault exists."

}




variable "vault_name" {
  type        = string
  description = "Name of the Recovery Services Vault to be created, if not using an existing one."
  default     = ""
}

variable "capacity_reservation_target_sku" {
  type        = string
  description = "The SKU of the capacity reservation to be created."
  default     = ""

}



variable "target_vnet_name" {
  type        = string
  description = "The name of the target virtual network to be created if not using an existing one."
  default     = ""
}

variable "target_vnet_address_space" {
  type        = list(string)
  description = "The address space of the target virtual network to be created, if required."
  default     = []
}




variable "target_subnet_name" {
  type        = string
  description = "The name of the target subnet to be created if not using an existing one."
  default     = ""
}

variable "target_subnet_address_prefix" {
  type        = string
  description = "The address prefix for the target subnet, if not using an existing one."
  default     = ""
}
variable "replicated_vms" {
  description = "A map of virtual machines to replicate, with their corresponding configuration."
  type = map(object({
    vm_id                                 = string
    target_resource_group_id              = string
    source_network_id                     = string
    target_network_id                     = string
    managed_disks = list(object({
      disk_id                            = string
      disk_type                          = string
      replica_disk_type                  = string
      target_disk_encryption_set_id      = optional(string)
    }))
    network_interfaces = list(object({
      network_interface_id               = string
      target_subnet_name                 = string
      target_static_ip                   = optional(string)
      recovery_public_ip_address_id      = optional(string)
      failover_test_static_ip            = optional(string)
      failover_test_subnet_name          = optional(string)
      failover_test_public_ip_address_id = optional(string)
    }))
    create_capacity_reservation          = optional(bool)
    capacity_reservation_sku             = optional(string)
    capacity_reservation_group_name      = optional(string)
    target_availability_set_id           = optional(string)
    target_zone                         = optional(string)
    target_edge_zone                    = optional(string)
    target_proximity_placement_group_id = optional(string)
    target_boot_diagnostic_storage_account_id = optional(string)
    target_virtual_machine_scale_set_id = optional(string)
    test_network_id                     = optional(string)
    multi_vm_group_name                 = optional(string)
  }))
}
variable "existing_capacity_reservation_group_id" {
  description = "The ID of an existing capacity reservation group to use. Leave empty if creating a new one."
  type        = string
  default     = ""
}

variable "capacity_reservation_group_name" {
  description = "The name for a new capacity reservation group common for all replicated VMs."
  type        = string
  default     = ""
}



# Recovery Policy Configuration
variable "recovery_point_retention_in_minutes" {
  type        = number
  description = "The duration in minutes for which the recovery points need to be stored."
}

variable "application_consistent_snapshot_frequency_in_minutes" {
  type        = number
  description = "The frequency in minutes at which application-consistent snapshots are taken."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources."
  default     = {}
}


variable "replicated_vm_name" {
  description = "Name of the replicated VM"
  default     = "replicated-vm"
}
variable "target_availability_set_id" {
  type        = string
  description = "Id of availability set that the new VM should belong to when a failover is done."
  default     = null
}

variable "target_zone" {
  type        = string
  description = "Specifies the Availability Zone where the Failover VM should exist."
  default     = null
}

variable "target_edge_zone" {
  type        = string
  description = "Specifies the Edge Zone within the Azure Region where this Managed Kubernetes Cluster should exist."
  default     = null
}

variable "target_proximity_placement_group_id" {
  type        = string
  description = "Id of Proximity Placement Group the new VM should belong to when a failover is done."
  default     = null
}

variable "target_boot_diagnostic_storage_account_id" {
  type        = string
  description = "Id of the storage account which the new VM should used for boot diagnostic when a failover is done."
  default     = null
}



variable "target_virtual_machine_scale_set_id" {
  type        = string
  description = "Id of the Virtual Machine Scale Set which the new Vm should belong to when a failover is done."
  default     = null
}



variable "test_network_id" {
  type        = string
  description = "Network to use when a test failover is done."
  default     = null
}

variable "multi_vm_group_name" {
  type        = string
  description = "Name of group in which all machines will replicate together and have shared crash consistent and app-consistent recovery points when failed over."
  default     = null
}



variable "network_interface_target_static_ip" {
  type        = string
  description = "Static IP to assign when a failover is done."
  default     = null
}

variable "network_interface_recovery_public_ip_address_id" {
  type        = string
  description = "Id of the public IP object to use when a failover is done."
  default     = null
}

variable "network_interface_failover_test_static_ip" {
  type        = string
  description = "Static IP to assign when a test failover is done."
  default     = null
}

variable "network_interface_failover_test_subnet_name" {
  type        = string
  description = "Name of the subnet to use when a test failover is done."
  default     = null
}

variable "network_interface_failover_test_public_ip_address_id" {
  type        = string
  description = "Id of the public IP object to use when a test failover is done."
  default     = null
}

variable "enable_capacity_reservation" {
  description = "Defines whether capacity reservation should be created."
  type        = bool
  default     = false
}



variable "staging_replication_type" {
  description = "The replication type for the staging storage account."
  type        = string
  default     = "LRS"
}

variable "target_resource_group_name" {
  description = "The name of the resource group in which the target replicarted resources will be created."
  type        = string
  default     = ""
}

variable "bcdr_subscription" {
  description = "The subscription ID for the bcdr resources."
  type        = string
  default     = ""
}
variable "target_subscription" {
  description = "The subscription ID for the target resources."
  type        = string
  default     = ""
}

variable "environment" {
  description = "The environment for the resources."
  type        = string
  default     = "prod"
}

variable "create_capacity_reservation_group" {
  description = "Defines whether capacity reservation group should be created."
  type        = bool
  default     = false
}
