##############################################################################
# Address Prefixes Tests
##############################################################################

locals {
  # tflint-ignore: terraform_unused_declarations
  assert_address_prefix_0_has_correct_name = regex("ut-zone-1-1", module.unit_tests.address_prefixes[0].name)
  # tflint-ignore: terraform_unused_declarations
  assert_address_prefix_0_has_correct_address = regex("1", module.unit_tests.address_prefixes[0].cidr)
  # tflint-ignore: terraform_unused_declarations
  assert_address_prefix_0_has_correct_zone = regex("us-south-1", module.unit_tests.address_prefixes[0].zone)
  # tflint-ignore: terraform_unused_declarations
  assert_address_prefixes_correct_length = regex("2", tostring(length(module.unit_tests.address_prefixes)))
}

##############################################################################

##############################################################################
# Routes Tests
##############################################################################

locals {
  # tflint-ignore: terraform_unused_declarations
  assert_route_key_exists = lookup(module.unit_tests.routes, "test-route")
  # tflint-ignore: terraform_unused_declarations
  assert_route_has_route_table = lookup(module.unit_tests.routing_table_route_map, "ut-test-route-route-1")
}

##############################################################################

##############################################################################
# Public Gateway Tests
##############################################################################

locals {
  # tflint-ignore: terraform_unused_declarations
  assert_null_gateways_not_returned = regex("2", tostring(length(keys(module.unit_tests.use_public_gateways))))
  # tflint-ignore: terraform_unused_declarations
  assert_zone_found_in_map = lookup(module.unit_tests.use_public_gateways, "zone-1")
  # tflint-ignore: terraform_unused_declarations
  assert_zone_correct_name = regex("us-south-1", module.unit_tests.use_public_gateways["zone-1"])
}

##############################################################################

##############################################################################
# Security Group Rules Test
##############################################################################

locals {
  # tflint-ignore: terraform_unused_declarations
  assert_rule_exists_in_map = lookup(module.unit_tests.security_group_rules, "test-rule")
  # tflint-ignore: terraform_unused_declarations
  assert_rule_has_correct_field = regex("test-rule", module.unit_tests.security_group_rules["test-rule"].name)
}

##############################################################################

##############################################################################
# Network ACL Tests
##############################################################################

locals {
  # tflint-ignore: terraform_unused_declarations
  assert_acl_exists_in_map = lookup(module.unit_tests.acl_map, "acl")
  # tflint-ignore: terraform_unused_declarations
  assert_cluster_rule_exists_in_position_0 = regex("roks-create-worker-nodes-inbound", module.unit_tests.acl_map["acl"].rules[0].name)
  # tflint-ignore: terraform_unused_declarations
  assert_cluster_rule_uses_network_cidr = regex("1.2.3.4/5", module.unit_tests.acl_map["acl"].rules[0].destination)
  # tflint-ignore: terraform_unused_declarations
  assert_acl_rule_exists_in_last_position = regex("test-rule", module.unit_tests.acl_map["acl"].rules[length(module.unit_tests.acl_map["acl"].rules) - 1].name)
  # tflint-ignore: terraform_unused_declarations
  assert_length_of_rules_cluster_rules_plus_1 = regex("9", tostring(length(module.unit_tests.acl_map["acl"].rules)))
}

##############################################################################

##############################################################################
# Subnet Tests
##############################################################################

locals {
  # tflint-ignore: terraform_unused_declarations
  assert_subnets_list_0_has_correct_prefix_name = regex("ut-subnet-1", module.unit_tests.subnet_list[0].prefix_name)
  # tflint-ignore: terraform_unused_declarations
  assert_subnets_list_0_has_correct_zone = regex("1", module.unit_tests.subnet_list[0].zone)
  # tflint-ignore: terraform_unused_declarations
  assert_subnets_list_0_has_correct_zone_name = regex("us-south-1", module.unit_tests.subnet_list[0].zone_name)
  # tflint-ignore: terraform_unused_declarations
  assert_subnets_list_0_has_correct_count = regex("1", module.unit_tests.subnet_list[0].count)
  # tflint-ignore: terraform_unused_declarations
  assert_subnets_list_0_has_correct_public_gateway = regex("pgw1", module.unit_tests.subnet_list[0].public_gateway)
  # tflint-ignore: terraform_unused_declarations
  assert_subnets_list_1_has_correct_public_gateway = regex("null", lookup(module.unit_tests.subnet_list[1], "public_gateway", null) == null ? "null" : "error")
  # tflint-ignore: terraform_unused_declarations
  assert_subnets_list_1_has_correct_count = regex("2", module.unit_tests.subnet_list[1].count)
  # tflint-ignore: terraform_unused_declarations
  assert_even_if_gateway_true_no_pgw_provision_zone_return_null = regex("null", lookup(module.unit_tests.subnet_list[2], "public_gateway", null) == null ? "null" : "error")
  # tflint-ignore: terraform_unused_declarations
  assert_subnet_exists_in_map = lookup(module.unit_tests.subnet_map, "ut-subnet-1")
}

##############################################################################
