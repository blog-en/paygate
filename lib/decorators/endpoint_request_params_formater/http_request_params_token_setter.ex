defmodule Decorators.HttpRequestParamsTokenSetter do
  @moduledoc false

  defstruct [:self, :token_provider]

  defimpl Types.EndpointRequestParamsFormater do
    def get_req_params(this, params) do
      token = Types.TokenProvider.get(this.token_provider)

      Types.EndpointRequestParamsFormater.get_req_params(
        this.self,
        Map.put(params, :token, token)
      )
    end
  end
end
