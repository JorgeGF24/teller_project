defmodule Bank1API.Transaction do
	@enforce_keys [:account_id, :username, :beneficiary_name, :amount, :date]
    defstruct [:account_id, :username, :beneficiary_name, :amount, :date, detail: "", currency: "GBP"]

    defimpl Jason.Encoder do
      @impl Jason.Encoder 
      def encode(value, opts) do
         Jason.Encode.map(%{account_id: Map.get(value, :account_id), username: Map.get(value, :username), 
            beneficiary_name: Map.get(value, :beneficiary_name), amount: Map.get(value, :amount), detail: Map.get(value, :detail), date: Map.get(value, :date, nil)}, opts)
      end
   end
end