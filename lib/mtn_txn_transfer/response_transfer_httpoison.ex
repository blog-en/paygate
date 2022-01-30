defmodule MTNTransferHTTPoisonResponse do
  @moduledoc false

  require Logger

  defstruct []

  defimpl Types.HTTPClientResponse do
    def process_response(_this, result) do
      case result do
        {:ok, %HTTPoison.Response{status_code: 202 = status_code, body: encoded_body}} ->
          %TransactionSuccessfulResponse{
            extra_info: "{}",
            body: %ResponseBody{
              status: status_code,
              content: encoded_body
            }
          }

        {:ok, %HTTPoison.Response{status_code: status_code, body: encoded_body}}
        when status_code in [400, 500] ->
          case_status_400_or_500(encoded_body, status_code)

        {:ok, %HTTPoison.Response{status_code: 409 = status_code, body: encoded_body}} ->
          %TransactionErrorResponse{
            reason: "409: Duplicated reference id. Creation of resource failed.",
            body: %ResponseBody{
              status: status_code,
              content: encoded_body
            }
          }

        {:ok, %HTTPoison.Response{status_code: status_code, body: encoded_body}} ->
          %TransactionErrorResponse{
            reason: "#{status_code} response",
            body: %ResponseBody{
              status: status_code,
              content: encoded_body
            }
          }

        {:error, %HTTPoison.Error{reason: :timeout}} ->
          Logger.error("transfer timeout HTTP error")
          status_code = -1

          %TransactionErrorResponse{
            reason: "timeout",
            body: %ResponseBody{
              status: status_code,
              content: :timeout
            }
          }

        {:error, _} ->
          status_code = -1
          Logger.error("transfer request HTTP error")

          %TransactionErrorResponse{
            reason: "Unknow error",
            body: %ResponseBody{
              status: status_code,
              content: inspect(result)
            }
          }
      end
    end

    defp case_status_400_or_500(encoded_body, status_code) do
      value = Jason.decode(encoded_body)

      case value do
        {:ok, %{"code" => code, "message" => message} = res} when is_map(res) ->
          cond do
            code in MTN.Contract.Codes.error() ->
              %TransactionFailedResponse{
                reason: message,
                body: %ResponseBody{
                  status: status_code,
                  content: encoded_body
                }
              }

            code in MTN.Contract.Codes.undefined() ->
              %TransactionUndefinedResponse{
                reason: message,
                body: %ResponseBody{
                  status: status_code,
                  content: encoded_body
                }
              }

            true ->
              %TransactionErrorResponse{
                reason: message,
                body: %ResponseBody{
                  status: status_code,
                  content: encoded_body
                }
              }
          end

        {:ok, _res} ->
          %TransactionErrorResponse{
            reason: "Unknow response body",
            body: %ResponseBody{
              status: status_code,
              content: encoded_body
            }
          }

        {:error, _} ->
          %TransactionErrorResponse{
            reason: "Unknow response body",
            body: %ResponseBody{
              status: status_code,
              content: encoded_body
            }
          }
      end
    end
  end
end
