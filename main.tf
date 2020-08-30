provider "azurerm" {
  features {}
}

# CREATE RESOURCE
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-rg"
  location = var.location

  tags = {
    udacity = "project1"
  }
}




# CREATE VIRTUAL NETWORK AND SUBNETS

# Virtual Network (VNet)
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    udacity = "project1"
  }
}
# Backend subnet (No front end, except we have Application Gateway)
resource "azurerm_subnet" "main" {
  name                 = "${var.prefix}-vm-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes       = ["10.0.2.0/24"]
}






# CREATE NETWORK SECURITY GROUP
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

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
    udacity = "project1"
  }
}



# CREATE LOAD BALANCER (Including PUBLIC IP and Backend Address Pool)

#Public IP
resource "azurerm_public_ip" "main" {
  name                         = "${var.prefix}-public-ip"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.main.name
  allocation_method            = "Static"
  
  domain_name_label            = azurerm_resource_group.main.name
  
  tags = {
    udacity = "project1"
  }
}
# Load Balancer (LB)
resource "azurerm_lb" "main" {
  name                = "${var.prefix}-lb"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "${var.prefix}-pip"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  tags = {
    udacity = "project1"
  }
}
# Backend Address pool
resource "azurerm_lb_backend_address_pool" "main" {
  name                = "${var.prefix}-BackEndAddressPool"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id  
}



# CREATE AVAILABILITY SET
resource "azurerm_availability_set" "main" {
  name                = "${var.prefix}-avset"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    udacity = "project1"
  }
}

# ###----------PAUSE HERE and CREATE PACKER IMAGE then return-------#####

# ###-------------RETURN-------------------------####

#CREATE NICS and CONNECTION TO LOAD BALANCER BACK END POOL

# Network Interface Card (NIC)
resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "${var.prefix}-nic-ipconfig"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    udacity = "project1"
  }
}
# Address Pool Association from NIC to LB
resource "azurerm_network_interface_backend_address_pool_association" "main" {
  network_interface_id    = azurerm_network_interface.main.id
  ip_configuration_name   = "${var.prefix}-nic-ipconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}


# GET IMAGE FROM PACKER

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
  count = var.vmcount
  name                            = "${var.prefix}-vm${count.index+1}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_D2s_v3"
  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  network_interface_ids = [ azurerm_network_interface.main.id,  ]

  source_image_id =data.azurerm_image.image.id  

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = {
    udacity = "project1"
  }
}


# Managed Disks
resource "azurerm_managed_disk" "main" {
  count = var.vmcount
  name                 = "${var.prefix}-md${count.index+1}"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "100"

  tags = {
    udacity = "project1"
  }
}

# Attach Managed Disk
resource "azurerm_virtual_machine_data_disk_attachment" "main" {
  
  managed_disk_id    = azurerm_managed_disk.main.id
  virtual_machine_id = azurerm_virtual_machine.main.id
  lun                = "10"
  caching            = "ReadWrite"
}






 






