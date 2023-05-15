defmodule GenericAppBackend.Router do
    use Plug.Router
    use Plug.ErrorHandler
    alias GenericAppBackend.Guardian
    alias GenericAppBackend.Utils
    alias GenericAppBackend.User
    alias GenericAppBackend.Account
    require Logger

    plug(Plug.Logger)

    plug(Plug.Parsers,
        parsers: [:json],
        pass: ["*/*"],
        json_decoder: Jason
    )

    plug(:match)

    plug(:dispatch)

    # SIMULATE THAT ALL /Bank1/... paths go to a different server (bank1's server)
    forward "/bank1", to: Bank1API.Router

    get "/" do
        send_resp(conn, 200, "GenericApp: OK")
    end

    put "/" do
        :timer.sleep(5000)
        send_resp(conn, 200, "GenericApp: OK")
    end

    # Endpoint for creating a new user in our generic App
    put "/new_user" do
        case conn.body_params do
            %{"first_name" => first_name, "last_name" => last_name, "password" => password} ->
                # Create username from name and surname
                case Utils.username_from_name(first_name, last_name) do
                    {:error} -> send_resp(conn, 400, "GenericApp: Invalid request: names can't contain underscores")
                    {:ok, username} ->
                        if Utils.get_user(username) != nil do
                            send_resp(conn, 403, "GenericApp: Already existing user")
                        else
                            # Simple password encryption
                            password = Safetybox.encrypt(password)
                            user = %User{first_name: first_name, last_name: last_name, username: username, password: password}
                            
                            {:ok, token, _claims} = Guardian.encode_and_sign(%{username: username, institution: "GenericApp"})

                            {:ok, body} = Jason.encode(%{"message"=>"GenericApp: User created successfully with username #{username}", "status"=>200, "access"=>token})
                            

                            Utils.store_user(username, user)

                            conn
                                |> put_resp_content_type("application/json")
                                |> send_resp(200, body)
                        end
                end
            _ -> send_resp(conn, 400, "GenericApp: Request does not contain all required fields (first_name, last_name, password)")
        end
    end

    post "/login" do
        case conn.body_params do
            %{"username" => username, "password" => password} ->
                if Utils.get_user(username) == nil do
                    send_resp(conn, 403, "GenericApp: Credentials are not valid")
                else
                    user = Utils.get_user(username)

                    if Safetybox.is_decrypted(password, user.password) do
                        {:ok, token, _claims} = Guardian.encode_and_sign(%{username: username, institution: "GenericApp"})

                        {:ok, body} = Jason.encode(%{"message"=>"GenericApp: Login succesful for user #{username}", "status"=>200, "access"=>token})
                        
                        conn
                            |> put_resp_content_type("application/json")
                            |> send_resp(200, body)
                    else 
                        send_resp(conn, 403, "GenericApp: Credentials are not valid")
                    end
                end
            _ -> send_resp(conn, 400, "GenericApp: Request does not contain all required fields (username, password)")
        end
    end

    # GET USER DETAIL
    get "/users/:username" do
        {auth, user} = authenticated?(conn, username, true)
        if auth do
            {:ok, body} = Jason.encode(user)

            conn
                |> put_resp_content_type("application/json")
                |> send_resp(200, body)
        else 
            send_resp(conn, 403, "GenericApp: Not authorized")
        end
    end

    # GET USER ACCOUNTS FROM A BANK
    get "/accounts/:bank_name" do
        # Extracts username from bearer token
        {auth, user} = authenticated?(conn, "", true)
        if auth do
            case bank_name do
                "bank1" ->
                    path = Plug.Conn.request_url(conn) |>
                        String.slice(0..-(String.length(conn.request_path)+1))
                    path = path <> "/bank1/#{user.username}/accounts"
                        |> IO.inspect

                    token = get_token(conn, user, "bank1") |> IO.inspect
                    {:ok, response} = HTTPoison.get path, [], ["Authorization": "Bearer #{token}"]
                    
                    conn
                        |> put_resp_content_type("application/json")
                        |> send_resp(response.status_code, response.body)

                "bank2" ->
                    send_resp(conn, 404, "GenericApp: Not implemented yet")
                _ -> send_resp(conn, 500, "GenericApp: Unknown error")
            end
        else 
            send_resp(conn, 403, "GenericApp: Not authorized")
        end
    end

    # Should be get
    # GET ACCOUNT TRANSACTIONS FROM BANK ACCOUNT
    put "/transactions/:bank_name" do
        # Extracts username from bearer token
        {auth, user} = authenticated?(conn, "", true)
        case conn.body_params do
            %{"account_id" => _} ->
                if auth do
                    case bank_name do
                        "bank1" ->
                            path = Plug.Conn.request_url(conn) |>
                                String.slice(0..-(String.length(conn.request_path)+1))
                            path = path <> "/bank1/transactions"

                            {:ok, body} = Jason.encode(conn.body_params)

                            {:ok, response} = HTTPoison.put path, body, ["Authorization": "Bearer #{get_token(conn, user, "bank1")}","Content-Type": "application/json"]
                            
                            conn
                                |> put_resp_content_type("application/json")
                                |> send_resp(response.status_code, response.body)

                        "bank2" ->
                            send_resp(conn, 404, "GenericApp: Not implemented yet")
                        _ -> send_resp(conn, 500, "GenericApp: Unknown error")
                    end
                else 
                    send_resp(conn, 403, "GenericApp: Not authorized")
                end
            _ -> send_resp(conn, 400, "GenericApp: Missing fielsdsdfd account_id in body")
        end

    end

    put "/enroll/bank1/step2" do
        case conn.body_params do
            %{"security_answer" => _, "username" => username, "token" => _} ->
                if authenticated?(conn, username) do
                    enroll_bank1_step2(conn, username)
                else
                    send_resp(conn, 403, "GenericApp: Not authorized")
                end
            _ -> send_resp(conn, 400, "GenericApp: Request does not contain all required fields (username, security_answer, token)")
        end
    end

    put "/enroll/:bank_name" do
        case conn.body_params do
            %{"username" => username, "password" => _} ->
                if authenticated?(conn, username) and bank_integrated?(bank_name) do
                    case bank_name do
                        "Bank1" ->
                            enroll_bank1(conn, username)
                        "Bank2" ->
                            send_resp(conn, 404, "GenericApp: Not implemented yet")
                        _ -> send_resp(conn, 500, "GenericApp: Unknown error")

                    end
                else
                    send_resp(conn, 403, "GenericApp: Not authorized")
                end
            _ -> send_resp(conn, 400, "GenericApp: Request does not contain all required fields (username, last_name)")
        end
    end

    match _ do
        send_resp(conn, 404, "GenericApp: Not Found")
    end

    # Handle Errors
    defp handle_errors(conn, error) do
        Logger.error("[Router]: Web Request Failed:\n#{inspect(error)}")
        render_json(conn, conn.status, build_error("Something Went Wrong. See Logs."))
    end

    # Render JSON
    defp render_json(conn, code, map) do
        body = Jason.encode!(map)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(code, body)
    end

    # Build Error
    defp build_error(message) do
        %{status: "failed", message: message}
    end

    defp enroll_bank1(conn, username) do

        # Do a request to the Bank1 API to check if credentials are valid
        path = Plug.Conn.request_url(conn) |>
            String.slice(0..-(String.length(conn.request_path)+1))
        path = path <> "/bank1/login"

        {:ok, body} = Jason.encode(conn.body_params)

        {:ok, response} = HTTPoison.post path, body, [{"Content-Type", "application/json"}]
        # Response should redirect us to 2nd step of their security check, for which we have been given a temporary access token
        
        if response.status_code == 200 do

            # Store temporary access token in account info, needed to pass 2-step security check
            user = Utils.get_user(username)

            {:ok, decoded_body} = Jason.decode(response.body)

            account = %Account{institution_name: "bank1", username: username, extra_info: %{temporary_access: decoded_body["access"]}}
            user = %User{user | accounts: [account | user.accounts], security_tokens: Map.put(user.security_tokens, "bank1", decoded_body["access"])}

            # User with new commenced bank enrollment. Save token in user's device before going onto step 2.
            Utils.store_user(username, user)
        end
        
        conn
            |> put_resp_content_type("application/json")
            |> send_resp(response.status_code, response.body)
    end

    defp enroll_bank1_step2(conn, username) do

        # Do a request to the Bank1 API to check if security question is valid
        path = Plug.Conn.request_url(conn) |>
            String.slice(0..-(String.length(conn.request_path)+1))
        path = path <> "/bank1/security"

        {:ok, body} = Jason.encode(conn.body_params)

        user = Utils.get_user(username)

        {:ok, response} = HTTPoison.put path, body, ["Authorization": "Bearer #{get_token(conn, user, "bank1")}", "Content-Type": "application/json"]

        if response.status_code == 200 do

            # Store access token with all rights in account info
            {:ok, decoded_body} = Jason.decode(response.body)


            user = %User{user | security_tokens: Map.put(user.security_tokens, "bank1", decoded_body["access"])}

            # User with completed enrollment in bank1. Save token in user's device to authorize toher endpoints.
            Utils.store_user(username, user)
            
        end

        conn
            |> put_resp_content_type("application/json")
            |> send_resp(response.status_code, response.body)
    end

    defp authenticated?(conn, username, return_user \\ false) do
        # Extract authorization token from header
        case Enum.at(Plug.Conn.get_req_header(conn,"authorization"),0) do
            nil -> if return_user, do: {false, nil}, else: false
            token -> 
                # Remove "Bearer " from token string
                token = String.slice(token, 7..-1)
                
                case GenericAppBackend.Guardian.decode_and_verify(token) do
                    {:ok, claims} -> 
                        # Check that username is same as bearer token's
                        {:ok, user} = GenericAppBackend.Guardian.resource_from_claims(claims)
                        if return_user do
                            {user != nil, user}
                        else
                            user != nil and username == user.username
                        end
                    _ -> 
                        if return_user, do: {false, nil}, else: false
                end
        end
    end

    defp bank_integrated?(bank_name) do
        Enum.member?(["Bank1"], bank_name)
    end

    defp get_token(conn, user, bank_name) do
        conn.body_params["token"] || user.security_tokens[bank_name]
    end
end