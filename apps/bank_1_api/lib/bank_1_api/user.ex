defmodule Bank1API.User do
	@enforce_keys [:username, :first_name, :last_name, :password]
    defstruct [:username, :first_name, :last_name, :password, accounts: [], security_status: "Nope", secret_answer: "orange"]

    # Banks is a list of BankInfo structs

    defimpl Jason.Encoder do
      @impl Jason.Encoder 
      def encode(value, opts) do
         Jason.Encode.map(%{username: Map.get(value, :username), first_name: Map.get(value, :first_name), 
            last_name: Map.get(value, :last_name), accounts: Map.get(value, :accounts)}, opts)
      end
   end
end