defmodule HTTPoisonGetRequest do
  @moduledoc false

  defstruct [:options, :base_url, :path]

  defimpl Types.HTTPClientRequest do
    def execute(this, {params, headers}) do
      HTTPoison.get(this.base_url <> this.path.(params), headers, this.options)
    end
  end
end
