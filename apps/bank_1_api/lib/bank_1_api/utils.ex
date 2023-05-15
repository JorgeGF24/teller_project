defmodule Bank1API.Utils do

    def username_from_name(first_name, last_name) do
        if String.contains?(first_name, "_") or String.contains?(last_name, "_") do
            {:error, "Name not valid"}
        else
            {:ok, first_name <> "_" <> last_name}
        end
    end

    def get_account(account_id) do
        {:ok, accounts} = KV.Registry.lookup(Bank1API.DB, "accounts")

        KV.Bucket.get(accounts, account_id)
    end

    def store_account(account_id, account) do
        {:ok, accounts} = KV.Registry.lookup(Bank1API.DB, "accounts")
        {:ok, account_counter} = KV.Registry.lookup(Bank1API.DB, "accounts counter")

        counter = KV.Bucket.get(account_counter, account.username) || 0
        KV.Bucket.put(account_counter, account.username, counter + 1)

        KV.Bucket.put(accounts, account_id, account)
    end

    # It is not straightforward to have updated accounts in our pseudo database, so we pass it as an option
    def get_user(username, accounts_up_to_date \\ false) do
        {:ok, users} = KV.Registry.lookup(Bank1API.DB, "users")

        user = KV.Bucket.get(users, username)

        if accounts_up_to_date do
            accounts = for account <- user.accounts, do: get_account(account.account_id)
            
            user = %{user | accounts: accounts}
            store_user(username, user)
        end

        user
    end

    def store_user(username, user) do
        {:ok, users} = KV.Registry.lookup(Bank1API.DB, "users")

        KV.Bucket.put(users, username, user)
    end

    def get_transactions(account_number) do
        {:ok, transactions} = KV.Registry.lookup(Bank1API.DB, "transactions")

        KV.Bucket.get(transactions, account_number) || []
    end

    def store_transaction(account_number, transaction) do
        {:ok, transactions} = KV.Registry.lookup(Bank1API.DB, "transactions")

        trans_list = [transaction | get_transactions(account_number)]

        KV.Bucket.put(transactions, account_number, trans_list)
    end

    # Limit number of accounts per user
    def can_create_account(username, password) do
        count = number_of_accounts(username)
        
        # Limit 3 accounts per user
        count == nil || count < 3
    end

    def number_of_accounts(username) do
        {:ok, account_counter} = KV.Registry.lookup(Bank1API.DB, "accounts counter")

        KV.Bucket.get(account_counter, username) 
    end

    # Heuristic for generating account numbers
    def generate_account_number do
        Ecto.UUID.generate
    end
end

