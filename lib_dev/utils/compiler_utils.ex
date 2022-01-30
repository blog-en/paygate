defmodule CompilerUtils do
  def c do
    # https://stackoverflow.com/questions/36490089/how-do-i-recompile-an-elixir-project-and-reload-it-from-within-iex
    # everything is hot-reloaded without the application restarting
    Mix.Task.reenable("app.start")
    Mix.Task.reenable("compile")
    Mix.Task.reenable("compile.all")
    compilers = Mix.compilers()
    Enum.each(compilers, &Mix.Task.reenable("compile.#{&1}"))
    Mix.Task.run("compile.all")
  end

  def rc, do: IEx.Helpers.recompile()
end
