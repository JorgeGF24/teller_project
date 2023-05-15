defmodule Bank1API.Account do
	@enforce_keys [:account_id, :first_name, :last_name, :username]
    defstruct [:account_id, :first_name, :last_name, :username, balance: 0]

    # Banks is a list of BankInfo structs

    defimpl Jason.Encoder do
      @impl Jason.Encoder 
      def encode(value, opts) do
         Jason.Encode.map(%{account_id: Map.get(value, :account_id), first_name: Map.get(value, :first_name), 
            last_name: Map.get(value, :last_name), username: Map.get(value, :username), balances: Map.get(value, :balance)}, opts)
      end
   end
end