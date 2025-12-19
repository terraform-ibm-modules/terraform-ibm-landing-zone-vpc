#######################################################################################################################
# Wrapper around fully-configurable variation
#######################################################################################################################

module "vpc_da" {
    source                                        = "../fully-configurable"
    ibmcloud_api_key                              = var.ibmcloud_api_key
    existing_resource_group_name                  = var.existing_resource_group_name
    prefix                                        = var.prefix
    provider_visibility                           = "private"
    vpc_name                                      = var.vpc_name
    region                                        = var.region
    resource_tags = var.resource_tags
    access_tags = var.access_tags
    subnets = var.subnets
    network_acls = var.network_acls
    security_group_rules = var.security_group_rules
    clean_default_security_group_acl = var.clean_default_security_group_acl
    address_prefixes = var.address_prefixes
    routes = var.routes
    enable_vpc_flow_logs = var.enable_vpc_flow_logs
    skip_vpc_cos_iam_auth_policy = var.skip_vpc_cos_iam_auth_policy
    existing_cos_instance_crn                     = var.existing_cos_instance_crn
    flow_logs_cos_bucket_name = var.flow_logs_cos_bucket_name
    kms_encryption_enabled_bucket                 = true
    skip_cos_kms_iam_auth_policy                  = var.skip_cos_kms_iam_auth_policy
        management_endpoint_type_for_bucket           = "private"
        cos_bucket_class = var.cos_bucket_class
        add_bucket_name_suffix                        = var.add_bucket_name_suffix
        flow_logs_cos_bucket_archive_days = var.flow_logs_cos_bucket_archive_days
        flow_logs_cos_bucket_archive_type = var.flow_logs_cos_bucket_archive_type
        flow_logs_cos_bucket_expire_days = var.flow_logs_cos_bucket_expire_days
        flow_logs_cos_bucket_enable_object_versioning = var.flow_logs_cos_bucket_enable_object_versioning
        flow_logs_cos_bucket_enable_retention = var.flow_logs_cos_bucket_enable_retention
        flow_logs_cos_bucket_default_retention_days = var.flow_logs_cos_bucket_default_retention_days
        flow_logs_cos_bucket_maximum_retention_days = var.flow_logs_cos_bucket_maximum_retention_days
        flow_logs_cos_bucket_minimum_retention_days = var.flow_logs_cos_bucket_minimum_retention_days
        flow_logs_cos_bucket_enable_permanent_retention = var.flow_logs_cos_bucket_enable_permanent_retention
        existing_flow_logs_bucket_kms_key_crn = var.existing_flow_logs_bucket_kms_key_crn
    existing_kms_instance_crn                     = var.existing_kms_instance_crn
    kms_endpoint_type                             = "private"
    kms_key_ring_name = var.kms_key_ring_name
    kms_key_name = var.kms_key_name
    ibmcloud_kms_api_key                          = var.ibmcloud_kms_api_key
    default_network_acl_name = var.default_network_acl_name
    default_security_group_name = var.default_security_group_name
    default_routing_table_name = var.default_routing_table_name
    vpn_gateways = var.vpn_gateways
    vpe_gateway_cloud_services = var.vpe_gateway_cloud_services
    vpe_gateway_cloud_service_by_crn = var.vpe_gateway_cloud_service_by_crn
    vpe_gateway_service_endpoints = "private"
    vpe_gateway_security_group_ids = var.vpe_gateway_security_group_ids
    vpe_gateway_reserved_ips = var.vpe_gateway_reserved_ips 
}