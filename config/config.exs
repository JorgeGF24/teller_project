# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#

config :generic_app_backend, GenericAppBackend.Guardian,
      issuer: "generic_app_backend",
      secret_key: "m82kv6Obuoi0yCcq82j5JVm3S6WTNw6mSNvLh8uj65+/hGAqe5HLePYezDPU0cHI"

config :generic_app_backend, port: 8080

config :bank_1_api, Bank1API.Guardian,
      issuer: "bank_1_api",
      secret_key: "rpKr31MOSX0ft8vB4eYNBlGeRZc1JRXAkCQuSi+smW8m80gtCsaws6OTUWVx9+L3"