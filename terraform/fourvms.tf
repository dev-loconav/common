terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}
provider "azurerm" {
  features {}
    
  subscription_id   = "f110dbef-9b94-43e9-a919-008c2f159717"
  tenant_id         = "73e31ee9-3416-4eff-a80b-31fdf2dc2d7b"
  client_id         = "9f3e653d-3f0f-4797-86c1-4755427a6796"
  client_secret     = "R85SN~HrO_C9drM_1Pu9YjtCBGo3sEoVZm"
}

# Create a resource group if it doesn't exist
#resource "azurerm_resource_group" "myterraformgroup" {
#    name     = "locotest"
#    location = "eastus"
#
#    tags = {
#        environment = "test1"
#    }
#}

# Create virtual network
#resource "azurerm_virtual_network" "myterraformnetwork" {
#    name                = "locoVnet"
#    address_space       = ["10.1.0.0/16"]
#    location            = "eastus"
#    resource_group_name = "loconav-test"
#
#    tags = {
#        environment = "test1"
##    }
#}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "locoSubnet"
    resource_group_name  = "loconav-test"
    virtual_network_name = "loconav-test-vnet"
    address_prefixes       = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "vm21PublicIP"
    location                     = "eastus"
    resource_group_name          = "loconav-test"
    allocation_method            = "Dynamic"

    tags = {
        environment = "test1"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "locoSecurityGroup"
    location            = "eastus"
    resource_group_name = "loconav-test"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "test1"
    }
}


# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "loconav-test"
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "loconav-test"
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "test1"
    }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic21" {
    name                      = "vm21NIC"
    location                  = "eastus"
    resource_group_name       = "loconav-test"

    ip_configuration {
        name                          = "vm21NicConfiguration"
        subnet_id                     = azurerm_subnet.myterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
    }

    tags = {
        environment = "test1"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example21" {
    network_interface_id      = azurerm_network_interface.myterraformnic21.id
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}



# Create virtual machine
resource "azurerm_linux_virtual_machine" "terraformvm21" {
    name                  = "vm21"
    location              = "eastus"
    resource_group_name   = "loconav-test"
    network_interface_ids = [azurerm_network_interface.myterraformnic21.id]
    size                  = "Standard_D2s_v3"

    os_disk {
        name              = "vm21OsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "vm21"
    admin_username = "azuser"
    disable_password_authentication = false
    admin_password = "1234qwer!@#$"

   
    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "test1"
    }
}
resource "azurerm_managed_disk" "vm21disk" {
  name                 = "vm2-disk1"
  location             = "eastus"
  resource_group_name  = "loconav-test"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32
}

resource "azurerm_virtual_machine_data_disk_attachment" "example21" {
  managed_disk_id    = azurerm_managed_disk.vm21disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.terraformvm21.id
  lun                = "1"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_extension" "test21" {
  name                 = "hostname21"
  virtual_machine_id   = azurerm_linux_virtual_machine.terraformvm21.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "apt-get update; apt-get install perl;useradd -m -p $(perl -e 'print crypt($ARGV[0], \"password\")' 'deployer') \"deployer\"; echo \"deployer ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers.d/90-cloud-init-users; apt-get install sshpass"
    }
SETTINGS
}

#####VM22###
# Create network interface
resource "azurerm_network_interface" "myterraformnic22" {
    name                      = "vm22NIC"
    location                  = "eastus"
    resource_group_name       = "loconav-test"

    ip_configuration {
        name                          = "vm22NicConfiguration"
        subnet_id                     = azurerm_subnet.myterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
    }

    tags = {
        environment = "test1"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example22" {
    network_interface_id      = azurerm_network_interface.myterraformnic22.id
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}



# Create virtual machine
resource "azurerm_linux_virtual_machine" "terraformvm22" {
    name                  = "vm22"
    location              = "eastus"
    resource_group_name   = "loconav-test"
    network_interface_ids = [azurerm_network_interface.myterraformnic22.id]
    size                  = "Standard_D2s_v3"

    os_disk {
        name              = "vm22OsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "vm22"
    admin_username = "azuser"
    disable_password_authentication = false
    admin_password = "1234qwer!@#$"

    
    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "test1"
    }
}
resource "azurerm_managed_disk" "vm22disk" {
  name                 = "vm22-disk1"
  location             = "eastus"
  resource_group_name  = "loconav-test"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32
}

resource "azurerm_virtual_machine_data_disk_attachment" "example22" {
  managed_disk_id    = azurerm_managed_disk.vm22disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.terraformvm22.id
  lun                = "1"
  caching            = "ReadWrite"
}


resource "azurerm_virtual_machine_extension" "test22" {
  name                 = "hostname22"
  virtual_machine_id   = azurerm_linux_virtual_machine.terraformvm22.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "apt-get update; apt-get install perl;useradd -m -p $(perl -e 'print crypt($ARGV[0], \"password\")' 'deployer') \"deployer\"; echo \"deployer ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers.d/90-cloud-init-users; apt-get install sshpass"
    }
SETTINGS
}

#####VM23###
# Create network interface
resource "azurerm_network_interface" "myterraformnic23" {
    name                      = "vm23NIC"
    location                  = "eastus"
    resource_group_name       = "loconav-test"

    ip_configuration {
        name                          = "vm23NicConfiguration"
        subnet_id                     = azurerm_subnet.myterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
    }

    tags = {
        environment = "test1"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example23" {
    network_interface_id      = azurerm_network_interface.myterraformnic23.id
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}



# Create virtual machine
resource "azurerm_linux_virtual_machine" "terraformvm23" {
    name                  = "vm23"
    location              = "eastus"
    resource_group_name   = "loconav-test"
    network_interface_ids = [azurerm_network_interface.myterraformnic23.id]
    size                  = "Standard_D2s_v3"

    os_disk {
        name              = "vm23OsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "vm23"
    admin_username = "azuser"
    disable_password_authentication = false
    admin_password = "1234qwer!@#$"

    
    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "test1"
    }
}
resource "azurerm_managed_disk" "vm23disk" {
  name                 = "vm23-disk1"
  location             = "eastus"
  resource_group_name  = "loconav-test"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32
}

resource "azurerm_virtual_machine_data_disk_attachment" "example23" {
  managed_disk_id    = azurerm_managed_disk.vm23disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.terraformvm23.id
  lun                = "1"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_extension" "test23" {
  name                 = "hostname23"
  virtual_machine_id   = azurerm_linux_virtual_machine.terraformvm23.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "apt-get update; apt-get install perl;useradd -m -p $(perl -e 'print crypt($ARGV[0], \"password\")' 'deployer') \"deployer\"; echo \"deployer ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers.d/90-cloud-init-users; apt-get install sshpass"
    }
SETTINGS
}

#####VM24###
# Create network interface
resource "azurerm_network_interface" "myterraformnic24" {
    name                      = "vm24NIC"
    location                  = "eastus"
    resource_group_name       = "loconav-test"

    ip_configuration {
        name                          = "vm24NicConfiguration"
        subnet_id                     = azurerm_subnet.myterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
    }

    tags = {
        environment = "test1"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example24" {
    network_interface_id      = azurerm_network_interface.myterraformnic24.id
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}



# Create virtual machine
resource "azurerm_linux_virtual_machine" "terraformvm24" {
    name                  = "vm24"
    location              = "eastus"
    resource_group_name   = "loconav-test"
    network_interface_ids = [azurerm_network_interface.myterraformnic24.id]
    size                  = "Standard_D2s_v3"

    os_disk {
        name              = "vm24OsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "vm24"
    admin_username = "azuser"
    disable_password_authentication = false
    admin_password = "1244qwer!@#$"

    
    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "test1"
    }
}
resource "azurerm_managed_disk" "vm24disk" {
  name                 = "vm24-disk1"
  location             = "eastus"
  resource_group_name  = "loconav-test"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32
}

resource "azurerm_virtual_machine_data_disk_attachment" "example24" {
  managed_disk_id    = azurerm_managed_disk.vm24disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.terraformvm24.id
  lun                = "1"
  caching            = "ReadWrite"
}


resource "azurerm_virtual_machine_extension" "test24" {
  name                 = "hostname24"
  virtual_machine_id   = azurerm_linux_virtual_machine.terraformvm24.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "apt-get update; apt-get install perl;useradd -m -p $(perl -e 'print crypt($ARGV[0], \"password\")' 'deployer') \"deployer\"; echo \"deployer ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers.d/90-cloud-init-users; apt-get install sshpass"
    }
SETTINGS
}