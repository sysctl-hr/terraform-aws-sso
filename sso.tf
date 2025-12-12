# Create group
resource "aws_identitystore_group" "this" {
  for_each          = var.groups
  display_name      = each.key
  description       = try(each.value.description, "${each.key} user group")
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
}

# Assign users to the group
resource "aws_identitystore_group_membership" "this" {
  for_each = local.group_user_matrix

  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
  group_id          = aws_identitystore_group.this[each.value.group].group_id
  member_id         = data.aws_identitystore_user.this[each.value.user].user_id
}

# Assign group to the account
resource "aws_ssoadmin_account_assignment" "this" {
  for_each = local.account_assignment_matrix

  instance_arn       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.permission_set].arn

  principal_id   = aws_identitystore_group.this[each.value.group_name].group_id
  principal_type = "GROUP"

  target_id   = each.value.account_id
  target_type = "AWS_ACCOUNT"
}

# Create PermissionSet
resource "aws_ssoadmin_permission_set" "this" {
  for_each         = merge(local.permission_sets, var.permission_sets)
  name             = each.key
  description      = try(each.value.description, null)
  instance_arn     = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  session_duration = try(each.value.session_duration, "PT4H")
}

# Assign managed Policies to a PermissionSet
resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each = local.permission_set_managed_policy_attachment

  instance_arn       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/${each.value.policy_name}"
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.permission_set].arn
}

# Assign custom managed policies to a PermissionSet - works only if the policy is already created in the target account
resource "aws_ssoadmin_customer_managed_policy_attachment" "this" {
  for_each = local.permission_set_custom_managed_policy_attachment

  instance_arn       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.permission_set].arn

  customer_managed_policy_reference {
    name = element(split("/", each.value.policy_arn), length(split("/", each.value.policy_arn)) - 1)
  }
}

# Assign inline policies to a PermissionSet
resource "aws_ssoadmin_permission_set_inline_policy" "this" {
  for_each = local.permission_set_inline_policy_attachment

  instance_arn       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.this[each.key].arn
  inline_policy      = each.value
}

# TODO: permission boundary on the permission set