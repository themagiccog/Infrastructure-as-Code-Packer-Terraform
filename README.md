# Infrastructure-as-Code (using Azure)

### Creating a Web-server by deploying a VM with Terraform with image from Packer

## Overview

The aim of this project is to use the DevOps tool, Infrastructure-as-Code to deploy a Web Server as a Virtual Machine. We will use the Provisioning tool, Terraform, to provision the Virtual Machine (VM). The server template tool, Packer, will be used to develop a server template that will be used by Terraform. To provision the VM, the infrastructure should have the necessary resources in place in other for the VM to run. Some of the client's major requirements are as shown below:
Scalability: The VMs should be in an Availability Set (with a minimum and default of 2 VMs running with the capacity to increase the VM count to 5).
Security: The Virtual Network should be in such a way where the VMs in the Network should not be accessible by the Internet but should be accessible within the VMs in the subnet.
Efficiency: The Virtual Network should have a Load Balancer to distribute the work load to the VMs available in the Network.
Disks: The client has also requested that there are Managed Disks attached for each VM deployed.

At the end of this project we should have a TerraForm and Packer template that can be used to deploy VMs of the same requirements as need.
![##### *Azure Web Server Architecture (Deny Access from Internet)*Azure WebServer Deny Internet to VMs](https://engrcog.com/wp-content/uploads/2020/09/Automate-WebServerno-bastion.jpeg)


## Packer 
What is Packer? Parker is one of the DevOps tools used to generate Server Templates for automated Deployment. These server templates can also be configured to include the application and software as required by the project. Packer tools are scripted with JSON. The Packer template is made up of 3 key key attributes: The Variable attribute, the Builders attribute and the Provisioners Attribute. The Variable attributes is used to hold variables that can be used in the building of the server template. These variables can also bind to variables stored in the shell environment. The Builder attribute is used to identify the properties of the Server to be built, including the type of image (Windows or Linux), size of CPU, etc. The last attribute we are going to talk about is the Provisioner Attribute. This attribute is used to deploy applications after the Image has being built. Here, you can give instructions to run an application, Install a Web Server, etc. For this project we will just be creating a little html file with the output "Hello, World".

#### Packer Installation and Setup
Please visit: [https://learn.hashicorp.com/tutorials/packer/getting-started-install](https://learn.hashicorp.com/tutorials/packer/getting-started-install) to view the Packer Installation and Setup up process for your machine.

## TerraForm
Terraform is a DevOps Provisioning tool that can be used to automate the creation of Resources needed for a Cloud environment. TerraForm tools are written with a propitiatory language called HCL. HCL is a script language similar to JSON. The HCL script is usually contains attributes that tell the script what to do. The 3 major attributes are Provider, Resource and Data. The Provider Attribute is used to identify the type of Cloud environment being utilized, in this case it is Azure. The Resource Attributes are used as a template to generate resources in the Cloud environment for example, Virtual Networks and Managed Disks.

#### TerraForm Installation and Setup
Please visit: [https://learn.hashicorp.com/tutorials/terraform/install-cli](https://learn.hashicorp.com/tutorials/terraform/install-cli) to view the Packer Installation and Setup up process for your machine.



## Identifying Resources
BEfore we begin, we will take a look at all the resources that is required to meet the client specifications. When creating a VM in a cloud enviroment, the following resources are typically created along side it. The first this we need is to create a **Resource Group**. A resource group will contain all the resources necessary to deploy these VMs.
A Virtual Machine needs to be in a Network to be effective, so a **Virtual Network (VNet)** is required when a VM is spurn (a way of saying created). To be in a Network, the VM must have **Network Interface Cards (NIC)** so this resource is created. The VMs will need to be segregated within a Network to restrict access to those who don't need to be on it. It is recommended that Virtual Networks have subnets so that the Network can be managed better. This is the reason why we will need a **Subnet** resource. Chances are that we want to be able to access our VMs from the Internet at some point in time, this means our network will require a **Public IP address**. We will also need a **Network Security Gateway** resouce that will house polices on communication rules within the Network. The client also specified a need for a **Load Balancer** so we will need that resource and finally, we will need a *Managed Disk** to be attached to the VM. This Managed Disk is different from the OS disk that is created by default alongside the VM.
A recap of the resources we need to create a VM so far:
Resource Group
Virtual Machine
Virtual Network (the Subnet resource is included in VNet resource)
Public IP Address
Network Security Gateway
Network Interface Card

## Resource Tagging Policy
One of the requirements from the client was to ensure that any resources created was tagged appropriately. So we need to Create a policy definition for this purpose and assign the policy to our scope of work - which for this project will be applied to the subscription.

## Security Policy
By Default, when a network resource is created, there is always an NSG (Network Security Group) deployed with it. The NSG contains a group of rules or policies telling the network how to send or receive information. By deafault, it has some set of rules that restrict communication with the internet on all ports. Only the ports specified in the resource creation stage is allowed. In addition to this policy, the client has requested that she doesn't want any communications from the internet in the network, only communication between the VMs in the network.



## Azure CLI /Bash/ PowerShell

Install the latest version of Powershell 7, and run it. Ensure you have installed the latest CLI module to start with as we will be using the this for this task. 
_**Note:** You can also utilize Bash and the codes are similar._

First, we log on to Azure. Enter the following on PowerShell/Bash:

```PowerShell
> az login
```
You will be sent to a web-page where you can sign into your Azure account.
The next step will be to check for the subscription id for your account.:
```PowerShell
> az account show --query "{ subscription_name: name, subscription_id: id }" -o table
 ```
 This displays your Subscription id as shown:
 >*output similar to:*
 ```PowerShell
Subscription_name    Subscription_id
-------------------  ------------------------------------
MySubscription     xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```
Copy the subscription id, you will need it soon.

***Note:*** _If you have multiple subscriptions, you can list the accounts you have and select the subscription you are interested._
```PowerShell
> az account list --query "[].{subscription_name: name, subscription_id: id}" -o table
```
>*output similar to:*
```PowerShell
Subscription_name         	Subscription_id
------------------------  	------------------------------------
Subscription_1  			xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Subscription_2          	yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy
```


***Note:*** _If you need to clear the Azure Subscription from the CLI, you can run the code below. You will have to log into Azure again and your current subscription will be the whatever was set as default._
```PowerShell
> az account clear
```
***Note:*** _You can also logout using the following command. This retains the subscription that was set in CLI_
```PowerShell
> az logout
```

## Policy
Now that we have logged into our Azure Account using the CLI, we will create a policy on the account.
The Policy should be in place to ensure that when resources are created, they have a tag name. We use JSON to create a policy template which will be used to define our policy.
We want to store the name of our policy definition in the CLI Environment. This way we can just make reference to it as we go along. 
_**Note:** It is good practice to do this, we need to avoid repetitions as often as possible. We will keep track of all the environment variables as we proceed with this task._
In the CLI, we will save our Subscription ID (as you had copied above) and Policy definition name, using the variable names ```subs_id``` and ```policy_def``` respectively, in the Environment with the following code:
```
> $subs_id='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
> $policy_def='DenyIfNoTagsPolicy'
```
#### Define Policy
Now, let use develop a template for the policy we will be defining in our Azure Subscription. The main goal of the policy is to ensure that resources always have a tag name. We create a JSON file, ```rules.json``` which will contain the Policy rules as follows:
```JSON
{
	"if": 	{
			"field": "[concat('tags[', parameters('tagName'), ']')]",
			"exists": "false"
			},
	"then": {
			"effect": "deny"
			}			
}
```
This JSON file defines the Policy rule. The policy simple checks if the Resource has a tag that does not exists (i.e. Exists = false) and if this is the case, it denies creation of the Resource. 

The problem, at least for me, with this is that it was too intrusive and required that I tagged all my resource in my subscription, even test resources. I decided to modify the policy to check if the resource was in a resource group named in a certain format, and if it was then check if the tag key exists.  In this case, we are checking to see if the resource group starts with the words "myproject" and if it does then check if the tag key exists. This was, this policy will only be restricted to Resource Groups with names starting with "myproject".

_Alternative:_
```JSON
{
"if": {
	"allof": [
				{
				"value": "[resourceGroup().name]",
				"like": "myproject*"
				},
				{
				"field": "[concat('tags[', parameters('tagName'), ']')]",
				"exists": "false"
				}
			]
		},
"then": {
		"effect": "deny"
		}			
}
```

_**Note:** For more information on Tagging logic in Azure, please visit:_ [https://docs.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure).

Now we need to define the tag parameter for the rules. We will save this parameter in a JSON file called ```rulesparams.json``` and we will populate as follows:
```JSON
{
"tagName": {
			"type": "String",
			"metadata": {
						"displayName": "Tag Name",
						"description": "Name of the tag, such as 'test'"
						}
			}
}
```
_**Note:** that during assignment of this policy, we will need to specify the ```tagName``` we want to use for this policy._


Now that we have structured the Policy on JSON, its time to create the definition on Azure. Run the following code, which creates the Policy Definition from the JSON file.:
```PowerShell
\policy> az policy definition create -n $policy_def --rules rules.json --params rulesparams.json
```
>*output similar to:*
```PowerShell
{
  "description": null,
  "displayName": null,
  "id": "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/providers/Microsoft.Authorization/policyDefinitions/DenyIfNoTagsPolicy",
  "metadata": {
    "createdBy": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "createdOn": "2020-09-02T16:49:29.5984076Z",
    "updatedBy": null,
    "updatedOn": null
  },
  "mode": "Indexed",
  "name": "DenyIfNoTagsPolicy",
  "parameters": {
    "tagName": {
      "allowedValues": null,
      "defaultValue": null,
      "metadata": {
        "additionalProperties": null,
        "description": "Name of the tag, such as 'test'",
        "displayName": "Tag Name"
      },
      "type": "String"
    }
  },
  "policyRule": {
    "if": {
      "allof": [
        {
          "like": "myproject*",
          "value": "[resourceGroup().name]"
        },
        {
          "exists": "false",
          "field": "[concat('tags[', parameters('tagName'), ']')]"
        }
      ]
    },
    "then": {
      "effect": "deny"
    }
  },
  "policyType": "Custom",
  "type": "Microsoft.Authorization/policyDefinitions"
}
```
#### Assign Policy
We have now defined our policy, the next step will be to assign this policy to our subscription.
To assign the defined policy we will used the ```az policy assignment create``` command. We need to pass a parameter to this policy (as we created in the policy definition) so we need to create a JSON file, ```tagparam.json``` to pass this value.
Copy the following code into the JSON file just created.
```JSON
{
"tagName": 	{
			"value": "test"
			}
}
```
Then run the following command:
```PowerShell
\policy> az policy assignment create -n 'tagging_policy' --policy $policy_def --params tagparam.json
```
>*output similar to:*
```PowerShell
{
  "description": null,
  "displayName": null,
  "enforcementMode": "Default",
  "id": "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/providers/Microsoft.Authorization/policyAssignments/tagging_policy",
  "identity": null,
  "location": null,
  "metadata": {
    "createdBy": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "createdOn": "2020-09-02T17:51:44.890264Z",
    "updatedBy": null,
    "updatedOn": null
  },
  "name": "tagging_policy",
  "notScopes": null,
  "parameters": {
    "tagName": {
      "value": "test"
    }
  },
  "policyDefinitionId": "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/providers/Microsoft.Authorization/policyDefinitions/DenyIfNoTagsPolicy",
  "scope": "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "sku": {
    "name": "A0",
    "tier": "Free"
  },
  "type": "Microsoft.Authorization/policyAssignments"
}
```
We can check to see the list of policy assigned in our subscription by using the ```az policy assignment list``` and verifying that our policy is in the list. Alternatively, you can verify in the Azure Portal.

## Environment Variables
As a DevOps Engineer, it is imperative that we reduce manual imputations of variables. The best way to do this is by using scripts, but for this project, we are going to be storing variables in the shell environment so we can reuse across  the board. 
So far, we have defined two Environment Variables: ```policy_def``` that holds the name of the Policy Definition and ```subs_id``` that holds the Subscription ID.  
_In PowerShell, Environment Variables are declared with the ```$``` prefix._

_**Note:** The final list of Environment Variables will be available at the end._


We will capture Environment Variables in a table for reference. Values can be defined as required.
The table below identifies some of the variables we will utilize.

### _Environment Set Variables_

 Env. Variable  | Value 		| Comment 						
----------------| ------------- | ----------------------------- 
subs_id 		|xxxxxxxxx		|This holds the Subscription ID 
policy_def		|DenyIfNoTagPolicy|	This is the Policy Definition Name							
prefix			|myproject		|This is the prefix used for naming resources
rg_name			|{$prefix}-rg	| This holds the resource Group name
image_name		|{$prefix}-vmimage|This holds the VM Image name
rg_location		|eastus			|This holds the location resources
rs_tag_key		|test			| This holds the Tag Key for resources
rs_tag_value	|{$prefix}		| This holds the Tag Value for resources
vm_username		| azureterrauser| This holds the username for the VM
vm_password		| xxxxxxxxxxxxx	| This holds the password for the user

In PowerShell, enter the following commands to ensure we have these variables in the environment as we will be accessing them when we build the Packer and TerraForm templates:
```PowerShell
> $prefix='myproject'
> $rg_name="$prefix-rg"
> $image_name="$prefix-vmimage"
> $rg_location='eastus'
> $rs_tag_key='test'
> $rs_tag_value=$prefix
> $vm_username='azureterrauser'
> $vm_password='1234567890
```

### Create a Resource Group
The first thing we need to do before creating any resource on Azure is to create a resource group. Resource Groups are containers that hold all the resources together.
To create the resource group, we use the command  ```az group create``` as shown below:
```PowerShell
az group create -n $rg_name -l $rg_location
```
>*output similar to:*
```PowerShell
{
  "id": "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/myproject-rg",
  "location": "eastus",
  "managedBy": null,
  "name": "myproject-rg",
  "properties": {
    "provisioningState": "Succeeded"
  },
  "tags": null,
  "type": "Microsoft.Resources/resourceGroups"
}
```

## Packer
The next step will be to Create the VM image using Packer.
The client has indicated that she wants an Linux UbuntuServer 18.04 LTS. She also wants a simple HTML file (that returns _```Hello, World!```_ ) to be Provisioned after the Image has been deployed in the VM. 
To create the VM Image, lets investigate what variables we will need.
We would need to grant Packer App access to our Azure Subscriptions by creating a Service Principal using ```az ad sp create```. Once the Service Principal has been created, we need to have the following attributes of the Service Principal:
```
- Client ID
- Client Password (Secret)
- Tenant ID
```
To create a quick Service Principal using defaults, let use run the command as shown below:
```PowerShell
az ad sp create-for-rbac --query "{Client_ID: appId, Client_Secret : password, Tenant_ID: tenant}"
```
>*output similar to:*
```PowerShell
Creating a role assignment under the scope of "/subscriptions/c5b70caf-bdd9-4336-b990-edf1b1ea365d"
  Retrying role assignment creation: 1/36
{
  "Client_ID": "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz",
  "Client_Secret": "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
  "Tenant_ID": "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
}
```
Take a note of these outputs as we will use them in the Packer Template.

A Packer template is constructed with JSON using the following key parameters:
```
- variables
- builders
- provisioners
```
_**Note:** For more on Packer Templates, Visit: [https://www.packer.io/guides/packer-on-cicd](https://www.packer.io/guides/packer-on-cicd)_

####  Packer Variables
Packer Variables	| Comment 
--------------------| ------------------------ 
"client_id"  		| Client ID from Service Principal _**(environment)**_
"client_secret" 	| Client ID from Service Principal _**(environment)**_
"subscription_id" 	| Azure Subscription ID _**(environment)**_
"tenant_id" 		| Azure Tenant ID _**(environment)**_
"vmlocation" 		| Location of VM _**(environment)**_
"vmcpu_size" 		| Size of VM _**(hardcoded)**_
"vm_image_rg_name" 	| Name of VM Image Resource Group _**(environment)**_
"vm_image_name" 	| Name of VM Image _**(environment)**_
"resource_tag_name" | Resource Tag Key _**(environment)**_
"resource_tag_value"| Resource Tag Value _**(environment)**_

To use variables from Environment, Packer looks for tags in the following format: ```ARM_XXXXXX``` where ```XXXXXX``` is the variable name and then this tag can be assigned in the template by using  ```"{{env `ARM_XXXXX`}}"```. 
We can now create these Variables in the Environment. (Service Principal credentials copied above)
```PowerShell
> $env:ARM_CLIENT_ID='zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz'
> $env:ARM_CLIENT_SECRET='wwwwwwwwwwwwwwwwwwwwwwwwwwwwwww'
> $env:ARM_SUBSCRIPTION_ID=$subs_id
> $env:ARM_TENANT_ID='yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy'
> $env:ARM_IMAGE_LOCATION=$rg_location 
> $env:ARM_IMAGE_RG = $rg_name
> $env:ARM_IMAGE_NAME = $image_name
> $env:ARM_RS_TAG_KEY = $rs_tag_key
> $env:ARM_RS_TAG_VALUE = $rs_tag_value
```
####  Packer Builders
The Builder is used to get the characteristics and features of the VM image. Below are the characteristics and feature we will be utilizing.
Builders Features	| Comments 
--------------------| ------------------------ 
"type"  			| Cloud Resource Type _**(hardcoded: azure-arm)**_
"client_id"  		| Client ID from Service Principal _**(user variable: client_id)**_
"client_secret" 	| Client ID from Service Principal _**(user variable: client_secret)**_
"tenant_id" 		| Azure Tenant ID _**(user variable: tenant_id)**_
"subscription_id" 	| Azure Subscription ID _**(user variable: subscription_id)**_
"os_type" 		| OS Type _**(hardcored: Linux)**_
"image_publisher" 		| Image Publisher _**(hardcored: Canonical)**_
"image_offer" 		| Image Offer _**(hardcoded: UbuntuServer)**_
"image_sku" 	| Name of VM Image Resource Group _**(hardcoded: 18.04-LTS)**_
"managed_image_resource_group_name" 	| Name of VM Image Resource Group _**(user variable: vm_image_rg_name)**_
"managed_image_name" | VM Image Name _**(user variable: vm_image_name)**_
"azure_tags"/"resource_tag_name"| Resource Tag Name _**(user variable: resource_tag_name)**_
"azure_tags"/"resource_tag_value"| Resource Tag Value _**(user variable: resource_tag_value)**_

To use variables from template, Packer uses the following format  ```"{{user `ZZZZZ`}}"``` where ```ZZZZZ``` is the variable defined in the variable parameter. 

####  Provisioner
The Provisioner is used to install an application when the image as being deployed in the new VM. For this task, it will just be an HTML file with the content ```"Hello, World!"```. Visit the Packer GitHub for more examples and templates.


####  Deploy Template
Now that we have all the requirements for the template, we create a JSON file, ```server.json```, and copy the code below to it.

```JSON
{
"variables": {
			"client_id": "{{env `ARM_CLIENT_ID`}}",
			"client_secret": "{{env `ARM_CLIENT_SECRET`}}",
			"subscription_id": "{{env `ARM_SUBSCRIPTION_ID`}}",
			"tenant_id": "{{env `ARM_TENANT_ID`}}",
			"vmlocation" : "{{env `ARM_IMAGE_LOCATION`}}",
			"vmcpu_size": "Standard_D2s_v3",
			"vm_image_rg_name" : "{{env `ARM_IMAGE_RG`}}",
			"vm_image_name" : "{{env `ARM_IMAGE_NAME`}}",
			"resource_tag_name" : "{{env `ARM_RS_TAG_KEY`}}",
			"resource_tag_value" : "{{env `ARM_RS_TAG_VALUE`}}"
			},
"builders": [
			{
			"type": "azure-arm",
			"client_id": "{{user `client_id`}}",
			"client_secret": "{{user `client_secret`}}",
			"tenant_id": "{{user `tenant_id`}}",
			"subscription_id": "{{user `subscription_id`}}",
			"os_type": "Linux",
			"image_publisher": "Canonical",
			"image_offer": "UbuntuServer",
			"image_sku": "18.04-LTS",
			"managed_image_resource_group_name": "{{user `vm_image_rg_name`}}",
			"managed_image_name": "{{user `vm_image_name`}}",

			"azure_tags": {
			"{{user `resource_tag_name`}}": "{{user `resource_tag_value`}}"
			},
			"location": "{{user `vmlocation`}}",
			"vm_size": "{{user `vmcpu_size`}}",
			"async_resourcegroup_delete": true
			}
			],

"provisioners": [
			{
			"type": "shell",
			"inline": [
			"echo 'Hello, World!' > index.html",
			"nohup busybox httpd -f -p 80 &"
			],
			"inline_shebang": "/bin/sh -x"
			}
			]
}
```

Use the command, ```packer build``` , to build the VM image. 
_**Note:** Before you do, verify that there is already a resource group created by using the command ```az group exists -n $rg_name```._

```Powershell
\packer> packer build server.json
```
>*output similar to:*
```PowerShell
packer build server.json
azure-arm: output will be in this color.

==> azure-arm: Running builder ...
==> azure-arm: Getting tokens using client secret
==> azure-arm: Getting tokens using client secret
    azure-arm: Creating Azure Resource Manager (ARM) client ...
==> azure-arm: WARNING: Zone resiliency may not be supported in eastus, checkout the docs at https://docs.microsoft.com/en-us/azure/availability-zones/
==> azure-arm: Creating resource group ...
==> azure-arm:  -> ResourceGroupName : 'pkr-Resource-Group-kohkjcbwwh'
==> azure-arm:  -> Location          : 'eastus'
==> azure-arm:  -> Tags              :
==> azure-arm:  ->> test : myproject
==> azure-arm: Validating deployment template ...
==> azure-arm:  -> ResourceGroupName : 'pkr-Resource-Group-kohkjcbwwh'
==> azure-arm:  -> DeploymentName    : 'pkrdpkohkjcbwwh'
==> azure-arm: Deploying deployment template ...
==> azure-arm:  -> ResourceGroupName : 'pkr-Resource-Group-kohkjcbwwh'
==> azure-arm:  -> DeploymentName    : 'pkrdpkohkjcbwwh'
==> azure-arm: Getting the VM's IP address ...
==> azure-arm:  -> ResourceGroupName   : 'pkr-Resource-Group-kohkjcbwwh'
==> azure-arm:  -> PublicIPAddressName : 'pkripkohkjcbwwh'
==> azure-arm:  -> NicName             : 'pkrnikohkjcbwwh'
==> azure-arm:  -> Network Connection  : 'PublicEndpoint'
==> azure-arm:  -> IP Address          : '13.82.176.207'
==> azure-arm: Waiting for SSH to become available...
==> azure-arm: Connected to SSH!
==> azure-arm: Provisioning with shell script: C:\Users\User\AppData\Local\Temp\packer-shell325797499
==> azure-arm: + echo Hello, World!
==> azure-arm: + nohup busybox httpd -f
==> azure-arm: Querying the machine's properties ...
==> azure-arm:  -> ResourceGroupName : 'pkr-Resource-Group-kohkjcbwwh'
==> azure-arm:  -> ComputeName       : 'pkrvmkohkjcbwwh'
==> azure-arm:  -> Managed OS Disk   : '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/PKR-RESOURCE-GROUP-KOHKJCBWWH/providers/Microsoft.Compute/disks/pkroskohkjcbwwh'
==> azure-arm: Querying the machine's additional disks properties ...
==> azure-arm:  -> ResourceGroupName : 'pkr-Resource-Group-kohkjcbwwh'
==> azure-arm:  -> ComputeName       : 'pkrvmkohkjcbwwh'
==> azure-arm: Powering off machine ...
==> azure-arm:  -> ResourceGroupName : 'pkr-Resource-Group-kohkjcbwwh'
==> azure-arm:  -> ComputeName       : 'pkrvmkohkjcbwwh'
==> azure-arm: Capturing image ...
==> azure-arm:  -> Compute ResourceGroupName : 'pkr-Resource-Group-kohkjcbwwh'
==> azure-arm:  -> Compute Name              : 'pkrvmkohkjcbwwh'
==> azure-arm:  -> Compute Location          : 'eastus'
==> azure-arm:  -> Image ResourceGroupName   : 'myproject-rg'
==> azure-arm:  -> Image Name                : 'myproject-vmimage'
==> azure-arm:  -> Image Location            : 'eastus'
==> azure-arm: Deleting resource group ...
==> azure-arm:  -> ResourceGroupName : 'pkr-Resource-Group-kohkjcbwwh'
==> azure-arm:
==> azure-arm: The resource group was created by Packer, deleting ...
==> azure-arm:
==> azure-arm: Resource Group is being deleted, not waiting for deletion due to config. Resource Group Name 'pkr-Resource-Group-kohkjcbwwh'
==> azure-arm: Deleting the temporary OS disk ...
==> azure-arm:  -> OS Disk : skipping, managed disk was used...
==> azure-arm: Deleting the temporary Additional disk ...
==> azure-arm:  -> Additional Disk : skipping, managed disk was used...
==> azure-arm: Removing the created Deployment object: 'pkrdpkohkjcbwwh'
==> azure-arm: ERROR: -> ResourceGroupBeingDeleted : The resource group 'pkr-Resource-Group-kohkjcbwwh' is in deprovisioning state and cannot perform this operation.
==> azure-arm:
Build 'azure-arm' finished.

==> Builds finished. The artifacts of successful builds are:
--> azure-arm: Azure.ResourceManagement.VMImage:

OSType: Linux
ManagedImageResourceGroupName: myproject-rg
ManagedImageName: myproject-vmimage
ManagedImageId: /subscriptions/c5b70caf-bdd9-4336-b990-edf1b1ea365d/resourceGroups/myproject-rg/providers/Microsoft.Compute/images/myproject-vmimage
ManagedImageLocation: eastus
```
As seen in the output above, the Package Image has been created and is located in the Resource Group we specified. We can confirm this by using the the command, ```az resource list ``` , to look inside the resource group, i.e:
```Bash
> az resource list --resource-group $rg_name --query "[].{Resource_Name: name, Resource_Type:type}" -o table
```
>*output similar to:*
```Bash
Resource_Name      Resource_Type
-----------------  ------------------------
myproject-vmimage  Microsoft.Compute/images
```

## TerraForm
TerraForm uses 2 main files to hold its template. A main file, which we will name as ```main.tf``` and a file for variables, which we will call ```var.tf```. TerraForm templates are generated with a proprietary language called HCL. HCL language uses the ```.tf``` suffix on its files.

The main file, ```main.tf```, is used to house parameters responsible for building resources.
The variables file, ```var.tf```, is used to hold variables that will be used by main file. 

_**Note:** For more information on TerraForm Template structure, please visit:_ [https://www.terraform.io/docs/providers/azurerm/index.html](https://www.terraform.io/docs/providers/azurerm/index.html)

### Variables: 

And the following variables will be used.
Variable	| Comments 
--------------------| ------------------------ 
vmcount 			| Number of VMs to be deployed (between 2 and 5) _**(command-line)**_
prefix			| The prefix which should be used for all resources in this example _**(environment)**_
location|The location where resources are created _**(environment)**_
tagKey|Resource Tag Key _**(environment)**_
tagValue|Resource Tag Value _**(environment)**_
vmimage|This is the name of the image created _**(environment)**_
vmimagerg|This is the name of the Resource Group that image was created _**(environment)**_
username| Username of VM _**(environment)**_
password| Password of User _**(environment)**_

TerraForm can read values in the environment, provided the have the following syntax: ```TF_VAR_XXXXX``` where ```XXXXX``` is the variable name.

So we will create the variables shown above in the environment as follows:
```Bash
> $env:TF_VAR_prefix=$prefix
> $env:TF_VAR_location=$rg_location
> $env:TF_VAR_tagKey=$rs_tag_key
> $env:TF_VAR_tagValue=$rs_tag_value
> $env:TF_VAR_vmimage=$image_name
> $env:TF_VAR_vmimagerg=$rg_name
> $env:TF_VAR_username=$vm_username
> $env:TF_VAR_password=$vm_password
```
Create a file named ```var.tf```, if you haven't done so already, and copy the following code to it.
```HCL
variable  "vmcount" {
		type =  number
		description =  "Number of VM to create?"
		validation {
		condition =  var.vmcount > 1 && var.vmcount < 6
		error_message =  "The VM count should be between 2 and 5 (Default is 2. Max is 5)."
		}
}
  
variable  "prefix" {
		description =  "The prefix which should be used for all resources in this example"
}  

variable  "location" {
		description =  "The location where resources are created"
}

variable  "tagKey" {
		description =  "Resource Tag Key"
}

variable  "tagValue" {
		description =  "Resource Tag Value"
}  

variable  "vmimage" {
		description =  "This is the name of the image created"
}  

variable  "vmimagerg" {
		description =  "This is the name of the Resource Group that image was created"
} 

variable  "username" {
		description =  "Enter Username"
} 

variable  "password" {
		description =  "Enter Password"
}
```
Notice that we has environment values set for all but the ```vmcount``` variable. This is because we intend to make the user be prompted to specify how many VMs to create. There is a validation logic on the variable that ensures that no more than 5 VMs are created at one time with the tool and no fewer than 2.


### Resources: 

We need to build resources to meet the requirements as described in the image below:
![##### *Azure Web Server Architecture (Deny Access from Internet)*Azure WebServer Deny Internet to VMs](https://engrcog.com/wp-content/uploads/2020/09/Automate-WebServerno-bastion.jpeg)
##### *Azure Web Server Architecture (Deny Access from Internet)*

The following are resources that we would like to be provisioned. Some resources will be created multiple times, as required based on the count of VMs requested by user. Some resources are really just resource parameters and do not need to have a resource tags specified.

Resource| Count | Tags|Comments
--------------------| ----|-----|--------------- 
Resource Group	| -| - | Resource Group has already been created, so we load it into TerraForm and reference it
Virtual Network		| 1| Y | Address Space: 10.0.0.0/16
Subnet|1 | N |Address Prefix: 10.0.2.0/24
Network Security Group|1 |Y| Deny Internet Access to VM
Public IP Address| 1| Y | _Will not be used as the Load Balancer is Internal_
Load Balancer | 1 | Y | This load balancer is internal and will use Private IP address from the subnet address range above
Backend Address Pool| 1 | N | This is the backend pool feature of the Load Balancer
Availability Set| 1 | Y | Availability Set that will be Assigned to VMs
Network Interface |2 - 5 | Y| Network Interface for VM
Address Pool NI to LB association| 2  - 5 | N | A feature used to match NI to LB Backend Address Pool
Get Packer image|1 | N | This is a command to load data (the Packer Image) 
Linux VM | 2 - 5 | Y | This is the Linux VM Server to be provisioned. _Fixed size: Standard_D2s_v3_
Managed Disks |2 - 5| Y | 100 GB Data Disk to be attached to VM
Attach Managed Disks| 2 - 5| N| A feature to attach the Managed Disks to VM


In the ```main.tf``` file, create one if you haven't already, copy the following code. 

```HCL
provider  "azurerm" {
features {}
}


# CREATE RESOURCE
#Resource Already Created on the CLI so we call it
data  "azurerm_resource_group"  "main" {
name =  "${var.vmimagerg}"
}

  
  

# CREATE VIRTUAL NETWORK AND SUBNETS
# Virtual Network (VNet)
resource  "azurerm_virtual_network"  "main" {
name =  "${var.prefix}-vnet"
address_space =  ["10.0.0.0/16"]
location =  var.location
resource_group_name =  data.azurerm_resource_group.main.name
tags =  {
"${var.tagKey}" ="${var.tagValue}"
}
}

# Backend subnet
resource  "azurerm_subnet"  "main" {
name =  "${var.prefix}-vm-subnet"
resource_group_name =  data.azurerm_resource_group.main.name
virtual_network_name =  azurerm_virtual_network.main.name
address_prefixes =  ["10.0.2.0/24"]
}
  
  

# CREATE NETWORK SECURITY GROUP (Deny Access to Internet)
resource  "azurerm_network_security_group"  "main" {
name =  "${var.prefix}-nsg"
location =  data.azurerm_resource_group.main.location
resource_group_name =  data.azurerm_resource_group.main.name
security_rule {
name =  "IN-Allow-only-VM-in-Subnets"
priority =  4096
direction =  "Inbound"
access =  "Deny"
protocol =  "*"
source_port_range =  "*"
destination_port_range =  "*"
source_address_prefix =  "Internet"
destination_address_prefix =  "VirtualNetwork"
}

security_rule {
name =  "OUT-Allow-only-VM-in-Subnets"
priority =  4096
direction =  "Outbound"
access =  "Deny"
protocol =  "*"
source_port_range =  "*"
destination_port_range =  "*"
source_address_prefix =  "VirtualNetwork"
destination_address_prefix =  "Internet"
}

  

tags =  {
"${var.tagKey}" ="${var.tagValue}"
}
}

  
  
  

# CREATE LOAD BALANCER (Including PUBLIC IP (or PRIVATE IP) and Backend Address Pool) 

#Public IP (Not needed for this task but will be created)
resource  "azurerm_public_ip"  "main" {
name =  "${var.prefix}-public-ip"
location =  var.location
resource_group_name =  data.azurerm_resource_group.main.name
allocation_method =  "Static"
domain_name_label =  data.azurerm_resource_group.main.name
tags =  {
"${var.tagKey}" ="${var.tagValue}"
}
}

# Load Balancer (LB)
resource  "azurerm_lb"  "main" {
name =  "${var.prefix}-lb"
location =  var.location
resource_group_name =  data.azurerm_resource_group.main.name
  

frontend_ip_configuration {
name =  "${var.prefix}-pip"
# for Public Load Balancer, use the "public_ip_address_id" for the Public IP resource.
# public_ip_address_id = azurerm_public_ip.main.id  

# for Internal Load Balancer, use "subnet_id" of the subnet resource (configured as backend) on the VNet resource.
subnet_id =  azurerm_subnet.main.id
}

  

tags =  {
"${var.tagKey}" ="${var.tagValue}"
}
}

# Backend Address pool
resource  "azurerm_lb_backend_address_pool"  "main" {
name =  "${var.prefix}-BackEndAddressPool"
resource_group_name =  data.azurerm_resource_group.main.name
loadbalancer_id =  azurerm_lb.main.id
}

  
  
  

# CREATE AVAILABILITY SET
resource  "azurerm_availability_set"  "main" {
name =  "${var.prefix}-avset"
location =  data.azurerm_resource_group.main.location
resource_group_name =  data.azurerm_resource_group.main.name
tags =  {
"${var.tagKey}" ="${var.tagValue}"
}
}

  

#CREATE NICS and CONNECTION TO LOAD BALANCER BACK END POOL  

# Network Interface (NIC)
resource  "azurerm_network_interface"  "main" {
count =  var.vmcount
name =  "${var.prefix}-nic${count.index+1}"
location =  data.azurerm_resource_group.main.location
resource_group_name =  data.azurerm_resource_group.main.name
  

ip_configuration {
name =  "${var.prefix}-nic-ipconfig${count.index+1}"
subnet_id =  azurerm_subnet.main.id
private_ip_address_allocation =  "Dynamic"
}

  

tags =  {
"${var.tagKey}" ="${var.tagValue}"
}
}

# Address Pool Association from NIC to LB

resource  "azurerm_network_interface_backend_address_pool_association"  "main" {
count =  var.vmcount
network_interface_id =  azurerm_network_interface.main[count.index].id
ip_configuration_name =  "${var.prefix}-nic-ipconfig${count.index+1}"
backend_address_pool_id =  azurerm_lb_backend_address_pool.main.id
}

  
  

# GET IMAGE MADE BY PACKER 

# Assign resource group name of image
data  "azurerm_resource_group"  "image" {
name =  "${var.vmimagerg}"
}

# Get Packer Image
data  "azurerm_image"  "image" {
name =  "${var.vmimage}"
resource_group_name =  data.azurerm_resource_group.image.name
}

  
  

# CREATE LINUX VIRTUAL MACHINE (VM)
resource  "azurerm_linux_virtual_machine"  "main" {
count =  var.vmcount
name =  "${var.prefix}-vm${count.index+1}"
resource_group_name =  data.azurerm_resource_group.main.name
location =  data.azurerm_resource_group.main.location
availability_set_id =  azurerm_availability_set.main.id
size =  "Standard_D2s_v3"
admin_username =  var.username
admin_password =  var.password
disable_password_authentication =  false
network_interface_ids =  [ azurerm_network_interface.main[count.index].id, ]
source_image_id =data.azurerm_image.image.id

  

os_disk {
storage_account_type =  "Standard_LRS"
caching =  "ReadWrite"
}
  

tags =  {
"${var.tagKey}" ="${var.tagValue}"
}
}

  
  

# Managed Disks
resource  "azurerm_managed_disk"  "main" {
count =  var.vmcount
name =  "${var.prefix}-md${count.index+1}"
location =  data.azurerm_resource_group.main.location
resource_group_name =  data.azurerm_resource_group.main.name
storage_account_type =  "Standard_LRS"
create_option =  "Empty"
disk_size_gb =  "100"
tags =  {
"${var.tagKey}" ="${var.tagValue}"
}
}

  

# Attach Managed Disk
resource  "azurerm_virtual_machine_data_disk_attachment"  "main" {
count =  var.vmcount
managed_disk_id =  azurerm_managed_disk.main[count.index].id
virtual_machine_id =  azurerm_linux_virtual_machine.main[count.index].id
lun =  "10"
caching =  "ReadWrite"
}

```

### Deploying the Infrastructure
This step must be done only after creating the packer image. If not already created, create it can proceed with this step.

#### Initialization
In CLI, go to the folder where you have saved the ```main.tf``` and the ```var.tf```, and run the following command, ```terraform init ```:
```Bash
\TerraForm> terraform init
```
This initializes the TerraForm environment. a ```.terraform``` folder containing is created in the folder with the ```main.tf``` and the ```var.tf``` files which contains necessary plugins.

#### Plan
Once TerraForm has been initialized, the next step is to run the plan, ```terraform plan``` command. This command will cycle through the HCL TerraForm template and try to identify any errors and also investigate if the necessary resources for deploy are available. We can also get an output of the plan for review purposes. For this project, I will save the out put of the plan to ```solution.plan``` by running the following command:
_(**Note:** that the user will be requested to enter the number of VMs he wants to deploy when the command is run)_
```Bash
\TerraForm> terraform plan -out solution.plan
```

>*output similar to:*
```Bash
\TerraForm> terraform plan -out solution.plan
var.vmcount
  Number of VM to create??

  Enter a value: 2

Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

data.azurerm_resource_group.image: Refreshing state...

.......<output abbridged for clarity>................

  # azurerm_virtual_network.main will be created
  + resource "azurerm_virtual_network" "main" {
      + address_space       = [
          + "10.0.0.0/16",
        ]
      + guid                = (known after apply)
      + id                  = (known after apply)
      + location            = "eastus"
      + name                = "myproject-vnet"
      + resource_group_name = "myproject-rg"
      + subnet              = (known after apply)
      + tags                = {
          + "test" = "myproject"
        }
    }

Plan: 17 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

This plan was saved to: solution.plan

To perform exactly these actions, run the following command to apply:
    terraform apply "solution.plan"
```

As you can see from a snippet of the output, it shows that a number of resource have planned to be added and also informs that the TerraForm plan was saved. Next we apply these actions.

#### Apply
To apply the actions listed on the plan we run the following command as instructed:

```Bash
\TerraForm> terraform apply "solution.plan"
```

This command will go through the process of building the required resources.

We can confirm that the resources have actually been created by running the following command to view the resources in the resource group:

```Bash
> az resource list --resource-group $rg_name --query "[].{Resource_Name: name, Resource_Type:type}" -o table
```
>*output similar to:*
```Bash
\TerraForm> az resource list --resource-group $rg_name --query "[].{Resource_Name: name, Resource_Type:type}" -o table
Resource_Name                                         Resource_Type
----------------------------------------------------  ---------------------------------------
myproject-avset                                       Microsoft.Compute/availabilitySets
myproject-md1                                         Microsoft.Compute/disks
myproject-md2                                         Microsoft.Compute/disks
myproject-md3                                         Microsoft.Compute/disks
myproject-md4                                         Microsoft.Compute/disks
myproject-md5                                         Microsoft.Compute/disks
myproject-vm1_disk1_2b4d358831d54b57bd0fbd365c43f71c  Microsoft.Compute/disks
myproject-vm2_disk1_487bea1a3585497993c924ddefee83e6  Microsoft.Compute/disks
myproject-vm3_disk1_e04583e236b84f289bb7abc662571497  Microsoft.Compute/disks
myproject-vm4_disk1_0fc211a3e4f146c0b938b2a80c7b342f  Microsoft.Compute/disks
myproject-vm5_disk1_cb4479c466574f9b953b340043bd40c4  Microsoft.Compute/disks
myproject-vmimage                                     Microsoft.Compute/images
myproject-vm1                                         Microsoft.Compute/virtualMachines
myproject-vm2                                         Microsoft.Compute/virtualMachines
myproject-vm3                                         Microsoft.Compute/virtualMachines
myproject-vm4                                         Microsoft.Compute/virtualMachines
myproject-vm5                                         Microsoft.Compute/virtualMachines
myproject-lb                                          Microsoft.Network/loadBalancers
myproject-nic1                                        Microsoft.Network/networkInterfaces
myproject-nic2                                        Microsoft.Network/networkInterfaces
myproject-nic3                                        Microsoft.Network/networkInterfaces
myproject-nic4                                        Microsoft.Network/networkInterfaces
myproject-nic5                                        Microsoft.Network/networkInterfaces
myproject-nsg                                         Microsoft.Network/networkSecurityGroups
myproject-public-ip                                   Microsoft.Network/publicIPAddresses
myproject-vnet                                        Microsoft.Network/virtualNetworks
```

Or by viewing the portal:![Output from TerraForm](https://engrcog.com/wp-content/uploads/2020/09/Portal-Output-scaled.jpg)


Once we have confirmed that the resources have been created, we will delete it (to avoid incurring costs).

#### Destroy
Since TerraForm is a state-based Automation tool it can track the actions it has taken to create resources and reverse them enabling those resources to be destroyed.
To destroy, we enter the following command:
```Bash

```

After running, it will verify if we want to delete the resources. Since we want to delete, we type ```yes``` and hit enter to continue with the deletion process.
```Bash
Plan: 0 to add, 0 to change, 32 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

```
>*output similar to:*

```Bash 
```
We have successfully destroyed the Resources.

## Summary
In this project, we learned how to do the following:
- Basic steps in Building Infrastructure-as-Code 
- Process client requests on Architecture development.
- Develop a Packer Template for creating Virtual Machine Images. 
- Use TerraForm to build Infrastructure while utilizing the Image Created with Packer. 
- Automate the process of deploying resources. 
- Create a Managed Disk and Attach it to a VM.
- Define and assign an Azure Policies, including the use of conditional logic techniques to determine when to Deny or Grant access to resources.
- Configure a Network Security Group and the use of its policies to restrict or grant access to Network resources on Azure using Inbound and Outbound Rules. 
- Configure the Load Balancer to work within an Availability set with Virtual Machines, and how to set up a Private IP for utilizing a Load Balancer Internally.

We learned a lot about what Infrastructure-as-Code entails but what we did not do was so Network related tasks like to test Load Balance Process. The reason is because the Virtual Machines did not have access to the Internet. Two reasons why there was no access was because of these Client requirements: Firstly, Deny Internet Access to VMs and secondly, configure the Load Balancer to strictly Balance the traffic between the VMs. - which means no Public IP address for internet access.

The next steps will be the following:
- Investigate and test ways in which we can access the VMs securely from outside the internet. Currently exploring the latest Azure Offering (Bastion).
- Create a Windows Server Image following similar steps.
