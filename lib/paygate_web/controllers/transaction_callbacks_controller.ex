defmodule PaygateWeb.TransactionCallbacksController do
  use PaygateWeb, :controller

  @doc false
  def transfer_mtn_callback(conn, %{"ref" => e, "status" => status} = params) do
    if status
       |> String.downcase() == "successful" do
      GenStateMachine.cast({:global, e}, {:ok_result, params})
    else
      GenStateMachine.cast({:global, e}, {:error_result, params})
    end

    conn
    |> put_view(PaygateWeb.DataView)
    |> put_status(200)
    |> render("data.json", data: "ok")
  end
end
