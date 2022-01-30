defmodule Paygate.AppConfig.Persistence do
  @moduledoc false

  def bindings do
    [
      {:database_url, "PAYGATE_DATABASE_URL", required: false},
      {:persistence, "PAYGATE_PERSISTENCE", default: "none", required: true}
    ]
  end

  @spec config(map()) :: %Structs.PersistenceReturn{}
  def config(configs) do
    if configs.persistence != "none" do
      repository_entity =
        if configs.persistence == "memory" do
          %Infrastructure.Repository.MemoryRepository{
            name: :repository
          }
        else
          if !Map.get(configs, :database_url) do
            IO.puts("PAYGATE_DATABASE_URL env var missing.")
            :erlang.halt(2)
          end

          %Infrastructure.Repository.MySQLRepository{}
        end

      %Structs.PersistenceReturn{
        write_buffer: %Events.WriteBuffer{
          name: :write_buffer,
          writer: repository_entity
        },
        repository_entity: repository_entity,
        transactions_loader: %PendingTransactionsLoader{
          name: :transaction_loader,
          repository: repository_entity
        }
      }
    else
      %Structs.PersistenceReturn{
        write_buffer: nil,
        repository_entity: nil,
        transactions_loader: nil
      }
    end
  end
end
