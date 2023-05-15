defmodule GenericAppBackend.Account do
	@enforce_keys [:institution_name, :username]
    defstruct [:institution_name, :account_id, :username, status: "open", extra_info: %{}]

    
    defimpl Jason.Encoder do
      @impl Jason.Encoder 
      def encode(value, opts) do
         Jason.Encode.map(%{institution_name: Map.get(value, :institution_name), account_id: Map.get(value, :account_id), 
         username: Map.get(value, :username), status: Map.get(value, :status)}, opts)
      end
   end
end