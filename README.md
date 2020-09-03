# Infrastructure-as-Code (using Azure)

### Creating a Web-server by deploying a VM with Terraform with image from Packer

## Overview

The aim of this project is to use the DevOps tool, Infrastructure-as-Code to deploy a Web Server as a Virtual Machine. We will use the Provisioning tool, Terraform, to provision the Virtual Machine (VM). The server template tool, Packer, will be used to develop a server template that will be used by Terraform. To provision the VM, the infrastructure should have the necessary resources in place in other for the VM to run. Some of the client's major requirements are as shown below:
Scalability: The VMs should be in an Availability Set (with a minimum and default of 2 VMs running with the capacity to increase the VM count to 5).
Security: The Virtual Network should be in such a way where the VMs in the Network should not be accessible by the Internet but should be accessible within the VMs in the subnet.
Efficiency: The Virtual Network should have a Load Balancer to distribute the work load to the VMs available in the Network.
Disks: The client has also requested that there are Managed Disks attached for each VM deployed.

At the end of this project we should have a TerraForm and Packer template that can be used to deploy VMs of the same requirements as need.

## Packer 
What is Packer? Parker is one of the DevOps tools used to generate Server Templates for automated Deployment. These server templates can also be configured to include the application and software as required by the project. Packer tools are scripted with JSON. The Packer template is made up of 3 key key attributes: The Variable attribute, the Builders attribute and the Provisioners Attribute. The Variable attributes is used to hold variables that can be used in the building of the server template. These variables can also bind to variables stored in the shell environment. The Builder attribute is used to identify the properties of the Server to be built, including the type of image (WIndows or Linux), size of CPU, etc. The last attribute we are going to talk about is the Provisioner Attribute. This attribute is used to deploy applications after the Image has being built. Here, you can give instructions to run an application, Install a Web SErver, etc. For this project we will just be creating a little html file with the output "Hello, World".

## TerraForm
Terraform is a DevOps Provisioning tool that can be used to automate the creation of Resources needed for a Cloud environment. TerraForm tools are written with a propitiatory language called HCL. HCL is a script language similar to JSON. The HCL script is usually contains attributes that tell the script what to do. The 3 major attributes are Provider, Resource and Data. The Provider Attribute is used to identify the type of Cloud environment being utilized, in this case it is Azure. The Resource Attributes are used as a template to generate resources in the Cloud environment for example, Virtual Networks and Managed Disks.

## Packer and TerraForm Installation and Setup


## Identifying Resourses
BEfore we begin, we will take a look at all the resources that is required to meet the client specifications. When creating a VM in a cloud enviroment, the following resources are typically created along side it. The first this we need is to create a **Resource Group**. A resource group will contain all the resources necessary to deploy these VMs.
A Virtual Machine needs to be in a Network to be effective, so a **Virtual Network (VNet)** is required when a VM is spurn (a way of saying created). To be in a Network, the VM must have **Network Interface Cards (NIC)** so this resource is created. The VMs will need to be segregated within a Network to restrict access to those who dont need to be on it. It is recommented that Virtual Networks have subnets so that the Network can be managed better. This is the reason why we will need a **Subnet** resource. Chances are that we want to be able to access our VMs from the Internet at some point in time, this means our network will require a **Public IP address**. We will also need a **Network Security Gateway** resouce that will house polices on communication rules within the Network. The client also specified a need for a **Load Balancer** so we will need that resource and finally, we will need a *Managed Disk** to be attached to the VM. This Managed Disk is different from the OS disk that is created by default alonside the VM.
A recap of the resources we need to create a VM so far:
Resource Group
Virtual Machine
Virtual Network (the Subnet resource is included in VNet resource)
Public IP Address
Network Security Gateway
Network Interface Card

## Resource Tagging Policy
One of the requirements from the client was to ensure that any resources created was tagged appropiatly. So we need to Create a policy definition for this purpose and assign the policy to our scope of work - which for this project will be applied to the subscription.

## Security Policy
By Default, when a network resource is created, there is always an NSG (Network Segurity Group) deployed with it. The NSG contains a group of rules or policies telling the network how to send or recieve information. By deafault, it has some set of rules that restrict communication with the internet on all ports. Only the ports specified in the resource creation stage is allowed. In addition to this policy, the client has requested that she doesnt want any communications from the internet in the network, only communication between the VMs in the network.




## Begin



### Azure CLI

Install the latest version of Powershell 7, and run it. Ensure you have installed the latest CLI module to start with as we will be using the this for this task.

First, we log on to Azure. Enter the following on PowerShell:

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
_**Note:** It is good practise to do this, we need to avoid repeatitions as often as possible. We will keep track of all the environment variables as we proceed with this task._
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
output
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

In PowerShell, enter the following commands to ensure we have these variables in the environment as we will be accessing them when we build the Packer and Terraform templates:
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
The first thing we need to do before creating any resource on Azure is to create a resourc group. Resource Groups are containers that hold all the resources together.
To create the resource group, we use the command  ```az group create``` as shown below:
```PowerShell
az group create -n $rg_name -l $rg_location
```
Output:
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
output:
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
The Provisioner is used to install an application when the image as being deployed in the new VM. For this task, it will just be an HTML file with the content ```"Hello, World!"```. Visit the Packer GIthub for more examples and templates.


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
output:
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
Output:
```Bash
Resource_Name      Resource_Type
-----------------  ------------------------
myproject-vmimage  Microsoft.Compute/images
```

## TerraForm
Terraform uses 2 main files to hold its template. A main file, which we will name as ```main.tf``` and a file for variables, which we will call ```var.tf```. TerraForm templates are generated with a properietory language called HCL. HCL language uses the ```.tf``` suffix on its files.

The main file, ```main.tf```, is used to house parameters responsible for building resources.
The variables file, ```var.tf```, is used to hold variables that will be used by main file. 

_**Note:** For more information on TerraForm Template structure, please visit:_ [https://www.terraform.io/docs/providers/azurerm/index.html](https://www.terraform.io/docs/providers/azurerm/index.html)

### Resources: 

We need to build resources to meet the requirements as described in the image below:
![##### *Azure Web Server Architecture (Deny Access from Internet)*Azure WebServer Deny Internet to VMs](https://engrcog.com/wp-content/uploads/2020/09/Automate-WebServerno-bastion.jpeg)
##### *Azure Web Server Architecture (Deny Access from Internet)*

The following are resources that we would like to be provisioned .


### Variables: 


And the following variables will be used.