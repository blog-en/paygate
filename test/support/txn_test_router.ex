defmodule TXNAPITestRouter do
  @moduledoc false

  use Plug.Router

  #  import ExUnit.Assertions

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jason

  plug :match
  plug :dispatch

  post "/payments/transfer_callback/:ref" do
    {:ok, _body, conn} = Plug.Conn.read_body(conn)

    %{"ref" => e, "status" => status} = conn.params
    params = conn.params

    if status
       |> String.downcase() == "successful" do
      GenStateMachine.cast({:global, e}, {:ok_result, params})
    else
      GenStateMachine.cast({:global, e}, {:error_result, params})
    end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, "{}")
  end
end
