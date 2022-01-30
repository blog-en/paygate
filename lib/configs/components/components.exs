[
  # Transaction Supervisor
  {
    fn ->
      {DynamicSupervisor, strategy: :one_for_one, name: Requester.RequestRunner}
    end,
    true
  },
  # GenStage Pipeline
  {
    fn -> Throttler.Producer end,
    true
  },
  {
    fn ->
      Supervisor.child_spec(
        {MTNTokenProvider,
         {:token_needed, %{ref: nil, this: config.root.transfer_token_provider}}},
        id: :transfer_token_provider
      )
    end,
    true
  }
]
