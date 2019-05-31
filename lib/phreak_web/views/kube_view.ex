defmodule Phreak.KubeView do
  use PhreakWeb, :view
  alias Phreak.KubeLive


  def panel_styles(selected) do
    case selected do
      true ->
        "
        border-r border-b-4 border-l lg:border-t bg-white rounded-b rounded-t lg:rounded-r p-4
        border-blue-dark
        "
      false ->
        "border-r border-b-4 border-l lg:border-t bg-white rounded-b rounded-t lg:rounded-r p-4"
    end
  end

  def header_styles(context) do
    case context
         |> String.contains?("prod") do
      true ->
        "bg-red text-white"
      false ->
        "bg-primary text-white"
    end
  end

  def pod_status_style("Pending"), do: "bg-yellow"
  def pod_status_style("Running"), do: "bg-blue text-white"
  def pod_status_style("Succeeded"), do: "bg-green text-white"
  def pod_status_style("Failed"), do: "bg-red text-white"
  def pod_status_style("Unknown"), do: "bg-grey"
  def pod_status_style("Completed"), do: "bg-green-lighter"
  def pod_status_style("CrashLoopBackOff"), do: "bg-red-lighter"
  def pod_status_style("Terminating"), do: "bg-red-lighter"
  def pod_status_style(_), do: ""

  def ui_section_title(:pods), do: "Pods"
  def ui_section_title(:jobs), do: "Jobs"
  def ui_section_title(section), do: section

  def obfuscate(value) do
    value
    |> String.split("-")
    |> Enum.map(&Phreak.Obfuscate.obfuscate/1)
    |> Enum.join("-")
  end
end
