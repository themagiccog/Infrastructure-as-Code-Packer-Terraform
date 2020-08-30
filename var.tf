variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default = "udacity-project1"
}

variable "location" {
  description = "The location where resources are created"
  default     = "East US"
}

variable "vmimage" {
  description = "This is the name of the image created"
  default     = "udacity-project1-vm-image"
}

variable "vmimagerg" {
  description = "This is the name of the Resource Group that image was created"
  default     = "udacity-project1-image-rg"
}


variable "vmcount" {
  type = number
  description = "What number of VMs do you need?"
  default     = 2
  validation {
    condition     = var.vmcount > 1 && var.vmcount < 5
    error_message = "The VM count should be between 2 and 4 (Default is 2. Max is 4 and Max vCPU for region is 6)."
  }
}

variable "username" {
	description = "Enter Username"
}

variable "password" {
	description = "Enter Password"
}

