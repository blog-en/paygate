defmodule MTN.Contract.Codes do
  @moduledoc false

  def all(), do: error() ++ undefined()

  def error() do
    [
      "PAYEE_NOT_FOUND",
      "PAYER_NOT_FOUND",
      "NOT_ALLOWED",
      "NOT_ALLOWED_TARGET_ENVIRONMENT",
      "INVALID_CALLBACK_URL_HOST",
      "INVALID_CURRENCY",
      "PAYER_LIMIT_REACHED",
      "PAYEE_NOT_ALLOWED_TO_RECEIVE",
      "PAYMENT_NOT_APPROVED",
      "RESOURCE_NOT_FOUND",
      "APPROVAL_REJECTED",
      "EXPIRED",
      "TRANSACTION_CANCELED",
      "RESOURCE_ALREADY_EXIST"
    ]
  end

  def undefined() do
    [
      "SERVICE_UNAVAILABLE",
      "INTERNAL_PROCESSING_ERROR",
      "NOT_ENOUGH_FUNDS"
    ]
  end
end
