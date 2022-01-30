defmodule Paygate.TransactionsTest do
  use ExUnit.Case, async: true

  setup do
    options = [
      scheme: :http,
      plug: TXNAPITestRouter,
      options: [port: 8012]
    ]

    start_supervised!({Plug.Cowboy, options})

    notificator = %TestTransactionResultNotificator{
      pid: self()
    }

    Paygate.AppConfig.start_link(params: %{notificator: notificator})
    Paygate.AppConfig.start_link()

    config = Paygate.AppConfig.load_configs(%{notificator: notificator})
    children = Paygate.ApplicationConfig.get_children(config)
    for child <- children, do: start_supervised!(child)
    Process.sleep(2000)

    :ok
  end

  describe "transfer" do
    @tag :integration
    @tag :transfer_integration
    test "it succeeds and it goes with callback", %{} do
      ref = UUID.uuid4()

      _res =
        Types.PaymentServiceTransfer.execute(
          Paygate.AppConfig.get(:root).transfer_service,
          %{
            amount: 4230,
            currency: "UGX",
            msisdn: "2325215132",
            ref: ref
          }
        )

      assert_receive({:response, %{ref: ^ref, status: :success, txn_type: :transfer}}, 3_000)
    end

    @tag :integration
    @tag :transfer_integration
    test "it fails, Transfer \"EXPIRED\" request", %{} do
      ref = "d0ddb5ed-2235-4b1d-9c18-87fc23608aac"

      _res =
        Types.PaymentServiceTransfer.execute(
          Paygate.AppConfig.get(:root).transfer_service,
          %{
            amount: 4230,
            currency: "UGX",
            msisdn: "2325215133",
            ref: ref
          }
        )

      assert_receive(
        {:response, %{ref: ^ref, status: :failed, txn_type: :transfer, reason: "EXPIRED"}}
      )
    end

    @tag :integration
    @tag :transfer_integration
    test "it fails, Transfer \"TRANSACTION_CANCELED\" request", %{} do
      ref = "5b977fe1-9d71-4ffc-8997-a051a1743fef"

      _res =
        Types.PaymentServiceTransfer.execute(
          Paygate.AppConfig.get(:root).transfer_service,
          %{
            amount: 4230,
            currency: "UGX",
            msisdn: "2325215133",
            ref: ref
          }
        )

      assert_receive(
        {:response,
         %{ref: ^ref, status: :failed, txn_type: :transfer, reason: "TRANSACTION_CANCELED"}}
      )
    end

    @tag :integration
    @tag :transfer_integration
    test "it fails, Transfer with retries", %{} do
      ref = "6d66b814-a580-45de-bd12-f8d7a68b3cc1"

      _res =
        Types.PaymentServiceTransfer.execute(
          Paygate.AppConfig.get(:root).transfer_service,
          %{
            amount: 4230,
            currency: "UGX",
            msisdn: "2325215133",
            ref: ref
          }
        )

      assert_receive({:response, %{ref: ^ref, status: :failed, txn_type: :transfer}}, 15_000)
    end

    @tag :integration
    @tag :transfer_integration
    test "it succeeds, Transfer with retries", %{} do
      ref = "7663e46b-75e3-4701-886f-cfe6c52f3a68"

      _res =
        Types.PaymentServiceTransfer.execute(
          Paygate.AppConfig.get(:root).transfer_service,
          %{
            amount: 4230,
            currency: "UGX",
            msisdn: "2325215133",
            ref: ref
          }
        )

      assert_receive({:response, %{ref: ^ref, status: :success, txn_type: :transfer}}, 15_000)
    end

    @tag :integration
    @tag :transfer_integration
    test "it fail, Transfer with always \"PENDING\" pooling", %{} do
      ref = "8c97a029-512b-47a9-aabb-ceb0d512e487"

      _res =
        Types.PaymentServiceTransfer.execute(
          Paygate.AppConfig.get(:root).transfer_service,
          %{
            amount: 4230,
            currency: "UGX",
            msisdn: "2325215133",
            ref: ref
          }
        )

      assert_receive({:response, %{ref: ^ref, status: :failed, txn_type: :transfer}}, 15_000)
    end

    @tag :integration
    @tag :transfer_integration
    test "it succeeds, Transfer with \"PENDING\" pooling and then goes ok", %{} do
      ref = "bf942c0e-e76a-460a-9650-ad5bee26aa2c"

      _res =
        Types.PaymentServiceTransfer.execute(
          Paygate.AppConfig.get(:root).transfer_service,
          %{
            amount: 4230,
            currency: "UGX",
            msisdn: "2325215133",
            ref: ref
          }
        )

      assert_receive({:response, %{ref: ^ref, status: :success, txn_type: :transfer}}, 15_000)
    end

    @tag :integration
    @tag :transfer_integration
    test "it fails, Transfer with \"PENDING\" pooling and then goes \"FAILED\"", %{} do
      ref = "f2ad4d47-86f0-49a5-b379-c48ab961a541"

      _res =
        Types.PaymentServiceTransfer.execute(
          Paygate.AppConfig.get(:root).transfer_service,
          %{
            amount: 4230,
            currency: "UGX",
            msisdn: "2325215133",
            ref: ref
          }
        )

      assert_receive({:response, %{ref: ^ref, status: :failed, txn_type: :transfer}}, 15_000)
    end
  end
end
