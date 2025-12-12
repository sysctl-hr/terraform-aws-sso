variable "groups" {
  description = "SSO Group definition containing member accounts and their AWS Account assignments along with the permission sets on those accounts"
  type = map(object({
    members = optional(list(string), [])
    accounts = optional(map(object({
      account_id     = number
      permission_set = optional(list(string), [])
    })))
  }))
  default = {}
}

variable "permission_sets" {
  description = "Permission set configuration. By default AdministratorAccess and ReadOnlyAccess are created."
  type = map(object({
    description             = optional(string, null)
    managed_policies        = optional(list(string), [])
    custom_managed_policies = optional(list(string), [])
    inline_policy           = optional(string, null)
  }))
  default = {}
}
