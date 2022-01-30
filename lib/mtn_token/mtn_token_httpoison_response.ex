defmodule MTNTokenHTTPoisonResponse do
  @moduledoc false

  require Logger

  defstruct []

  defimpl Types.HTTPClientResponse do
    def process_response(_this, result) do
      case result do
        {:ok, %HTTPoison.Response{status_code: 200, body: encoded_body}} ->
          case_status_200(encoded_body)

        {:ok, %HTTPoison.Response{status_code: 500, body: encoded_body}} ->
          case_status_500(encoded_body)

        {:ok, %HTTPoison.Response{status_code: 401, body: encoded_body}} ->
          case_status_401(encoded_body)

        {:ok, %HTTPoison.Response{status_code: status_code, body: encoded_body}} ->
          {:error, :undefined, %{status: status_code, body: encoded_body}}

        {:error, %HTTPoison.Error{reason: :timeout}} ->
          Logger.error("token provider timeout HTTP error")
          {:error, :timeout, %{status: -1, body: :timeout}}

        {:error, _} ->
          Logger.error("token response HTTP error")
          {:error, :undefined, %{status: -1, body: :undefined}}
      end
    end

    defp case_status_500(encoded_body) do
      case Jason.decode(encoded_body) do
        {:ok, res} when is_map(res) ->
          msg = Map.get(res, "error")
          {:error, msg, %{status: 500, body: encoded_body}}

        {:ok, _res} ->
          {:error, :undefined, %{status: 500, body: encoded_body}}

        {:error, _e} ->
          {:error, :undefined, %{status: 500, body: encoded_body}}
      end
    end

    defp case_status_401(encoded_body) do
      case Jason.decode(encoded_body) do
        {:ok, res} when is_map(res) ->
          msg = Map.get(res, "message")
          {:error, msg, %{status: 401, body: encoded_body}}

        {:ok, _res} ->
          {:error, :undefined, %{status: 401, body: encoded_body}}

        {:error, _e} ->
          {:error, :undefined, %{status: 401, body: encoded_body}}
      end
    end

    defp case_status_200(encoded_body) do
      case Jason.decode(encoded_body) do
        {:ok, res} when is_map(res) ->
          token = Map.get(res, "access_token")
          life_time = Map.get(res, "expires_in")
          {:ok, %{token: token, life_time: life_time}, %{status: 200, body: encoded_body}}

        {:ok, _res} ->
          {:error, :undefined, %{status: 200, body: encoded_body}}

        {:error, _e} ->
          {:error, :undefined, %{status: 200, body: encoded_body}}
      end
    end
  end
end
