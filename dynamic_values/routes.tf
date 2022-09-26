module "routes" {
  source = "./config_modules/list_to_map"
  list   = var.routes
}

locals {
  routing_table_route_list = flatten(
    [for route_table in module.routes.value : [
      for rt in(lookup(route_table, "routes", null) == null ? [] : route_table.routes) :
      merge(rt, { route_table = route_table.name, route_index = index(route_table.routes, rt) + 1 })
      ]
    ]
  )

  routing_table_route_map = {
    for route in local.routing_table_route_list :
    ("${var.prefix}-${route.route_table}-route-${route.route_index}") => route
  }
}
