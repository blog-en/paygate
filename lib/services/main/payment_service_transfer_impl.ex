defmodule PaymentServiceTransferImpl do
  @moduledoc false

  defstruct [
    :fsm_data
  ]

  defimpl Types.PaymentServiceTransfer do
    def execute(this, %{ref: ref} = params) do
      {:ok, _job} =
        Transactor.start_job({
          :waiting_for_throttling,
          %{
            ref: nil,
            pooling_ref: nil,
            final_message: nil,
            this: this.fsm_data,
            params: params,
            started_time: DateTime.from_unix(0),
            messages: [],
            retries: 0,
            transaction_type: :transfer
          }
        })

      {:ok, ref}
    end
  end
end
