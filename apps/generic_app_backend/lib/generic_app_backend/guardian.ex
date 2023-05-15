defmodule GenericAppBackend.Guardian do
    use Guardian, otp_app: :generic_app_backend

    def subject_for_token(%{username: id}, _claims) do

        # Add an institution prefix to the subject
        sub = "GenApp_"<>to_string(id)
        {:ok, sub}
    end
    def subject_for_token(_, _) do
        {:error, :reason_for_error}
    end

    def resource_from_claims(%{"sub" => id}) do
        # Remove institution prefix from subject and get user
        resource =  to_string(id) |>
            String.slice(7..-1) |>
            GenericAppBackend.Utils.get_user
            
        {:ok,  resource}
    end
    def resource_from_claims(_claims) do
        {:error, :reason_for_error}
    end
end