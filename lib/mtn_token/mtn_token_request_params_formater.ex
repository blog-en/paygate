defmodule MTNTokenRequestParamsFormater do
  @moduledoc false

  defstruct [
    :api_user,
    :api_key,
    :subscription_key
  ]

  defimpl Types.EndpointRequestParamsFormater do
    def get_req_params(
          this,
          _params
        ) do
      body = %{}

      authorization = "Basic #{Base.encode64("#{this.api_user}:#{this.api_key}")}"

      headers = [
        {"Authorization", authorization},
        {"subscription-key", this.subscription_key},
        {"Content-Type", "application/json"}
      ]

      {body, headers}
    end
  end
end
