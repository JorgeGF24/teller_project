defmodule Bank1API.Router do
    use Plug.Router
    alias Bank1API.Guardian
    alias Bank1API.Utils
    alias Bank1API.Account
    alias Bank1API.User
    alias Bank1API.Transaction

    plug(Plug.Parsers,
        parsers: [:json],
        pass: ["*/*"],
        json_decoder: Jason
    )

    plug(:match)

    plug(:dispatch)

    get "/" do
        send_resp(conn, 200, "OK")
    end

    # This creates an account in the bank. It requires password for extra security. It also sets up a User account in the bank
    put "/create_account" do
        case conn.body_params do
            %{"first_name" => first_name, "last_name" => last_name, "password" => password} ->
                # Create username from name and surname
                case Utils.username_from_name(first_name, last_name) do
                    {:error} -> send_resp(conn, 400, "Invalid request: names can't contain underscores")
                    {:ok, username} ->
                        # Simple password encryption
                        user = Utils.get_user(username)
                        auth = user == nil || Safetybox.is_decrypted(password, user.password)
                        if auth do
                            if Utils.can_create_account(username, password) do
                                password = Safetybox.encrypt(password)

                                account_id = Utils.generate_account_number
                                account = %Account{account_id: account_id, first_name: first_name, last_name: last_name, username: username}

                                user = Utils.get_user(username) || %User{username: username, first_name: first_name, last_name: last_name, password: password}
                                user = %{user | accounts: [account|user.accounts] }

                                Utils.store_account(account_id, account)
                                Utils.store_user(username, user)
                                
                                {:ok, token, _claims} = Guardian.encode_and_sign(user)

                                {:ok, body} = Jason.encode(%{"message"=>"Bank1: Account created successfully","username"=>username,
                                    "account number" => account_id,
                                    "status"=>200, "access"=>token})
                                
                                conn
                                    |> put_resp_content_type("application/json")
                                    |> send_resp(200, body)
                            else
                                send_resp(conn, 403, "Bank1: Reached maximum number of permitted accounts for user #{username}")
                            end
                        else
                            send_resp(conn, 403, "Bank1: Invalid password")
                        end
                end
            _ -> send_resp(conn, 400, "Bank1: Request does not contain all required fields (first_name, last_name, password)")
        end
    end

    # This is the first step in the 2 step authentication of the bank
    post "/login" do
        case conn.body_params do
            %{"username" => username, "password" => password} ->
                if Utils.number_of_accounts(username) == nil do
                    send_resp(conn, 403, "Bank1: Credentials are not valid")
                else
                    user = Utils.get_user(username)

                    if Safetybox.is_decrypted(password, user.password) do
                        {:ok, token, _claims} = Guardian.encode_and_sign(user)
                        
                        path = Plug.Conn.request_url(conn) |>
                            String.slice(0..-(String.length(conn.request_path)+1))
                        path = path <> "/enroll/bank1/step2"

                        user = %User{user | security_status: "xxxx"}
                        Utils.store_user(username, user)

                        {:ok, body} = Jason.encode(%{"message"=>"Bank1: Credentials were correct for user #{username}. 
                            To proceed, please answer the security question \"what is your favourite colour?\" to #{path}.", "status"=>200, "access"=>token})
                        
                        conn
                            |> put_resp_content_type("application/json")
                            |> send_resp(200, body)
                    else 
                        send_resp(conn, 403, "Bank1: Credentials are not valid")
                    end
                end
            _ -> send_resp(conn, 400, "Bank1: Request does not contain all required fields (username, password)")
        end
    end

    # This endpoint checks the security answer of a user performing 2 step authentication
    put "/security" do
        case conn.body_params do
            %{"security_answer" => answer, "username" => username} ->
                if authenticated?(conn, username) do
                    user = Utils.get_user(username)

                    if answer == user.secret_answer do
                        user = %User{user | security_status: "okay"}
                        Utils.store_user(username, user)

                        {:ok, token, _claims} = Guardian.encode_and_sign(user)

                        {:ok, body} = Jason.encode(%{"message"=>"Bank1: Login succesful for user #{username}", "status"=>200, "access"=>token})
                        
                        conn
                            |> put_resp_content_type("application/json")
                            |> send_resp(200, body)
                    else
                        send_resp(conn, 403, "Bank1: Secret answer incorrect")

                    end
                else
                    send_resp(conn, 403, "Bank1: Credentials are not valid")
                end
                
            _ -> send_resp(conn, 400, "Bank1: Request does not contain all required fields (username, security_answer)")
        end
    end

    # Depending on provided information in body has different functionalities. Amount should be a number, not a string.
    put "/transactions" do
        case conn.body_params do
            # Creates a new transaction
            %{"account_id" => account_id, "beneficiary_name" =>beneficiary_name, "amount" => amount} when is_integer(amount) ->
                account = Utils.get_account(account_id)
                if account != nil do
                    if authenticated?(conn, account.username, true) do
                        transaction = %Transaction{account_id: account_id, beneficiary_name: beneficiary_name, username: account.username, 
                            amount: amount, detail: conn.body_params["detail"] || "", date: DateTime.utc_now}

                        account = %Account{account | balance: account.balance - amount}

                        Utils.store_account(account_id, account)
                        Utils.store_transaction(account_id, transaction)
                        
                        send_resp(conn, 200, "Bank1: Transaction recorded successfully")
                    else
                        send_resp(conn, 403, "Bank1: Not authorized to access")
                    end
                else
                    send_resp(conn, 404, "Bank1: Account doesn't exist")
                end

            # Returns a list of all transactions
            %{"account_id" => account_id} ->
                account = Utils.get_account(account_id)
                if account != nil do
                    if authenticated?(conn, account.username, true) do
                        {:ok, trans_list} = Jason.encode(Utils.get_transactions(account_id))

                        conn
                            |> put_resp_content_type("application/json")
                            |> send_resp(200, trans_list)

                    else
                        send_resp(conn, 403, "Bank1: Not authorized to access")
                    end
                else
                    send_resp(conn, 404, "Bank1: Account doesn't exist")
                end
            _-> send_resp(conn, 400, "Bank1: Missing field account_id in body")
        end
    end

    # Gets all accounts from a specific user
    put "/:username/accounts" do
        user = Utils.get_user(username, true)
        if authenticated?(conn, username, true) do
            {:ok, accounts} = Jason.encode(user.accounts)

            conn
                |> put_resp_content_type("application/json")
                |> send_resp(200, accounts)
        else
            send_resp(conn, 403, "Bank1: Not authorized to access")
        end
    end

    # get transactions
    # get accounts

    # Extra security is a parameter that specifies whether the user needs two step authentication for this action.
    defp authenticated?(conn, username, extra_security \\ false) do
        # Extract authorization token from header
        case Enum.at(Plug.Conn.get_req_header(conn,"authorization"),0) do
            nil -> 
                IO.puts "NO HEADER AUTH"
                false
                
            token -> 
                # Remove "Bearer " from token string
                token = String.slice(token, 7..-1)
                
                case Guardian.decode_and_verify(token) do
                    {:ok, claims} -> 
                        # Check that username is same as bearer token's
                        {:ok, user} = Guardian.resource_from_claims(claims)
                        # A security status of Nope means user hasnt done step 1, and okay means he's passed step 2
                        status_check = if extra_security, do: user.security_status == "okay", else: user.security_status != "Nope"
                        user != nil and username == user.username and status_check
                    _ -> false
                end
        end
    end


    match _ do
        send_resp(conn, 404, "Bank1: Not Found")
    end
end