defmodule Phreak.Kube do
  use GenServer

  def refresh() do
    get_pods()
    get_jobs()
  end

  def get_jobs() do
    GenServer.cast(:kube, :get_jobs)
  end

  def get_pods() do
    GenServer.cast(:kube, :get_pods)
  end

  def delete_pod(context, name) do
    GenServer.cast(:kube, {:delete_pod, context, name})
  end

  def get_contexts() do
    GenServer.call(:kube, :get_contexts)
  end

  def set_context(value) do
    GenServer.call(:kube, {:set_context, value})
    get_pods()
    get_jobs()
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: :kube)
  end

  def init(:ok) do
    Phoenix.PubSub.subscribe(
      Phreak.PubSub,
      "data_requests"
    )
    servers = init_kube_servers()
    Phoenix.PubSub.broadcast(Phreak.PubSub, "data_requests", :get_data)
    {:ok, servers}
  end

  def handle_cast(
        :get_pods,
        state
      ) do

    case Kazan.Apis.Core.V1.list_namespaced_pod!("default")
         |> Kazan.run(server: get_current_server(state)) do

      {:ok, result} ->
        broadcast({:pods, get_current_context(state), result.items})
        {:noreply, update(state, :pods, result.items)}
      {:error, error} ->
        broadcast({:server_error, error.reason})
        {:noreply, update(state, :pods, [])}
      {:http_error, 401, _} ->
        broadcast({:server_error, :unauthorized})
        {:noreply, update(state, :pods, [])}
    end

  end

  def handle_cast(
        :get_jobs,
        state
      ) do
    {:ok, result} = Kazan.Apis.Batch.V1.list_namespaced_job!("default")
                    |> Kazan.run(server: get_current_server(state))

    broadcast({:jobs, get_current_context(state), result.items})

    {:noreply, update(state, :jobs, result.items)}
  end

  def handle_cast({:delete_pod, context, name}, state) do
    server = state.servers[context].server

    Kazan.Apis.Core.V1.delete_namespaced_pod!(
      %Kazan.Models.Apimachinery.Meta.V1.DeleteOptions{
        api_version: "v1"
      },
      "default",
      name
    )
    |> Kazan.run(server: server)

    get_pods()
    {:noreply, state}
  end

  def handle_call(:get_contexts, _, state) do
    contexts = Map.keys(state.servers)
    {:reply, contexts, state}
  end

  def handle_call({:set_context, context}, _, state) do
    broadcast({:current_context, context})

    #    Phreak.Repo.transaction(
    #      fn ->
    #        Phreak.Repo.update_all(
    #          Phreak.Context,
    #          set: [
    #            is_current: false
    #          ]
    #        )
    #
    #        Ecto.Changeset.change(
    #          Phreak.Repo.get_by(Phreak.Context, name: context),
    #          %{is_current: true}
    #        )
    #        |> Phreak.Repo.update()
    #      end
    #    )

    {:reply, :ok, %{state | current_context: context}}
  end

  def handle_info(:get_data, state) do
    broadcast({:kube_data, state})
    get_pods()
    get_jobs()
    {:noreply, state}
  end

  ##
  # Private functions
  ##

  defp get_current_server(
         %{
           servers: servers,
           current_context: current_context
         }
       ) do
    servers[current_context].server
  end

  defp get_current_context(%{current_context: current_context}) do
    current_context
  end

  defp update(
         %{
           servers: servers,
           current_context: current_context
         } = state,
         key,
         data
       ) do

    servers[current_context]
    |> Map.put(key, data)
    |> (&(Map.put(servers, current_context, &1))).()
    |> (&(Map.put(state, :servers, &1))).()
  end

  defp broadcast(event) do
    Phoenix.PubSub.broadcast(Phreak.PubSub, "kube_updates", event)
    Phoenix.PubSub.broadcast(Phreak.PubSub, "kube_data", event)
  end

  defp get_server(config_file, context) do
    server_config = Kazan.Server.from_kubeconfig(
      config_file,
      context: context
    )
    {:ok, server} = Kazan.Server.resolve_auth(
      server_config,
      allow_command_execution: true
    )

    server
  end

  defp init_kube_servers() do
    config_file = Application.get_env(:phreak, :kube)[:config]
    data = YamlElixir.read_from_file!(config_file)

    servers = data["contexts"]
              |> Enum.map(fn c -> c["name"] end)
              |> Enum.reduce(
                   %{},
                   fn context, acc ->
                     server = get_server(config_file, context)
                     Map.put(
                       acc,
                       context,
                       %{
                         server: server,
                         jobs: [],
                         pods: []
                       }
                     )
                   end
                 )

    #    data["contexts"]
    #    |> Enum.each(
    #         fn c ->
    #           Phreak.Repo.insert(
    #             %Phreak.Context{
    #               name: c["name"],
    #               is_current: data["current-context"] == c["name"]
    #             }
    #           )
    #         end
    #       )

    %{current_context: data["current-context"], servers: servers}
  end
end
