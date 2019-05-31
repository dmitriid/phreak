# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :phreak,
       ecto_repos: []

config :phreak,
       :kube,
       config: "/Users/dmitrii.dimandt/.kube/config"

# Configures the endpoint
config :phreak,
       PhreakWeb.Endpoint,
       url: [
         host: "localhost"
       ],
       secret_key_base: "fVMq0PofOuw9Wd19y7w6EJveu7uuG0Nhir3RUZ6MUZ7+HpL5lIDoNsNzk4GEycqa",
       render_errors: [
         view: PhreakWeb.ErrorView,
         accepts: ~w(html json)
       ],
       pubsub: [
         name: Phreak.PubSub,
         adapter: Phoenix.PubSub.PG2
       ],
       live_view: [
         signing_salt: "SECRET_SALT"
       ],
       pubsub: [
         name: Phreak.PubSub,
         adapter: Phoenix.PubSub.PG2
       ]

# Configures Elixir's Logger
config :logger,
       :console,
       format: "$time $metadata[$level] $message\n",
       metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :phreak,
       Phreak.Scheduler,
       jobs: [
         refresh_kube: [
           schedule: {:extended, "*/15"},
           task: fn -> Phreak.Kube.refresh() end
         ]
       ],
       debug_logging: false

config :phreak, ecto_repos: [Phreak.Repo]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
