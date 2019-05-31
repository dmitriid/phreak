defmodule Mix.Tasks.Node.Update do
  use Mix.Task

  @shortdoc "Update node assets"
  def run(_args) do
    update_assets()
  end

  defp update_assets() do
    IO.puts "...Updating node assets"
    case System.cmd("node", ["./node_modules/webpack/bin/webpack.js", "--mode", "#{get_env()}"], cd: "assets") do
      {val, 0} ->
        IO.puts "...Node assets updated"
        IO.puts val
      {error, _errnum} ->
        IO.puts error
    end
  end

  def get_env() do
    case Mix.env do
      :prod -> "production"
      _ -> "development"
    end
  end

end
