defmodule Mix.Tasks.Echo do
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.shell().info(String.replace(Atom.to_string(Mix.Project.config()[:app]), "_", "-"))
    Mix.shell().info(Mix.Project.config()[:version])
  end
end
