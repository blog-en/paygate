defmodule Paygate.Repo.Migrations.TxnsActive do
  use Ecto.Migration

  def change do
    execute("""
              create table transactions_active
              (
              txn_state json not null
              );
    """)
  end

end
