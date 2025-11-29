locals {
  permission_sets = {
    "AdministratorAccess" = {
      description = "Full administrator level access"
      managed_policies = [
        "AdministratorAccess",
        "job-function/Billing"
      ]
    }
    "ReadOnlyAccess" = {
      description      = "ReadOnly level access"
      session_duration = "PT8H"
      managed_policies = [
        "ReadOnlyAccess"
      ]
    }
  }

  # Craft a complex object for mapping users to group
  group_user_matrix = {
    for pair in flatten([
      for group_name, group_config in var.groups : [
        for user in group_config.members : {
          key   = "${group_name}-${user}"
          group = group_name
          user  = user
        }
      ]
      ]) : pair.key => {
      group = pair.group
      user  = pair.user
    }
  }

  # Craft a complex object for assigning group with a permission sets to an AWS account
  account_assignment_matrix = merge([
    for group_name, group_config in var.groups : {
      for pair in flatten([
        for account_name, account_config in lookup(group_config, "accounts", {}) : [
          for permission_set in account_config.permission_set : {
            key            = "${group_name}-${account_name}-${permission_set}"
            group_name     = group_name
            account_name   = account_name
            account_id     = account_config.account_id
            permission_set = permission_set
          }
        ]
      ]) : pair.key => pair
    }
  ]...)

  # Craft a complex object for adding managed policies to a permisison set of permission_set/managed_policy
  permission_set_managed_policy_attachment = {
    for pair in flatten([
      for permission_set_name, permission_set_config in merge(local.permission_sets, var.permission_sets) : [
        for policy_name in lookup(permission_set_config, "managed_policies", []) : {
          key            = "${permission_set_name}-${policy_name}"
          permission_set = permission_set_name
          policy_name    = policy_name
        }
      ]
      ]) : pair.key => {
      permission_set = pair.permission_set
      policy_name    = pair.policy_name
    }
  }
}
