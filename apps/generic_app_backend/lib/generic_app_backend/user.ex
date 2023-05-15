defmodule GenericAppBackend.User do
	@enforce_keys [:first_name, :last_name, :username]
    defstruct [:first_name, :last_name, :username, :password, security_tokens: %{}, accounts: []]

    # Banks is a list of BankInfo structs

    defimpl Jason.Encoder do
      @impl Jason.Encoder 
      def encode(value, opts) do
         Jason.Encode.map(%{first_name: Map.get(value, :first_name), last_name: Map.get(value, :last_name), username: Map.get(value, :username),
                            accounts: Map.get(value, :accounts, 0)}, opts)
      end
   end
end