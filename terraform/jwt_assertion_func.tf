// Copyright (c) 2021 Oracle and/or its affiliates.  
//  Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "compartment_ocid" {}
variable "region" {}
variable "region_code" {}
variable "tenancy_namespace" {}
variable "repos_name" {}
variable "audience" {}
variable "clientid" {}
variable "issuer_name" {}
variable "subnet_id" {}
variable "debug_level" {}
variable "key_file_name" {}
variable "cert_file_name" {}

variable "name_prefix" {}

provider "oci" {
  tenancy_ocid     = "${var.tenancy_ocid}"
  user_ocid        = "${var.user_ocid}"
  fingerprint      = "${var.fingerprint}"
  private_key_path = "${var.private_key_path}"
  region           = "${var.region}"
  version          = "4.5.0"
}


resource "oci_functions_application" "test_application" {
  #Required
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.name_prefix}_jwtassertion_application"
  subnet_ids     = ["${var.subnet_id}"]
  config = {
     "issuer_name" = "${var.issuer_name}"
     "clientid" = "${var.clientid}"
     "audience" = "${var.audience}"
     "debug_level" = "${var.debug_level}"
     "encrypted_key" = "${oci_kms_encrypted_data.test_encrypted_key.ciphertext}"
     "encrypted_cert" = "${oci_kms_encrypted_data.test_encrypted_cert.ciphertext}"
     "kms_endpoint" = "${data.oci_kms_vault.test_vault.crypto_endpoint}"
     "kms_secret_key" = "${data.oci_kms_key.test_key.id}"
  }
}

#resource "oci_kms_vault" "test_vault" {
#	compartment_id = "${var.compartment_ocid}"
#	display_name = "${var.name_prefix}_jwtassertion_vault"
#	vault_type = "DEFAULT"
#}
data "oci_kms_vault" "test_vault" {
    #Required
    vault_id = "ocid1.vault.oc1.iad.b5sbgejmaacmc.abuwcljtj4w32etulm7cl4r72zcczvsrznjogyzuzub4c7o7zsidkmmvw6na"
}

#resource "oci_kms_key" "test_key" {
#  compartment_id      = "${var.compartment_ocid}"
#  display_name        = "${var.name_prefix}_jwtassertion_key"
#  management_endpoint = "${oci_kms_vault.test_vault.management_endpoint}"

#  key_shape {
#    algorithm = "AES"
#    length    = "16"
#  }
#}
data "oci_kms_key" "test_key" {
    #Required
    key_id = "ocid1.key.oc1.iad.b5sbgejmaacmc.abuwcljshr24bm7us77emtdclekrrl4ei5i52xqpmowlnufdotahufnjgeiq"
    management_endpoint = "https://b5sbgejmaacmc-management.kms.us-ashburn-1.oraclecloud.com"
}

resource "oci_kms_encrypted_data" "test_encrypted_key" {
    crypto_endpoint = "${data.oci_kms_vault.test_vault.crypto_endpoint}"
    key_id = "${data.oci_kms_key.test_key.id}"
    plaintext = filebase64("${var.key_file_name}")
}

resource "oci_kms_encrypted_data" "test_encrypted_cert" {
    crypto_endpoint = "${data.oci_kms_vault.test_vault.crypto_endpoint}"
    key_id = "${data.oci_kms_key.test_key.id}"
    plaintext = filebase64("${var.cert_file_name}")
}

resource "oci_functions_function" "auth_function" {
  application_id = "${oci_functions_application.test_application.id}"
  display_name   = "jwt_assertion"
  image          = "iad.ocir.io/sehubjapaciaas/oic_functions:jwt_assertion"
  memory_in_mbs  = "256"
  timeout_in_seconds = "120"
}

