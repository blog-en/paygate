defmodule PaygateWeb.TransactionController do
  use PaygateWeb, :controller

  use OpenApiSpex.ControllerSpecs

  alias PaygateWeb.Schemas.{
    TransferParams,
    TransferResponse200,
    TransferResponse400,
    TransferResponse429,
    TransferResponse502
  }

  @doc false
  def transfer(
        conn,
        %{"amount" => amount, "currency" => currency, "to" => msisdn} = _params
      ) do
    ref = get_req_header(conn, "x-reference-id")
    ref = if Enum.count(ref) > 0, do: Enum.at(ref, 0), else: UUID.uuid4()

    res =
      Types.PaymentServiceTransfer.execute(
        Paygate.AppConfig.get(:root).transfer_service,
        %{
          amount: amount,
          currency: currency,
          msisdn: msisdn,
          ref: ref
        }
      )

    event_prefix = [Application.get_application(__MODULE__), :transaction, :api]

    {status, msg} =
      case res do
        {:error, :too_many_requests} ->
          :telemetry.execute(
            event_prefix ++ [:transfer, :too_many_requests, :response],
            %{count: 1},
            %{label: "active"}
          )

          {429, %{status: :error, reason: "Too many requests"}}

        {:error, :transfer_currency_invalid} ->
          :telemetry.execute(
            event_prefix ++ [:transfer, :currency_invalid, :response],
            %{count: 1},
            %{label: "active"}
          )

          {400, %{status: :error, reason: "Currency invalid"}}

        {:error, :transfer_service_down} ->
          :telemetry.execute(
            event_prefix ++ [:transfer, :service_down, :response],
            %{count: 1},
            %{label: "active"}
          )

          {502, %{status: :error, reason: "Downstream transfer service down"}}

        {:error, :transfer_token_service_down} ->
          :telemetry.execute(
            event_prefix ++ [:transfer, :token_service_down, :response],
            %{count: 1},
            %{label: "active"}
          )

          {502, %{status: :error, reason: "Downstream token service down"}}

        {:error, reason} ->
          :telemetry.execute(event_prefix ++ [:transfer, :unknown, :response], %{count: 1}, %{
            label: "active"
          })

          {400, %{status: :error, reason: reason}}

        _ ->
          :telemetry.execute(event_prefix ++ [:transfer, :success, :response], %{count: 1}, %{
            label: "active"
          })

          {200, %{status: :ok}}
      end

    conn
    |> put_view(PaygateWeb.DataView)
    |> put_status(status)
    |> render("data.json", data: msg)
  end

  operation :transfer,
    summary: "Transfer operation",
    request_body: {"Transfer params", "application/json", TransferParams},
    responses: %{
      200 => {"Transfer success", "application/json", TransferResponse200},
      429 => {"Transfer error", "application/json", TransferResponse429},
      400 => {"Transfer error", "application/json", TransferResponse400},
      502 => {"Transfer error", "application/json", TransferResponse502}
    }
end
