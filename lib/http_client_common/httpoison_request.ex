defmodule HTTPoisonRequest do
  @moduledoc false

  defstruct [:options, :base_url, :path]

  defimpl Types.HTTPClientRequest do
    def execute(this, {body, headers}) do
      HTTPoison.post(this.base_url <> this.path, Jason.encode!(body), headers, this.options)
    end
  end
end
