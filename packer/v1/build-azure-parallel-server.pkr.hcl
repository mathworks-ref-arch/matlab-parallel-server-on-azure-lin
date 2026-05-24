# Copyright 2024-2026 The MathWorks, Inc.

packer {
  required_plugins {
    azure = {
      source = "github.com/hashicorp/azure"
      version = "~> 2"
    }
  }
}

# The following variables may have different values across MATLAB releases.
# MathWorks recommends that you modify them via the configuration file specific to each release.
# To see the release-specific values, open the configuration file
# in the /packer/v1/release-config/ folder.
variable "PRODUCTS" {
  type        = string
  description = "Target products to install in the machine image, e.g. MATLAB MATLAB_Parallel_Server."
  default     = "5G_Toolbox AUTOSAR_Blockset Aerospace_Blockset Aerospace_Toolbox Antenna_Toolbox Audio_Toolbox Automated_Driving_Toolbox Bioinformatics_Toolbox Bluetooth_Toolbox C2000_Microcontroller_Blockset Communications_Toolbox Computer_Vision_Toolbox Control_System_Toolbox Curve_Fitting_Toolbox DDS_Blockset DSP_HDL_Toolbox DSP_System_Toolbox Database_Toolbox Datafeed_Toolbox Deep_Learning_HDL_Toolbox Deep_Learning_Toolbox Econometrics_Toolbox Embedded_Coder Financial_Instruments_Toolbox Financial_Toolbox Fixed-Point_Designer Fuzzy_Logic_Toolbox GPU_Coder Global_Optimization_Toolbox HDL_Coder HDL_Verifier Image_Acquisition_Toolbox Image_Processing_Toolbox Industrial_Communication_Toolbox Instrument_Control_Toolbox LTE_Toolbox Lidar_Toolbox MATLAB MATLAB_Coder MATLAB_Compiler MATLAB_Compiler_SDK MATLAB_Parallel_Server MATLAB_Report_Generator MATLAB_Test MATLAB_Web_App_Server Mapping_Toolbox Medical_Imaging_Toolbox Mixed-Signal_Blockset Model_Predictive_Control_Toolbox Motor_Control_Blockset Navigation_Toolbox Optimization_Toolbox Parallel_Computing_Toolbox Partial_Differential_Equation_Toolbox Phased_Array_System_Toolbox Powertrain_Blockset Predictive_Maintenance_Toolbox RF_Blockset RF_PCB_Toolbox RF_Toolbox ROS_Toolbox Radar_Toolbox Reinforcement_Learning_Toolbox Requirements_Toolbox Risk_Management_Toolbox Robotics_System_Toolbox Robust_Control_Toolbox Satellite_Communications_Toolbox Sensor_Fusion_and_Tracking_Toolbox SerDes_Toolbox Signal_Integrity_Toolbox Signal_Processing_Toolbox SimBiology SimEvents Simscape Simscape_Battery Simscape_Driveline Simscape_Electrical Simscape_Fluids Simscape_Multibody Simulink Simulink_3D_Animation Simulink_Check Simulink_Coder Simulink_Compiler Simulink_Control_Design Simulink_Coverage Simulink_Design_Optimization Simulink_Design_Verifier Simulink_Desktop_Real-Time Simulink_Fault_Analyzer Simulink_PLC_Coder Simulink_Real-Time Simulink_Report_Generator Simulink_Test SoC_Blockset Stateflow Statistics_and_Machine_Learning_Toolbox Symbolic_Math_Toolbox System_Composer System_Identification_Toolbox Text_Analytics_Toolbox UAV_Toolbox Vehicle_Dynamics_Blockset Vehicle_Network_Toolbox Vision_HDL_Toolbox WLAN_Toolbox Wavelet_Toolbox Wireless_HDL_Toolbox Wireless_Testbench Wireless_Network_Toolbox Simulink_FMU_Builder Raspberry_Pi_Blockset STM32_Microcontroller_Blockset"
}

variable "SPKGS" {
  type        = string
  description = "Target MATLAB support packages to install in the machine image."
  default     = "Deep_Learning_Toolbox_Model_for_AlexNet_Network Deep_Learning_Toolbox_Model_for_EfficientNet-b0_Network Deep_Learning_Toolbox_Model_for_GoogLeNet_Network Deep_Learning_Toolbox_Model_for_ResNet-101_Network Deep_Learning_Toolbox_Model_for_ResNet-18_Network Deep_Learning_Toolbox_Model_for_ResNet-50_Network Deep_Learning_Toolbox_Model_for_Inception-ResNet-v2_Network Deep_Learning_Toolbox_Model_for_Inception-v3_Network Deep_Learning_Toolbox_Model_for_DenseNet-201_Network Deep_Learning_Toolbox_Model_for_Xception_Network Deep_Learning_Toolbox_Model_for_MobileNet-v2_Network Deep_Learning_Toolbox_Model_for_Places365-GoogLeNet_Network Deep_Learning_Toolbox_Model_for_NASNet-Large_Network Deep_Learning_Toolbox_Model_for_NASNet-Mobile_Network Deep_Learning_Toolbox_Model_for_ShuffleNet_Network Deep_Learning_Toolbox_Model_for_DarkNet-19_Network Deep_Learning_Toolbox_Model_for_DarkNet-53_Network Deep_Learning_Toolbox_Model_for_VGG-16_Network Deep_Learning_Toolbox_Model_for_VGG-19_Network"
}

variable "POLYSPACE_PRODUCTS" {
  type        = string
  description = "Target product names for Polyspace"
  default     = "Polyspace_Bug_Finder_Server Polyspace_Code_Prover_Server"
}

variable "RELEASE" {
  type        = string
  default     = "R2026a"
  description = "Target MATLAB release to install in the machine image, must start with \"R\"."

  validation {
    condition     = can(regex("^R20[0-9][0-9](a|b)(U[0-9])?$", var.RELEASE))
    error_message = "The RELEASE value must be a valid MATLAB release, starting with \"R\"."
  }
}

variable "MATLAB_ROOT" {
  type        = string
  default     = "/usr/local/matlab"
  description = "Target path that will contain MATLAB installation."
}

variable "POLYSPACE_ROOT" {
  type        = string
  default     = "/usr/local/polyspace"
  description = "Target path that will contain Polyspace installation."
}

variable "MSA_URL" {
  type        = string
  description = "URL pointing to a valid MATLAB Startup Accelerator file. If left unset, a default URL will be constructed based on the RELEASE variable."
  default     = null
}

variable "MATLAB_SOURCE_LOCATION" {
  type        = string
  default     = ""
  description = "Optional parameter which holds the location from which to install MATLAB and toolboxes, for use with the mpm --source option."
}

variable "SPKG_SOURCE_LOCATION" {
  type        = string
  default     = ""
  description = "Optional parameter which holds the location from which to install MATLAB Support Packages, for use with the mpm --source option."
}

variable "BUILD_SCRIPTS" {
  type = list(string)
  default = [
    "install-dependencies.sh",
    "install-matlab-dependencies-ubuntu.sh",
    "install-startup-scripts.sh",
    "install-runtime-scripts.sh",
    "install-shutdown-scripts.sh",
    "install-matlab.sh",
    "install-polypsace.sh",
    "setup-spkg-root.sh",
    "install-support-packages.sh",
    "install-jre.sh",
    "setup-startup-accelerator.sh"
  ]
  description = "The list of installation scripts Packer will use when building the image."
}

variable "STARTUP_SCRIPTS" {
  type = list(string)
  default = [
    ".env",
    "00_setup-dns-search-suffix.sh",
    "10_setup-machine.sh",
    "20_setup-disks.sh",
    "30_setup-matlab.sh",
    "40_warmup-matlab.sh",
    "50_edit-mjs-def.sh",
    "60_sync-mjs-files.sh",
    "70_setup-shared-storage.sh",
    "80_start-mjs.sh",
    "90_add-spot-instance-monitoring.sh",
    "95_tag-on-mjs-running.sh"
  ]
  description = "The list of startup scripts Packer will copy to the remote machine image builder, which can be used during resource group creation."
}

variable "NVIDIA_DRIVER_VERSION" {
  type        = string
  default     = "590"
  description = "The NVIDIA Drivers version to install in the resultant image."
}

variable "TENANT_ID" {
  type        = string
  description = "The Microsoft Entra ID tenant identifier with which your client_id and subscription_id are associated."
  sensitive   = true
}

variable "CLIENT_ID" {
  type        = string
  description = "The Microsoft Entra ID service principal associated with your builder."
  sensitive   = true
}

variable "CLIENT_SECRET" {
  type        = string
  description = "The password or secret for your service principal."
  sensitive   = true
}

variable "USER_ASSIGNED_MANAGED_IDENTITIES" {
  type        = list(string)
  default     = []
  description = "List of resource IDs of user-assigned managed identities to assign to the Packer builder Virtual Machine."
  sensitive   = true
}

variable "AZURE_KEY_VAULT" {
  type        = string
  default     = ""
  description = "Optional parameter to enter an Azure Key Vault name that can be used to store or retrieve sensitive information during Packer builds."
  sensitive   = true
}

variable "RESOURCE_GROUP_NAME" {
  type        = string
  default     = ""
  description = "Resource group under which the final artifact will be stored"
}

variable "SUBSCRIPTION_ID" {
  type        = string
  description = "Subscription under which the build will be performed."
  sensitive   = true
}

variable "AZURE_TAGS" {
  type = map(string)
  default = {
    Name  = "Packer Build"
    Build = "MATLAB Parallel Server"
    Type  = "Linux"
  }
  description = "The tags Packer applies to every deployed resource."
}

variable "MANIFEST_OUTPUT_FILE" {
  type        = string
  default     = "manifest.json"
  description = "The name of the resultant manifest file."
}

variable "IMAGE_PUBLISHER" {
  type        = string
  default     = "Canonical"
  description = "The publisher of the base image used for customization."
}

variable "IMAGE_OFFER" {
  type        = string
  default     = "ubuntu-24_04-lts"
  description = "The offer of the base image used for customization."
}

variable "IMAGE_SKU" {
  type        = string
  default     = "server-gen1"
  description = "Version of the base image used for customization."
}

variable "VM_SIZE" {
  type        = string
  default     = "Standard_NC4as_T4_v3"
  description = "Size of base Azure VM to be used for the Packer build."

}

# Optional networking configuration for the Packer Builder VM
variable "VIRTUAL_NETWORK_NAME" {
  type        = string
  default     = ""
  description = "(Optional) The name of the virtual network to use for the Packer builder VM."
}

variable "SUBNET_NAME" {
  type        = string
  default     = ""
  description = "(Optional) The name of the subnet within the virtual network to use for the Packer builder VM."
}

variable "VIRTUAL_NETWORK_RESOURCE_GROUP" {
  type        = string
  default     = ""
  description = "(Optional) Name of the resource group containing the virtual network to use for the Packer builder VM."
}

# Optional SSH Bastion host configuration
variable "SSH_BASTION_HOST" {
  type        = string
  default     = ""
  description = "(Optional) A bastion host to use for the actual SSH connection."
}

variable "SSH_BASTION_USERNAME" {
  type        = string
  default     = ""
  description = "(Optional) The username to use when connecting to the bastion host via SSH."
}

variable "SSH_BASTION_PASSWORD" {
  type        = string
  default     = ""
  description = "(Optional) The password to use when connecting to the bastion host via SSH."
}

# Set up local variables used by provisioners.
locals {
  image_uuid            = uuidv4()
  build_scripts         = [for s in var.BUILD_SCRIPTS : format("build/%s", s)]
  startup_scripts       = [for s in var.STARTUP_SCRIPTS : format("startup/%s", s)]
  # This local variable decides which URL to use.
  # If var.MSA_URL is not null (meaning the user provided an override), use that value.
  # Otherwise, construct the URL using var.RELEASE.
  effective_msa_url = var.MSA_URL != null ? var.MSA_URL : "https://raw.githubusercontent.com/mathworks-ref-arch/iac-building-blocks/refs/heads/main/common/artifacts/msa/${var.RELEASE}/Linux/msa.ini"
}

# Configure the AZURE instance that is used to build the machine image.
source "azure-arm" "Image_Builder" {
  communicator = "ssh"
  ssh_username = "ubuntu"

  # Optional configuration for SSH Bastion Host setup
  ssh_bastion_host     = "${var.SSH_BASTION_HOST}"
  ssh_bastion_username = "${var.SSH_BASTION_USERNAME}"
  ssh_bastion_password = "${var.SSH_BASTION_PASSWORD}"

  # Optional networking setup for the Packer Builder VM
  virtual_network_name                = "${var.VIRTUAL_NETWORK_NAME}"
  virtual_network_resource_group_name = "${var.VIRTUAL_NETWORK_RESOURCE_GROUP}"
  virtual_network_subnet_name         = "${var.SUBNET_NAME}"

  # Assigning a Public IP to the Packer Builder VM for internet connectivity
  private_virtual_network_with_public_ip = "true"
  azure_tags                             = "${var.AZURE_TAGS}"
  client_id                              = "${var.CLIENT_ID}"
  client_secret                          = "${var.CLIENT_SECRET}"
  subscription_id                        = "${var.SUBSCRIPTION_ID}"
  tenant_id                              = "${var.TENANT_ID}"
  user_assigned_managed_identities       = "${var.USER_ASSIGNED_MANAGED_IDENTITIES}"
  image_offer                            = "${var.IMAGE_OFFER}"
  image_publisher                        = "${var.IMAGE_PUBLISHER}"
  image_sku                              = "${var.IMAGE_SKU}"
  location                               = "East US"
  managed_image_resource_group_name      = "${var.RESOURCE_GROUP_NAME}"
  managed_image_name                     = "parallelserverlin-${var.RELEASE}-${local.image_uuid}"
  os_type                                = "Linux"
  os_disk_size_gb                        = "128"
  vm_size                                = "${var.VM_SIZE}"
}

# Build the machine image.
build {
  sources = ["source.azure-arm.Image_Builder"]

  provisioner "shell" {
    inline = ["/usr/bin/cloud-init status --wait"]
  }

  provisioner "shell" {
    inline = ["mkdir /tmp/startup"]
  }

  provisioner "file" {
    destination = "/var/tmp/"
    source      = "build/config"
  }

  provisioner "file" {
    destination = "/tmp/startup/"
    sources     = "${local.startup_scripts}"
  }

  provisioner "file" {
    destination = "/tmp/"
    source      = "runtime"
  }

  provisioner "file" {
    destination = "/tmp"
    source      = "shutdown"
  }

  provisioner "shell" {
    environment_vars = [
      "RELEASE=${var.RELEASE}",
      "PRODUCTS=${var.PRODUCTS}",
      "SPKGS=${var.SPKGS}",
      "POLYSPACE_PRODUCTS=${var.POLYSPACE_PRODUCTS}",
      "NVIDIA_DRIVER_VERSION=${var.NVIDIA_DRIVER_VERSION}",
      "MATLAB_ROOT=${var.MATLAB_ROOT}",
      "POLYSPACE_ROOT=${var.POLYSPACE_ROOT}",
      "MSA_URL=${local.effective_msa_url}",
      "MATLAB_SOURCE_LOCATION=${var.MATLAB_SOURCE_LOCATION}",
      "SPKG_SOURCE_LOCATION=${var.SPKG_SOURCE_LOCATION}",
      "AZURE_KEY_VAULT=${var.AZURE_KEY_VAULT}"
    ]
    expect_disconnect = true
    scripts           = "${local.build_scripts}"
  }

  provisioner "shell" {
    scripts = [
    "build/cleanup.sh"]
  }

  post-processor "manifest" {
    output     = "${var.MANIFEST_OUTPUT_FILE}"
    strip_path = true
    custom_data = {
      release                           = "MATLAB ${var.RELEASE}"
      specified_products                = "${var.PRODUCTS}"
      specified_spkgs                   = "${var.SPKGS}"
      specified_polyspace_products      = "${var.POLYSPACE_PRODUCTS}"
      build_scripts                     = join(", ", "${var.BUILD_SCRIPTS}")
      managed_image_resource_group_name = "${var.RESOURCE_GROUP_NAME}"
    }
  }
}
