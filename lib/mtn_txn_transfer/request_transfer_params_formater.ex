# MTN collection
defmodule MTNTransferRequestParamsFormater do
  @moduledoc false

  defstruct [:target_env, :subscription_key, :callback_url]

  defimpl Types.EndpointRequestParamsFormater do
    def get_req_params(
          this,
          %{
            amount: amount,
            msisdn: msisdn,
            currency: currency,
            ref: ref,
            token: token
          } = _params
        ) do
      body = %{
        amount: amount,
        currency: currency,
        externalId: ref,
        payee: %{
          partyIdType: "MSISDN",
          partyId: msisdn
        },
        payerMessage: "Default Message",
        payeeNote: "Default Note"
      }

      headers = [
        {"Authorization", "Bearer #{token}"},
        {"X-Reference-Id", ref},
        {"X-Target-Environment", this.target_env},
        {"Ocp-Apim-Subscription-Key", this.subscription_key},
        {"X-Callback-Url", this.callback_url},
        {"Content-Type", "application/json"}
      ]

      {body, headers}
    end
  end
end
