[
  {
    fn ->
      Supervisor.child_spec(
        {RateLimiting.TokenBucket,
         [
           name: :token_bucket,
           refill_rate: config.refill_rate,
           refill_time: config.refill_time,
           bucket_size: config.bucket_size
         ]},
        id: :token_bucket
      )
    end,
    true
  },
  {
    fn ->
      Supervisor.child_spec(
        {TokenSwitch,
         [
           this: config.root.transfer_token_switch
         ]},
        id: config.root.transfer_token_switch.id
      )
    end,
    true
  },
  {
    fn ->
      {
        Throttler.RateLimiter,
        %{
          min_demand: config.rate_limiter_min_demand,
          max_demand: config.rate_limiter_max_demand,
          interval: config.rate_limiter_interval,
          target_module: config.root.rate_limiter_target_module
        }
      }
    end,
    true
  }
]
