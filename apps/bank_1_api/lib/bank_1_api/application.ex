defmodule Bank1API.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do

    # KV.Registry will simulate the database. Here we create the bucket (a key value store) for our accounts table
    KV.Registry.create(Bank1API.DB, "accounts")
    # Here we store user information such as username and password
    users_table = KV.Registry.create(Bank1API.DB, "users")
    n_accounts_table = KV.Registry.create(Bank1API.DB, "accounts counter")
    KV.Registry.create(Bank1API.DB, "transactions")

    # We define a test user as an example. More can be created by performing HTTP calls to the Bank1API server.
    password = Safetybox.encrypt("test")
    test_user = %Bank1API.User{username: "test_user", first_name: "test", last_name: "user", secret_answer: "purple", password: password, 
      security_status: "okay"}

    KV.Bucket.put(users_table, "test_user", test_user)
    KV.Bucket.put(n_accounts_table, "test_user", 0)

    children = [
      # Starts a worker by calling: Bank1API.Worker.start_link(arg)
      # {Bank1API.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bank1API.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
