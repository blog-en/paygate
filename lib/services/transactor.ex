defmodule Transactor do
  @moduledoc false

  require Logger

  def start_job(args) do
    child_spec = %{
      :id =>
        args
        |> elem(1)
        # todo: this depends on the payload structure!
        |> get_in([:params, :ref]),
      :start => {TransactionRequesterFSM, :start_link, [args]},
      :restart => :transient,
      :type => :worker
    }

    DynamicSupervisor.start_child(
      Requester.RequestRunner,
      child_spec
    )
  end
end
