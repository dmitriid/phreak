defmodule Phreak.MockPubsub do
  use Task
  alias Phreak.MQ

  def start_link(opts \\ []) do

    IO.puts("start_link #{__MODULE__}")

    {:ok, data} = File.read(
      "/Users/dmitrii.dimandt/Projects/elixir/phreak/books.json"
    )

    {:ok, books} = Jason.decode(data)

    Task.start_link(__MODULE__, :run, [books])
  end

  def run(books) do
    random_books = Enum.take_random(books, Enum.count(books))

    Enum.each(
      random_books,
      fn book -> MQ.put(book) end
    )

    Process.sleep(:rand.uniform(1000))
    run(books)
  end
end
