defmodule Paygate.AppConfig.PromEx do
  @moduledoc false

  @promex_module Paygate.PromEx

  def config_prom_ex(config) do
    conf = Application.get_env(Application.get_application(__MODULE__), @promex_module)

    conf =
      if Keyword.has_key?(conf, :metrics_server) do
        server_config = Keyword.get(conf, :metrics_server)

        server_config =
          if Keyword.has_key?(server_config, :port) do
            Keyword.update!(server_config, :port, fn _existing_value -> config.metrics_port end)
          else
            Keyword.put(server_config, :port, config.metrics_port)
          end

        Keyword.update!(conf, :metrics_server, fn _existing_value -> server_config end)
      else
        Keyword.put(conf, :metrics_server, port: config.metrics_port)
      end

    Application.put_env(Application.get_application(__MODULE__), @promex_module, conf)
  end
end
