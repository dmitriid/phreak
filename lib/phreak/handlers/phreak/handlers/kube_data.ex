defmodule Phreak.Handlers.KubeData do
  @moduledoc false
  use GenServer
  import Ecto.Query, only: [from: 2, select: 3]

  def start_link(_) do
    IO.puts("start_link #{__MODULE__}")
    GenServer.start_link(__MODULE__, :ok, name: :kube_data_handler)
  end

  def init(:ok) do
    IO.puts("init #{__MODULE__}")

    Phoenix.PubSub.subscribe(
      Phreak.PubSub,
      "kube_data"
    )

    {:ok, %{}}
  end

  def handle_info({:kube_data, data}, socket) do
    contexts = data.servers
               |> Map.keys
    current_context = data.current_context
    jobs = []
    pods = []

    Phreak.Repo.transaction(
      fn ->
        Phreak.Repo.delete_all(Phreak.Context)
        contexts
        |> Enum.each(
             fn c ->
               Phreak.Repo.insert(
                 %Phreak.Context{
                   name: c,
                   is_current: c == current_context
                 }
               )
             end
           )
      end

    )
    {:noreply, %{}}
  end

  def handle_info({:pods, _current_context, pods}, socket) do
    list = pods
           |> Enum.map(
                fn p ->
                  status =
                    case (p.metadata.deletion_timestamp != nil and
                          p.metadata.deletion_timestamp > 0)
                      do
                      true -> "Terminating"
                      false -> p.status.phase
                    end

                  # %{
                  #   selected: false,
                  #   status: status,
                  #   data: p
                  # }

                  %Phreak.Models.Pod{
                    name: p.metadata.name,
                    status: "",
                    uid: p.metadata.uid,
                    parent_uid: (
                      p.metadata.owner_references
                      |> List.first).uid
                  }
                end
              )
    #    uids = list
    #           |> Enum.map(
    #                fn p ->
    #                  p.uid
    #                end
    #              )

    IO.inspect(list)

    Phreak.Repo.transaction(
      fn ->
        list
        |> Enum.each(
             fn p ->
               Phreak.Repo.insert(
                 p,
                 on_conflict: :replace_all_except_primary_key,
                 conflict_target: :uid
               )
             end
           )
      end
    )

    {:noreply, %{}}
  end

  def handle_info(_, socket) do
    {:noreply, %{}}
  end

end
