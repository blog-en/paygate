defmodule PaygateWeb.Schemas do
  @moduledoc false
  alias OpenApiSpex.Schema

  defmodule TransferParams do
    @moduledoc false
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "TransferParams",
      description: "Transfer request data",
      type: :object,
      properties: %{
        amount: %Schema{type: :string, description: "The transaction value"},
        currency: %Schema{type: :string, description: "The transaction currency (UGX)"},
        to: %Schema{type: :string, description: "The msisdn of the transaction"}
      },
      example: %{
        "amount" => "4230",
        "currency" => "UGX",
        "to" => "2325215132"
      }
    })
  end

  defmodule TransferResponse200 do
    @moduledoc false
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Transfer response 200",
      description: "Transfer response",
      type: :object,
      properties: %{
        status: %Schema{type: :string, description: "Operation status"},
        reason: %Schema{type: :string, description: "Result description"}
      },
      example: %{
        "status" => "ok"
      }
    })
  end

  defmodule TransferResponse429 do
    @moduledoc false
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Transfer response 429",
      description: "Transfer response",
      type: :object,
      properties: %{
        status: %Schema{type: :string, description: "Operation status"},
        reason: %Schema{type: :string, description: "Result description"}
      },
      example: %{
        "status" => "error",
        "reason" => "Too many requests"
      }
    })
  end

  defmodule TransferResponse400 do
    @moduledoc false
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Transfer response 400",
      description: "Transfer response",
      type: :object,
      properties: %{
        status: %Schema{type: :string, description: "Operation status"},
        reason: %Schema{type: :string, description: "Result description"}
      },
      example: %{
        "status" => "error",
        "reason" => "Currency invalid"
      }
    })
  end

  defmodule TransferResponse502 do
    @moduledoc false
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Transfer response 502",
      description: "Transfer response",
      type: :object,
      properties: %{
        status: %Schema{type: :string, description: "Operation status"},
        reason: %Schema{type: :string, description: "Result description"}
      },
      example: %{
        "status" => "error",
        "reason" => "Downstream transfer service down"
      }
    })
  end
end
