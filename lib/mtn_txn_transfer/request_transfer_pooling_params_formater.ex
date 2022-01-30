defmodule MTNTransferPoolingRequestParamsFormater do
  @moduledoc false

  defstruct [:subscription_key]

  defimpl Types.EndpointRequestParamsFormater do
    def get_req_params(
          this,
          %{
            ref: _ref,
            token: token
          } = params
        ) do
      headers = [
        {"Authorization", "Bearer #{token}"},
        {"Ocp-Apim-Subscription-Key", this.subscription_key},
        {"Content-Type", "application/json"}
      ]

      {params, headers}
    end
  end
end
