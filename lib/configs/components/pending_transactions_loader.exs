[
  {
    fn ->
      %{
        start:
          {PendingTransactionsLoader, :start_link, [config.root.pending_transactions_loader]},
        id: config.root.pending_transactions_loader.name,
        restart: :transient,
        type: :worker
      }
    end,
    config.persistence != "none"
  }
]
