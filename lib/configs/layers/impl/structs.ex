defmodule Structs.CircuitBreakerReturn do
  @moduledoc false

  defstruct [:switch_id, :circuit_breaker]
end

defmodule Structs.RateLimitingParams do
  @moduledoc false

  defstruct [:service]
end

defmodule Structs.RateLimitingReturn do
  @moduledoc false

  defstruct [:rate_limiter_id, :transfer_root_validator0]
end

defmodule Structs.PersistenceReturn do
  @moduledoc false

  defstruct [:write_buffer, :repository_entity, :transactions_loader]
end

defmodule Structs.TransferReturn do
  @moduledoc false

  defstruct [:service, :token_provider, :service_metrics, :token_switch, :transfer_fsm_data]
end

defmodule Structs.TransferParams do
  @moduledoc false

  defstruct [:switch_id, :write_buffer]
end

defmodule Structs.BaseReturn do
  @moduledoc false

  defstruct [
    :circuit_breaker,
    :transfer_service,
    :transfer_token_provider,
    :rate_limiter_target_module,
    :transfer_token_switch,
    :repository_entity,
    :buffer_writer,
    :pending_transactions_loader,
    :transfer_fsm_data
  ]
end

defmodule Structs.BaseParams do
  @moduledoc false

  defstruct [
    :write_buffer,
    :repository_entity,
    :transactions_loader,
    :token_provider,
    :service_metrics,
    :token_switch,
    :transfer_fsm_data,
    :rate_limiter_id,
    :transfer_root_validator0,
    :circuit_breaker
  ]
end
