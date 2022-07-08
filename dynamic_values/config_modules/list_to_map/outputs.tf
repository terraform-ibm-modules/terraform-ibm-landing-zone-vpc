##############################################################################
# Output
##############################################################################

output "value" {
  description = "List converted into map"
  value = {
    for item in var.list :
    ("${var.prefix == "" ? "" : "${var.prefix}-"}${item[var.key_name_field]}") =>
    item if(
      var.lookup_field == null                                                             # If not looking up
      ? true                                                                               # true
      : can(regex(var.lookup_value_regex, tostring(lookup(item, var.lookup_field, null)))) # Otherwise match regex
    )
  }
}

##############################################################################
