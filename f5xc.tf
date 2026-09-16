# ##########################################
# #  _____ ______  ______
# # |  ___| ___\ \/ / ___|
# # | |_  |___ \\  / |
# # |  _|  ___) /  \ |___
# # |_|   |____/_/\_\____|
# #
# ##########################################

locals {

  # student_name = "tsanghan" -> from locals.tf
  namespace = local.student_name

  lb_info = {
    name        = "${local.student_name}-http-lb"
    namespace   = local.namespace
    description = "${local.student_name}-lb managed by ${local.managed_by}"
    domains     = ["${local.student_name}.dev.learnf5.cloud"]
    port        = 443
  }

  pool_info = {
    name                   = "${local.student_name}-pool"
    namespace              = local.namespace
    description            = "${local.student_name}-pool managed by ${local.managed_by}"
    weight                 = 1
    priority               = 1
    port                   = 80
    loadbalancer_algorithm = ["ROUND_ROBIN"]
    endpoint_selection     = ["LOCAL_PREFERRED"]
  }

  hc_info = {
    name                = "${local.student_name}-hc"
    namespace           = local.namespace
    description         = "${local.student_name}-hc managed by ${local.managed_by}"
    timeout             = 3
    interval            = 15
    unhealthy_threshold = 1
    healthy_threshold   = 3
    health_check_path   = "/"
  }

  vsite_info = {
    name        = "${local.student_name}-vsite"
    namespace   = "shared"
    description = "${local.student_name}-vsite managed by ${local.managed_by}"

  }

  vk8s_info = {
    name              = "${local.student_name}-vk8s"
    namespace         = local.namespace
    description       = "${local.student_name}-vk8s managed by ${local.managed_by}"
    vk8s_service_name = "boutique-frontend.${local.namespace}"

  }

}

# ##########################################
# #  _ __   __ _ _ __ ___   ___  ___ _ __   __ _  ___ ___
# # | '_ \ / _` | '_ ` _ \ / _ \/ __| '_ \ / _` |/ __/ _ \
# # | | | | (_| | | | | | |  __/\__ \ |_) | (_| | (_|  __/
# # |_| |_|\__,_|_| |_| |_|\___||___/ .__/ \__,_|\___\___|
# #                                 |_|
# #
# ##########################################

# # resource "f5xc_namespace" "this" {
# #   name = local.student_name
# # }

# ##########################################
# #  ____  __  __ ____       ____
# # / ___||  \/  / ___|_   _|___ \
# # \___ \| |\/| \___ \ \ / / __) |
# #  ___) | |  | |___) \ V / / __/
# # |____/|_|  |_|____/ \_/ |_____|
# #
# ##########################################

resource "f5xc_securemesh_site_v2" "this" {
  name      = "${local.student_name}-smsv2"
  namespace = "system"

  labels = merge(
    local.common_tags,
    {
      "${local.student_name}-key" = "${local.student_name}-value"
    }
  )

  annotations = {
    owner = local.student_name
  }

  blocked_services_choice = {
    block_all_services = true
  }

  provider_choice = {
    aws = {
      orchestration_choice = {
        not_managed = {}
      }
    }
  }

  logs_receiver_choice = {
    logs_streaming_disabled = true
  }

  lifecycle {
    ignore_changes = [labels]
  }
}

# resource "time_sleep" "wait" {
#   create_duration  = "5s"
#   destroy_duration = "5s"

#   depends_on = [f5xc_securemesh_site_v2.this]
# }

resource "f5xc_token" "this" {
  name      = "${local.student_name}-smsv2"
  namespace = "system"
  type      = ["JWT"]
  site_name = "${local.student_name}-smsv2"
  timeouts = {
    create = "1m"
  }
  # depends_on = [f5xc_securemesh_site_v2.this, time_sleep.wait]
  depends_on = [f5xc_securemesh_site_v2.this]
}

# ##########################################
# #  _     ____
# # | |   | __ )
# # | |   |  _ \
# # | |___| |_) |
# # |_____|____/
# #
# ##########################################

resource "f5xc_http_loadbalancer" "this" {
  name        = local.lb_info["name"]
  namespace   = local.lb_info["namespace"]
  description = local.lb_info["description"]
  domains     = local.lb_info["domains"]

  labels = {
    "${local.student_name}-key" = "${local.student_name}-value"
  }

  annotations = {
    owner = local.student_name
  }

  loadbalancer_type_choice = {
    https_auto_cert = {
      add_hsts      = true
      http_redirect = true
      port_choice = {
        port = local.lb_info["port"]
      }
      mtls_choice = {
        no_mtls = true
      }
      path_normalize_choice = {
        enable_path_normalize = true
      }
    }
  }

  advertise_choice = {
    advertise_on_public_default_vip = true
  }

  default_route_pools = [
    {
      pool_choice = {
        pool = {
          name      = f5xc_origin_pool.this.name
          namespace = f5xc_origin_pool.this.namespace
        }
      }
      weight   = local.pool_info["weight"]
      priority = local.pool_info["priority"]
    }
  ]

  waf_choice = {
    disable_waf = true
  }

  challenge_type_choice = {
    no_challenge = true
  }

  user_id_choice = {
    user_id_client_ip = true
  }

  rate_limit_choice = {
    disable_rate_limit = true
  }

  service_policy_choice = {
    no_service_policies = true
  }
  hash_policy_choice = {
    round_robin = true
  }

  trust_client_ip_headers_choice = {
    disable_trust_client_ip_headers = true
  }

  malicious_user_detection_choice = {
    disable_malicious_user_detection = true
  }

  api_discovery_choice = {
    disable_api_discovery = true
  }

  bot_defense_choice = {
    disable_bot_defense = true
  }

  api_definition_choice = {
    disable_api_definition = true
  }

  sensitive_data_policy_choice = {
    default_sensitive_data_policy = true
  }

  api_testing_choice = {
    disable_api_testing = true
  }

  threat_mesh_choice = {
    disable_threat_mesh = true
  }

  malware_protection_choice = {
    disable_malware_protection = true
  }

  lifecycle {
    ignore_changes = [labels]
  }
}

##########################################
#   ___  ____
#  / _ \|  _ \
# | | | | |_) |
# | |_| |  __/
#  \___/|_|
#
##########################################

resource "f5xc_origin_pool" "this" {
  name                   = local.pool_info["name"]
  namespace              = local.pool_info["namespace"]
  description            = local.pool_info["description"]
  loadbalancer_algorithm = local.pool_info["loadbalancer_algorithm"]
  endpoint_selection     = local.pool_info["endpoint_selection"]

  labels = {
    "${local.student_name}-key" = "${local.student_name}-value"
  }

  annotations = {
    owner = local.student_name
  }

  port_choice = {
    port = local.pool_info["port"]
  }

  tls_choice = {
    no_tls = true
  }

  upstream_conn_pool_reuse_type = {
    map_downstream_to_upstream_conn_pool_type_choice = {
      disable_conn_pool_reuse = true
    }
  }

  origin_servers = [
    {
      choice = {
        k8s_service = {
          network_choice = {
            vk8s_networks = true
          }
          service_info_choice = {
            service_name = "${local.vk8s_info["vk8s_service_name"]}"
          }
          site_locator = {
            choice = {
              virtual_site = {
                name      = local.vsite_info["name"]
                namespace = local.student_name
              }
            }
          }
        }
      }
    }
  ]

  healthcheck = [
    {
      name      = f5xc_healthcheck.this.name
      namespace = local.hc_info["namespace"]
    }
  ]

  lifecycle {
    ignore_changes = [labels]
  }
}

##########################################
#  _   _  ____
# | | | |/ ___|
# | |_| | |
# |  _  | |___
# |_| |_|\____|
#
##########################################

resource "f5xc_healthcheck" "this" {
  name        = local.hc_info["name"]
  namespace   = local.hc_info["namespace"]
  description = local.hc_info["description"]

  labels = {
    "${local.student_name}-key" = "${local.student_name}-value"
  }

  annotations = {
    owner = local.student_name
  }

  timeout             = local.hc_info["timeout"]
  interval            = local.hc_info["interval"]
  unhealthy_threshold = local.hc_info["unhealthy_threshold"]
  healthy_threshold   = local.hc_info["healthy_threshold"]

  health_check_choice = {
    http_health_check = {
      host_header_choice = {
        use_origin_server_name = true
      }
      path = local.hc_info["health_check_path"]
    }
    request_headers_to_remove = ["User-Agent"]
    use_http2                 = false
    expected_status_codes     = ["200"]
  }

  lifecycle {
    ignore_changes = [labels]
  }
}

##########################################
#            _ _
# __   _____(_) |_ ___
# \ \ / / __| | __/ _ \
#  \ V /\__ \ | ||  __/
#   \_/ |___/_|\__\___|
#
##########################################

resource "f5xc_virtual_site" "this" {
  name        = local.vsite_info["name"]
  namespace   = local.vsite_info["namespace"]
  description = local.vsite_info["description"]

  labels = {
    "${local.student_name}-key" = "${local.student_name}-value"
  }

  annotations = {
    owner = local.student_name
  }

  site_selector = {
    expressions = ["${local.student_name}-key in (${local.student_name}-value)"]
  }

  site_type = ["CUSTOMER_EDGE"]

  lifecycle {
    ignore_changes = [labels]
  }
}

##########################################
#        _    ___
# __   _| | _( _ ) ___
# \ \ / / |/ / _ \/ __|
#  \ V /|   < (_) \__ \
#   \_/ |_|\_\___/|___/
#
##########################################

resource "f5xc_virtual_k8s" "this" {
  name        = local.vk8s_info["name"]
  namespace   = local.vk8s_info["namespace"]
  description = local.vk8s_info["description"]

  labels = {
    "${local.student_name}-key" = "${local.student_name}-value"
  }

  annotations = {
    owner = local.student_name
  }

  service_isolation_choice = {
    disabled = true
  }

  lifecycle {
    ignore_changes = [labels]
  }
}