defmodule Bank1API.Guardian do
    use Guardian, otp_app: :bank_1_api
    alias Bank1API.User

    def subject_for_token(%User{username: id, security_status: status}, _claims) do

        # Add an institution prefix to subject
        sub = "Bank1_"<>to_string(id)<>status
        {:ok, sub}
    end
    def subject_for_token(_, _) do
        {:error, :reason_for_error}
    end

    def resource_from_claims(%{"sub" => id}) do
        # Remove institution prefix from subject and get account
        user_security_status =  to_string id |>
            String.slice(6..-1)
            
        username = String.slice(user_security_status, 0..-5)
        security_status = String.slice(user_security_status, -5..-1)
        resource = Bank1API.Utils.get_user(username)

        {:ok,  resource}
    end
    def resource_from_claims(_claims) do
        {:error, :reason_for_error}
    end
end