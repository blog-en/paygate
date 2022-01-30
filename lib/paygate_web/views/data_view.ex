defmodule PaygateWeb.DataView do
  use PaygateWeb, :view
  #  alias PaygateWeb.DataView

  @doc false
  def render("data.json", %{data: data}) do
    data
  end
end
