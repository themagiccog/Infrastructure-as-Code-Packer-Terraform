variable "vmcount" {
  type = number
  description = "Number of VM to create??"
  
  validation {
    condition     = var.vmcount > 1 && var.vmcount < 6
    error_message = "The VM count should be between 2 and 5 (Default is 2. Max is 5)."
  }
}

variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  
}

variable "location" {
  description = "The location where resources are created"
  
}

variable "tagKey" {
	description = "Resource Tag Key"
  
}

variable "tagValue" {
	description = "Resource Tag Value"
  
}

variable "vmimage" {
  description = "This is the name of the image created"
  
}

variable "vmimagerg" {
  description = "This is the name of the Resource Group that image was created"
  
}

variable "username" {
	description = "Enter Username"
}

variable "password" {
	description = "Enter Password"
}

