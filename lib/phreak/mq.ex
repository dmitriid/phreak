defmodule Phreak.MQ do
  use GenServer

  def put(book) do
    GenServer.call(:book_update_mq, {:update, book})
  end

  def start_link(_) do
    IO.puts("start_link #{__MODULE__}")
    GenServer.start_link(__MODULE__, :ok, name: :book_update_mq)
  end

  def init(:ok) do
    IO.puts("init #{__MODULE__}")
    {:ok, PSQ.new()}
  end

  def handle_call({:update, book}, _, queue) do
    maybe_book = queue
                 |> PSQ.get(book["isbn"])

    new_queue = case maybe_book do
      nil ->
        b = Map.put(book, "duration", 1)
        queue
        |> PSQ.put(b["isbn"], b, -b["duration"])
      b ->
        duration = b["duration"] + :rand.uniform(100)
        updated = Map.put(b, "duration", duration)
        queue
        |> PSQ.put(updated["isbn"], updated, -updated["duration"])
    end

    Phoenix.PubSub.broadcast(
      Phreak.PubSub,
      "book_updates",
      new_queue
      |> Enum.to_list
      |> Enum.take(20)
    )
    #    IO.inspect(
    #      new_queue
    #      |> Enum.to_list
    #    )

    {:reply, :ok, new_queue}
  end

  def handle_info(
        event,
        #%Watcher.Event{object: object, from: watcher_pid, type: type},
        state
      ) do
    IO.inspect(event)
    #      case object do
    #        %Kazan.Apis.Core.V1.Namespace{} = namespace ->
    #          process_namespace_event(type, namespace)
    #
    #        %Kazan.Apis.Batch.V1.Job{} = job ->
    #          process_job_event(type, job)
    #      end
    {:noreply, state}
  end
end
