defmodule Paygate.Repo.Migrations.TxnsPayloadsHistory do
  use Ecto.Migration

  def change do
    execute("""
              create table transactions_history
              (
              id          binary(16) not null primary key,
              log         json       null,
              inserted_at datetime   null,
              constraint transactions_history_id_uindex unique (id)
              );
      """)
  end
end
