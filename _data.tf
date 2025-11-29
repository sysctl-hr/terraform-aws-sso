data "aws_ssoadmin_instances" "main" {}
data "aws_identitystore_user" "this" {
  for_each = toset(distinct(flatten([
    for group_name, group_config in var.groups :
    lookup(group_config, "members", [])
  ])))

  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "UserName"
      attribute_value = each.key
    }
  }
}
