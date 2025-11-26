# In this file, we load production configuration and secrets
# from environment variables.
import Config

secret_key_base =
  System.fetch_env!("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

zclassicd_hostname =
  System.fetch_env!("ZCLASSICD_HOSTNAME") ||
    raise """
    environment variable ZCLASSICD_HOSTNAME is missing
    """

zclassicd_port =
  System.fetch_env!("ZCLASSICD_PORT") ||
    raise """
    environment variable ZCLASSICD_PORT is missing
    """

zclassicd_username =
  System.fetch_env!("ZCLASSICD_USERNAME") ||
    raise """
    environment variable ZCLASSICD_USERNAME is missing
    """

zclassicd_password =
  System.fetch_env!("ZCLASSICD_PASSWORD") ||
    raise """
    environment variable ZCLASSICD_PASSWORD is missing
    """

explorer_hostname =
  System.fetch_env!("EXPLORER_HOSTNAME") ||
    raise """
    environment variable EXPLORER_HOSTNAME is missing
    """

vk_cpus =
  System.fetch_env!("VK_CPUS") ||
    raise """
    environment variable VK_CPUS is missing
    """

vk_mem =
  System.fetch_env!("VK_MEM") ||
    raise """
    environment variable VK_MEM is missing
    """

vk_runnner_image =
  System.fetch_env!("VK_RUNNER_IMAGE") ||
    raise """
    environment variable VK_RUNNER_IMAGE is missing
    """

zclassic_network =
  System.fetch_env!("ZCLASSIC_NETWORK") ||
    raise """
    environment variable ZCLASSIC_NETWORK is missing
    """

config :zclassic_explorer, ZclassicExplorerWeb.Endpoint,
  url: [
    host: explorer_hostname,
    port: String.to_integer(System.get_env("EXPLORER_PORT") || "443"),
    scheme: System.get_env("EXPLORER_SCHEME") || "https"
  ],
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6], compress: true]
  ],
  secret_key_base: secret_key_base,
  # add all the domain names that will be routed to this application ( including TOR Onion Service)
  check_origin: [
    "http://127.0.0.1:4000",
    "//zclassicexplorer.com",
    "//testnet.zclassicexplorer.com"
  ]

config :zclassic_explorer, Zclassicex,
  zclassicd_hostname: zclassicd_hostname,
  zclassicd_port: zclassicd_port,
  zclassicd_username: zclassicd_username,
  zclassicd_password: zclassicd_password,
  vk_cpus: vk_cpus,
  vk_mem: vk_mem,
  vk_runnner_image: vk_runnner_image,
  zclassic_network: zclassic_network

config :zclassic_explorer, ZclassicExplorerWeb.Endpoint, server: true
