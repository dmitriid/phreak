defmodule PhreakWeb.KubeLive do
  @moduledoc false

  use Phoenix.LiveView
  alias Phreak.KubeView

  @empty_state %{
    # data
    contexts: [],
    current_context: "",
    pods: [],
    jobs: [],
    ui: %{
      __global: %{
        section: :pods,

        menus: %{
          context: %{
            is_open: false,
          }
        }
      },

      pods: %{
        # actual display
        display_list: [],

        # selection
        no_of_selected: 0,
        all_are_selected: false,
        selected_map: %{},

        # deletion
        deletion_requested_for: "",
        deletion_requested_for_selection: false,

        # filtering
        filter: "",
        status_filters: [
          "Pending",
          "Running",
          "Succeeded",
          "Failed",
          "Unknown",
          "Completed",
          "CrashLoopBackOff",
          "Terminating"
        ],

        # sorting
        sort: %{
          name: :asc,
          status: nil
        }
      },

      jobs: %{
        # actual display
        display_list: [],

        # selection
        no_of_selected: 0,
        all_are_selected: false,
        selected_map: %{},

        # deletion
        deletion_requested_for: "",
        deletion_requested_for_selection: false,

        # filtering
        filter: "",

        # sorting
        sort: %{
          name: :asc,
          status: nil
        }
      }
    },
  }

  def render(assigns), do: KubeView.render("dashboard.html", assigns)

  def mount(_session, socket) do
    Phoenix.PubSub.subscribe(
      Phreak.PubSub,
      "kube_updates"
    )
    Phoenix.PubSub.broadcast(Phreak.PubSub, "data_requests", :get_data)

    {
      :ok,
      assign(
        socket,
        @empty_state
      )
    }
  end

  defp get_value(socket, assigns, keys, default) do
    case Kernel.get_in(assigns, keys) do
      nil -> case Kernel.get_in(socket.assigns, keys) do
               nil -> default
               value -> value
             end
      value -> value
    end
  end

  defp do_update_in(map, keys, value) do
    Kernel.put_in(map, Enum.map(keys, &Access.key(&1, %{})), value)
  end

  defp update_pod_list(socket, assigns) do
    get_value(socket, assigns, [:pods], [])
  end

  defp get_filtered_pods(pods, socket, assigns) do
    filter = get_value(
      socket,
      assigns,
      [:ui, :pods, :filter],
      ""
    )

    case filter do
      "" -> pods
      _ -> pods
           |> Enum.filter(
                fn pod ->
                  FuzzyCompare.similarity(
                    Phreak.KubeView.obfuscate(pod.data.metadata.name),
                    filter
                  ) > 0.8
                end
              )
    end
  end

  defp get_selected_pods(pods, socket, assigns) do
    selected_map = get_value(
      socket,
      assigns,
      [:ui, :pods, :selected_map],
      %{}
    )

    Enum.reduce(
      pods,
      {0, []},
      fn p, {n, pps} ->
        will_select = :error != Map.fetch(selected_map, p.data.metadata.uid)
        no = n + if will_select, do: 1, else: 0
        updated = %{
          p |
          selected: will_select
        }
        {no, pps ++ [updated]}
      end
    )
  end

  defp get_filtered_by_status(list, socket, assigns) do
    filters = get_value(
      socket,
      assigns,
      [:ui, :pods, :status_filters],
      []
    )

    Enum.filter(list, fn p -> p.status in filters end)
  end

  defp get_sorted_pods(pods, socket, assigns) do
    sort = get_value(
      socket,
      assigns,
      [:ui, :pods, :sort],
      %{name: nil, status: nil}
    )

    case sort do
      %{name: nil, status: nil} -> pods
      %{name: direction, status: nil} ->
        Enum.sort(
          pods,
          fn left, right ->
            case direction do
              :asc ->
                Phreak.KubeView.obfuscate(
                  left.data.metadata.name
                ) < Phreak.KubeView.obfuscate(right.data.metadata.name)
              :desc ->
                Phreak.KubeView.obfuscate(
                  left.data.metadata.name
                ) > Phreak.KubeView.obfuscate(right.data.metadata.name)
            end
          end
        )
      %{name: nil, status: direction} ->
        Enum.sort(
          pods,
          fn left, right ->
            case direction do
              :asc -> left.status < right.status
              :desc -> left.status > right.status
            end
          end
        )
    end
  end

  defp update_display(socket, assigns) do
    ui_pod_list = update_pod_list(socket, assigns)
    filtered_by_status = get_filtered_by_status(ui_pod_list, socket, assigns)
    filtered_pods = get_filtered_pods(filtered_by_status, socket, assigns)

    {no_selected, selected_pods} = get_selected_pods(
      filtered_pods,
      socket,
      assigns
    )

    sorted_pods = get_sorted_pods(selected_pods, socket, assigns)


    filter = get_value(
      socket,
      assigns,
      [:ui, :pods, :filter],
      ""
    )

    updated_assigns = assigns
                      |> do_update_in([:ui, :pods, :display_list], sorted_pods)
                      |> do_update_in([:ui, :pods, :filter], filter)
                      |> do_update_in(
                           [:ui, :pods, :all_are_selected],
                           no_selected == length(selected_pods)
                         )
                      |> do_update_in(
                           [:ui, :pods, :no_of_selected],
                           no_selected
                         )

    updated_socket_assigns = DeepMerge.deep_merge(
                               socket.assigns,
                               updated_assigns
                             )
                             |> do_update_in(
                                  [:ui, :pods, :selected_map],
                                  get_value(
                                    socket,
                                    assigns,
                                    [:ui, :pods, :selected_map],
                                    %{}
                                  )
                                )

    assign(
      socket,
      updated_socket_assigns

      #        Map.merge(
      #           %{
      #             ui_display_pods: sorted_pods,
      #             ui_filter: filter,
      #             ui_all_pods_selected: no_selected == length(selected_pods),
      #             ui_no_of_selected_pods: no_selected
      #           }
      #         )
    )
  end

  def handle_info({:kube_data, data}, socket) do
    contexts = data.servers
               |> Map.keys
    current_context = data.current_context
    jobs = []
    pods = []

    {
      :noreply,
      update_display(
        socket,
        Map.merge(
          @empty_state,
          %{
            contexts: contexts,
            current_context: current_context,
            jobs: jobs,
            pods: pods
          }
        )
        |> do_update_in([:ui, :pods, :display_list], pods)
      )
    }
  end

  def handle_info({:jobs, _current_context, jobs}, socket) do
    {:noreply, update_display(socket, %{jobs: jobs})}
  end

  def handle_info({:current_context, value}, socket) do
    {:noreply, update_display(socket, %{current_context: value})}
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

                  %{
                    selected: false,
                    status: status,
                    data: p
                  }
                end
              )
    {:noreply, update_display(socket, %{pods: list})}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  def handle_event("select", value, %{assigns: assigns} = state) do
    selected_map = get_in(assigns, [:ui, :pods, :selected_map])
    will_select = :error == Map.fetch(selected_map, value)

    updated_selected_map = case will_select do
      true ->
        selected_map
        |> Map.put(value, true)
      false ->
        selected_map
        |> Map.delete(value)
    end

    {
      :noreply,
      update_display(
        state,
        %{
          ui: %{
            pods: %{
              selected_map: updated_selected_map
            }
          }
        }
      )
    }
  end

  def handle_event("select_all", _, %{assigns: assigns} = state) do
    pods = get_in(assigns, [:ui, :pods, :display_list])
    select_all = get_in(assigns, [:ui, :pods, :all_are_selected]) == false
    selected_map = case select_all do
      true ->
        Enum.reduce(
          pods,
          get_in(assigns, [:ui, :pods, :selected_map]),
          fn p, acc -> Map.put(acc, p.data.metadata.uid, true) end
        )
      false -> %{}
    end
    {
      :noreply,
      update_display(
        state,
        %{}
        |> do_update_in([:ui, :pods, :selected_map], selected_map)
      )
    }
  end

  def handle_event("select-context", value, state) do
    current_context = get_in(state.assigns, [:current_context])
    case value do
      c when c == current_context ->
        {:noreply, state}
      _ ->
        Phreak.Kube.set_context(value)
        {
          :noreply,
          update_display(
            state,
            %{jobs: [], pods: []}
            |> do_update_in([:ui, :__global, :menus, :context, :is_open], false)
          )
        }
    end
  end

  def handle_event("select-section", value, state) do
    {
      :noreply,
      update_display(
        state,
        %{}
        |> do_update_in([:ui, :__global, :section], String.to_atom(value))
      )
    }
  end

  def handle_event("filter-pods", value, state) do
    filter = case value do
      "Backspace" -> ""
      _ -> value
    end
    {
      :noreply,
      update_display(
        state,
        %{}
        |> do_update_in([:ui, :pods, :filter], filter)
      )
    }
  end

  def handle_event("delete-pod-request", value, state) do
    {
      :noreply,
      update_display(
        state,
        %{}
        |> do_update_in([:ui, :pods, :deletion_requested_for], value)
      )
    }
  end

  def handle_event("delete-pod-cancel", _, state) do
    {
      :noreply,
      update_display(
        state,
        %{}
        |> do_update_in([:ui, :pods, :deletion_requested_for], "")
      )
    }
  end

  def handle_event("delete-pod-indeed", value, state) do
    Phreak.Kube.delete_pod(get_in(state.assigns, [:current_context]), value)
    {
      :noreply,
      update_display(
        state,
        %{}
        |> do_update_in([:ui, :pods, :deletion_requested_for], "")
      )
    }
  end

  def handle_event("ui-context-dropdown", _, state) do
    {
      :noreply,
      update_display(
        state,
        %{}
        |> do_update_in(
             [:ui, :__global, :menus, :context, :is_open],
             !get_in(
               state.assigns,
               [:ui, :__global, :menus, :context, :is_open]
             )
           )
      )
    }
  end

  def handle_event("filter-by-status", value, state) do
    old_filters = get_in(state.assigns, [:ui, :pods, :status_filters])
    ui_status_filters = case value in old_filters do
      true -> List.delete(old_filters, value)
      false -> old_filters ++ [value]
    end
    {
      :noreply,
      update_display(
        state,
        %{}
        |> do_update_in([:ui, :pods, :status_filters], ui_status_filters)
      )
    }
  end

  def handle_event("delete-selected-request", _, state) do
    {
      :noreply,
      update_display(
        state,
        %{}
        |> do_update_in([:ui, :pods, :deletion_requested_for_selection], true)
      )
    }
  end

  def handle_event("delete-pod-selected-cancel", _, state) do
    {
      :noreply,
      update_display(
        state,
        %{}
        |> do_update_in([:ui, :pods, :deletion_requested_for_selection], false)
      )
    }
  end

  def handle_event("delete-selected-pods-indeed", _, state) do
    selected_pod_uids = Enum.map(
      get_in(state.assigns, [:ui, :pods, :selected_map]),
      fn {uid, _} ->
        uid
      end
    )

    Enum.filter(
      get_in(state.assigns, [:ui, :pods, :display_list]),
      fn pod -> pod.data.metadata.uid in selected_pod_uids end
    )
    |> Enum.each(
         fn pod ->
           Phreak.Kube.delete_pod(
             get_in(state.assigns, [:current_context]),
             pod.data.metadata.name
           )
         end
       )
    {
      :noreply,
      update_display(
        state,
        %{}
        |> do_update_in([:ui, :pods, :deletion_requested_for_selection], false)
      )
    }
  end

  def handle_event("data-sort", value, state) do
    direction = case get_in(state.assigns, [:ui, :pods, :sort])[String.to_atom(
      value
                                                               )] do
      nil -> :asc
      :asc -> :desc
      :desc -> :asc
    end

    sort = %{
             name: nil,
             status: nil
           }
           |> Map.put(String.to_atom(value), direction)
    {
      :noreply,
      update_display(
        state,
        %{}
        |> do_update_in([:ui, :pods, :sort], sort)
      )
    }
  end
end
