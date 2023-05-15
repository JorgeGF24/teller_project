defmodule GenericAppBackend.Utils do

    def username_from_name(first_name, last_name) do
        if String.contains?(first_name, "_") or String.contains?(last_name, "_") do
            {:error, "Name not valid"}
        else
            {:ok, first_name <> "_" <> last_name}
        end
    end

    def get_user(username) do
        {:ok, users} = KV.Registry.lookup(GenericAppBackend.DB, "users")

        KV.Bucket.get(users, username)
    end

    def store_user(username, user) do
        {:ok, users} = KV.Registry.lookup(GenericAppBackend.DB, "users")

        KV.Bucket.put(users, username, user)
    end
end

