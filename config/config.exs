# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :kujibot,
  ecto_repos: [Kujibot.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :kujibot, KujibotWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: KujibotWeb.ErrorHTML, json: KujibotWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Kujibot.PubSub,
  live_view: [signing_salt: "BVVLdPi3"]

# This tells Tesla which HTTP client adapter to use
# for making outbound HTTP requests from the server.
config :tesla, adapter: Tesla.Adapter.Hackney

# Oban base configuration, keep completed, cancelled or discarded jobs for 1 hour
config :kujibot, Oban,
  repo: Kujibot.Repo,
  queues: [default: 10, wallet: 10],
  plugins: [{Oban.Plugins.Pruner, max_age: 3_600}]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :kujibot, Kujibot.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  kujibot: [
    args:
      ~w(js/app.ts --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.0",
  kujibot: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
