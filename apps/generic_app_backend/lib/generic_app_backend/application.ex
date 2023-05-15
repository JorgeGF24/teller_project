defmodule GenericAppBackend.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do

    # KV.Registry will simulate the database. Here we create the bucket (a key value store) for our users and accounts table
    users_table = KV.Registry.create(GenericAppBackend.DB, "users")

    # We define a test user as an example. More can be created by performing HTTP calls to the GenericAppBackend server.
    password = Safetybox.encrypt("test")
    test_user = %GenericAppBackend.User{username: "test_user", first_name: "test", last_name: "user", password: password}

    KV.Bucket.put(users_table, "test_user", test_user)

    # Start module to simulate performing http requests to banks
    HTTPoison.start

    children = [
      {Plug.Cowboy, 
        scheme: :http, 
        plug: GenericAppBackend.Router, 
        options: [port: Application.get_env(:generic_app_backend, :port)]},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GenericAppBackend.Supervisor]
    
    Supervisor.start_link(children, opts)
  end
end
