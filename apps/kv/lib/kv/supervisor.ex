defmodule KV.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      Supervisor.child_spec({KV.Registry, name: GenericAppBackend.DB}, id: :gen_app_db),
      {DynamicSupervisor, name: GenericAppBackend.DB.BucketSupervisor, strategy: :one_for_one},
      Supervisor.child_spec({KV.Registry, name: Bank1API.DB}, id: :bank_1_db),
      {DynamicSupervisor, name: Bank1API.DB.BucketSupervisor, strategy: :one_for_one},
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end