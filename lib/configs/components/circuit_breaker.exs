[
  {
    fn ->
      Supervisor.child_spec(
        {CircuitBreaker, {:closed, %{this: config.root.circuit_breaker, errors: 0}}},
        id: :switch_1
      )
    end,
    true
  }
]
