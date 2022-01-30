defmodule CallbackRequestParamsFormater do
  @moduledoc false

  require Logger

  defstruct token: nil

  defimpl Types.EndpointRequestParamsFormater do
    def get_req_params(
          this,
          body
        ) do
      headers =
        if this.token do
          [
            {"Authorization", "Bearer #{this.token}"},
            {"Content-Type", "application/json"}
          ]
        else
          [
            {"Content-Type", "application/json"}
          ]
        end

      {body, headers}
    end
  end
end
