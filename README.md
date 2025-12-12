# terraform-aws-sso

Due to the limitation of syncing groups from Google Workspace or Microsoft 365 when using it as an Identity Source in IAM Identity center, this module was developed in order to manually create required groups, and assign users by their username to a particular group with the necessary permissions.

In short, this moodule handles:
- IAM Identity Center group creation - when using external identnity source, option to create the group is not visible in the console, but it still works via API
- Permission Set creation
- Assignment of the existing IAM Identity Center users to the groups
- Assignment of the IAM Identity Center groups to a specific AWS account with a specific Permission Set


## Example

```terraform
module "sso" {
  source = "git@github.com:sysctl-hr/terraform-aws-sso.git"

  permission_sets = {
    "my-custom-permissions" = {
      description = "My custom permissions"
      policies = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess"
      ]
      custom_managed_policies = [
        "name-of-the-policy-in-the-destination-account"
      ]
      inline_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect   = "Allow"
          Action   = ["s3:GetObject"]
          Resource = "*"
        }]
      })
    }
  }

  groups = {
    "Administrators" = {
      members = [
        "MyUserName"
      ]
      accounts = {
        "sysctl" = {
          account_id     = "12345678901"
          permission_set = ["AdministratorAccess", "ReadOnlyAccess", ]
        }
        "sysctl-sbx" = {
          account_id     = "12345678902"
          permission_set = ["AdministratorAccess"]
        }
      }
    }
  }
}
```