defmodule MTNTransferPoolingHTTPoisonResponse do
  @moduledoc false

  require Logger

  defstruct []

  defimpl Types.HTTPClientResponse do
    def process_response(_this, result) do
      case result do
        {:ok, %HTTPoison.Response{status_code: 200 = status_code, body: encoded_body}} ->
          case_status_200(encoded_body, status_code)

        {:ok, %HTTPoison.Response{status_code: status_code, body: encoded_body}} ->
          %TransactionPoolingErrorResponse{
            response: "{}",
            body: %ResponseBody{
              status: status_code,
              content: encoded_body
            }
          }

        {:error, %HTTPoison.Error{reason: :timeout}} ->
          Logger.error("transfer timeout HTTP error")

          status_code = -1

          %TransactionPoolingErrorResponse{
            response: "timeout",
            body: %ResponseBody{
              status: status_code,
              content: :timeout
            }
          }

        {:error, _} ->
          Logger.error("transfer pooling HTTP error")
          status_code = -1

          %TransactionPoolingErrorResponse{
            response: "Unknow error",
            body: %ResponseBody{
              status: status_code,
              content: inspect(result)
            }
          }
      end
    end

    defp case_status_200(encoded_body, status_code) do
      case Jason.decode(encoded_body) do
        {:ok, %{"status" => "SUCCESSFUL"} = response} when is_map(response) ->
          %TransactionPoolingSuccessfulResponse{
            response: response,
            body: %ResponseBody{
              status: status_code,
              content: encoded_body
            }
          }

        {:ok,
         %{"status" => "FAILED", "reason" => %{"code" => code, "message" => message}} = response}
        when is_map(response) ->
          %TransactionPoolingFailedResponse{
            code: code,
            reason: message,
            body: %ResponseBody{
              status: status_code,
              content: encoded_body
            }
          }

        {:ok, %{"status" => "FAILED", "reason" => reason} = response} when is_map(response) ->
          %TransactionPoolingFailedResponse{
            reason: inspect(reason),
            body: %ResponseBody{
              status: status_code,
              content: encoded_body
            }
          }

        {:ok, %{"status" => "FAILED"} = response} when is_map(response) ->
          %TransactionPoolingFailedResponse{
            reason: "",
            body: %ResponseBody{
              status: status_code,
              content: encoded_body
            }
          }

        {:ok, %{"status" => "PENDING"} = response} when is_map(response) ->
          %TransactionPoolingPendingResponse{
            response: response,
            body: %ResponseBody{
              status: status_code,
              content: encoded_body
            }
          }

        {:ok, response} ->
          %TransactionPoolingErrorResponse{
            response: response,
            body: %ResponseBody{
              status: status_code,
              content: encoded_body
            }
          }

        {:error, response} ->
          %TransactionPoolingErrorResponse{
            response: response,
            body: %ResponseBody{
              status: status_code,
              content: encoded_body
            }
          }
      end
    end
  end
end
