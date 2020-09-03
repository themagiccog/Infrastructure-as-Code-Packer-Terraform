provider "azurerm" {
  features {}
}

# CREATE RESOURCE
#Resource Already Created on the CLI so we call it
data "azurerm_resource_group" "main" {
  name     = "${var.vmimagerg}" 
}




# CREATE VIRTUAL NETWORK AND SUBNETS

# Virtual Network (VNet)
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name

  tags = {
    "${var.tagKey}" ="${var.tagValue}"
  }
}
# Backend subnet
resource "azurerm_subnet" "main" {
  name                 = "${var.prefix}-vm-subnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes       = ["10.0.2.0/24"]
}






# CREATE NETWORK SECURITY GROUP (Deny Access to Internet)
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "IN-Allow-only-VM-in-Subnets"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
  }
  security_rule {
    name                       = "OUT-Allow-only-VM-in-Subnets"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
  }
  

  tags = {
    "${var.tagKey}" ="${var.tagValue}"
  }
}



# CREATE LOAD BALANCER (Including PUBLIC IP (or PRIVATE IP) and Backend Address Pool)

#Public IP (Not needed for this task but will be created)
resource "azurerm_public_ip" "main" {
  name                         = "${var.prefix}-public-ip"
  location                     = var.location
  resource_group_name          = data.azurerm_resource_group.main.name
  allocation_method            = "Static"
  
  domain_name_label            = data.azurerm_resource_group.main.name
  
  tags = {
    "${var.tagKey}" ="${var.tagValue}"
  }
} 
# Load Balancer (LB)
resource "azurerm_lb" "main" {
  name                = "${var.prefix}-lb"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "${var.prefix}-pip"
    # for Public Load Balancer, use the "public_ip_address_id" for the Public IP resource.
    # public_ip_address_id = azurerm_public_ip.main.id

    # for Internal Load Balancer, use "subnet_id" of the subnet resource (configured as backend) on the VNet resource.
    subnet_id = azurerm_subnet.main.id
  }

  tags = {
    "${var.tagKey}" ="${var.tagValue}"
  }
}
# Backend Address pool
resource "azurerm_lb_backend_address_pool" "main" {
  name                = "${var.prefix}-BackEndAddressPool"
  resource_group_name = data.azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id  
}



# CREATE AVAILABILITY SET
resource "azurerm_availability_set" "main" {
  name                = "${var.prefix}-avset"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  tags = {
    "${var.tagKey}" ="${var.tagValue}"
  }
}

#CREATE NICS and CONNECTION TO LOAD BALANCER BACK END POOL

# Network Interface (NIC)
resource "azurerm_network_interface" "main" {
  count               = var.vmcount
  name                = "${var.prefix}-nic${count.index+1}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                          = "${var.prefix}-nic-ipconfig${count.index+1}"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    "${var.tagKey}" ="${var.tagValue}"
  }
}
# Address Pool Association from NIC to LB
resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count                   = var.vmcount
  network_interface_id    = azurerm_network_interface.main[count.index].id
  ip_configuration_name   = "${var.prefix}-nic-ipconfig${count.index+1}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}


# GET IMAGE MADE BY PACKER

# Assign resource group name of image
data "azurerm_resource_group" "image" {
  name = "${var.vmimagerg}"
}
# Get Packer Image 
data "azurerm_image" "image" {
  name                = "${var.vmimage}"
  resource_group_name = data.azurerm_resource_group.image.name
}


# CREATE LINUX VIRTUAL MACHINE (VM)
resource "azurerm_linux_virtual_machine" "main" {
  count                           = var.vmcount
  name                            = "${var.prefix}-vm${count.index+1}"
  resource_group_name             = data.azurerm_resource_group.main.name
  location                        = data.azurerm_resource_group.main.location
  availability_set_id             = azurerm_availability_set.main.id
  size                            = "Standard_D2s_v3"
  admin_username                  = var.username
  admin_password                  = var.password  
  disable_password_authentication = false
  network_interface_ids = [ azurerm_network_interface.main[count.index].id,  ]

  source_image_id =data.azurerm_image.image.id  

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = {
    "${var.tagKey}" ="${var.tagValue}"
  }
}


# Managed Disks
resource "azurerm_managed_disk" "main" {
  count                 = var.vmcount
  name                 = "${var.prefix}-md${count.index+1}"
  location             = data.azurerm_resource_group.main.location
  resource_group_name  = data.azurerm_resource_group.main.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "100"

  tags = {
    "${var.tagKey}" ="${var.tagValue}"
  }
}

# Attach Managed Disk
resource "azurerm_virtual_machine_data_disk_attachment" "main" {
  count               = var.vmcount
  managed_disk_id    = azurerm_managed_disk.main[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.main[count.index].id
  lun                = "10"
  caching            = "ReadWrite"
}






 






