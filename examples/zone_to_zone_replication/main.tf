# source (Source) Resources

resource "azurerm_resource_group" "source" {
  name     = "source-resource-group-2"
  location = var.source_location
}


resource "azurerm_virtual_network" "source_vnet" {
  name                = "source-vnet"
  location            = var.source_location
  resource_group_name = azurerm_resource_group.source.name
  address_space       = ["10.0.0.0/16"]

  subnet {
    name           = "source-subnet"
    address_prefix = "10.0.1.0/24"
  }
}

resource "azurerm_network_security_group" "source_nsg" {
  name                = "source-nsg"
  location            = var.source_location
  resource_group_name = azurerm_resource_group.source.name
}

resource "azurerm_network_interface" "source_nic" {
  name                = "source-nic"
  location            = var.source_location
  resource_group_name = azurerm_resource_group.source.name

  ip_configuration {
    name                          = "source-ip-configuration"
    subnet_id                     = azurerm_virtual_network.source_vnet.subnet.*.id[0]
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "source_vm" {
  name                  = "source-vm"
  computer_name         = "hostname-source"
  resource_group_name   = azurerm_resource_group.source.name
  location              = var.source_location
  size                  = "Standard_DS1_v2"
  admin_username        = "adminuser"
  admin_password        = "P@ssw0rd1234!"
  network_interface_ids = [azurerm_network_interface.source_nic.id]

  zone =1
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  disable_password_authentication = false
}

resource "azurerm_managed_disk" "source_managed_disk" {
  name                 = "source-managed-disk"
  location             = var.source_location
  resource_group_name  = azurerm_resource_group.source.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10
  zone = 1
}

resource "azurerm_virtual_machine_data_disk_attachment" "source_data_disk" {
  managed_disk_id    = azurerm_managed_disk.source_managed_disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.source_vm.id
  lun                = 0
  caching            = "ReadWrite"
}
# target (Target) Resources


resource "azurerm_resource_group" "target" {
  name     = "target-resource-group-2"
  location = var.target_location
  provider = azurerm.target
}

resource "azurerm_virtual_network" "target_vnet" {
  name                = "target-vnet"
  location            = var.target_location
  resource_group_name = azurerm_resource_group.target.name
  address_space       = ["10.1.0.0/16"]

  subnet {
    name           = "target-subnet"
    address_prefix = "10.1.1.0/24"
    security_group = azurerm_network_security_group.target_nsg.id
  }
  provider = azurerm.target
}

resource "azurerm_network_security_group" "target_nsg" {
  name                = "target-nsg"
  location            = var.target_location
  resource_group_name = azurerm_resource_group.target.name
  provider            = azurerm.target
}



# Workaround to generate Os Disk to prevent resource recreation
data "azurerm_subscription" "current" {}
locals {
  subscription_id     = data.azurerm_subscription.current.subscription_id
  resource_group_name = azurerm_linux_virtual_machine.source_vm.resource_group_name
  os_disk_name        = azurerm_linux_virtual_machine.source_vm.os_disk[0].name
}

# Module for Replicating Virtual Machine between regions

module "avm_bcdr_replication" {
  source = "../../."

  # Name of the resource group where the vault that should be updated is located.
  target_resource_group_name = azurerm_resource_group.target.name

  # Regions
  source_location = var.source_location
  target_location = var.target_location

  # Deploy a new Recovery Services Vault
  use_existing_vault        = false # This example assumes we're creating a new vault for the example, the vault should exist in the target resource group if true
  vault_name                = "avm-recovery-vault"
  vault_resource_group_name = azurerm_resource_group.target.name


  # Recovery Policy Configuration
  recovery_point_retention_in_minutes                  = 24 * 60
  application_consistent_snapshot_frequency_in_minutes = 4 * 60

  # Source Virtual Machine (source)

  replicated_vms = {

    "vm01" = {

      vm_id                    = azurerm_linux_virtual_machine.source_vm.id
      target_resource_group_id = azurerm_resource_group.target.id # Id of resource group where the VM should be created when a failover is done.
      source_network_id        = azurerm_virtual_network.source_vnet.id
      target_network_id        = azurerm_virtual_network.target_vnet.id
      target_zone= 2

      managed_disks = [
        {
          disk_id           = "/subscriptions/${local.subscription_id}/resourceGroups/${local.resource_group_name}/providers/Microsoft.Compute/disks/${local.os_disk_name}"
          disk_type         = "StandardSSD_LRS"
          replica_disk_type = "StandardSSD_LRS"
        },
        {
          disk_id           = azurerm_managed_disk.source_managed_disk.id
          disk_type         = "Standard_LRS"
          replica_disk_type = "Standard_LRS"
        }
      ]

      network_interfaces = [
        {
          network_interface_id = azurerm_network_interface.source_nic.id
          target_subnet_name   = azurerm_virtual_network.target_vnet.subnet.*.name[0]
          target_static_ip     = null # Replace with the desired static IP or keep null for dynamic allocation
        }
      ]
    }
  }
  # Tagging
  tags = {
    "Environment" = "Test"
  }

  providers = {
    azurerm.target = azurerm.target
  }

  depends_on = [azurerm_managed_disk.source_managed_disk, azurerm_resource_group.target]
}
