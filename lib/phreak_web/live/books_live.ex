defmodule PhreakWeb.BooksLive do
  @moduledoc false

  use Phoenix.LiveView
  alias Phreak.BooksView

  def render(assigns), do: BooksView.render("list.html", assigns)
  #  def render(assigns) do
  #    ~L"""
  #    <div>
  #      <h1 phx-click="boom">The count is: <%= @val %></h1>
  #      <button phx-click="reset" class="alert-danger">BOOM</button>
  #      <button phx-click="dec">-</button>
  #      <button phx-click="inc">+</button>
  #    </div>
  #
  #
  #    <div>
  #      <h1>Books</h1>
  #
  #      <ol>
  #        <%= Enum.each(@books) ->  %>
  #      </ol>
  #    </div>
  #    """
  #  end

  def mount(_session, socket) do
    Phoenix.PubSub.subscribe(
      Phreak.PubSub,
      "book_updates"
    )
    {:ok, assign(socket, :books, [])}
  end

  def handle_info(books, socket) do
    #IO.inspect(books)

    {:noreply, assign(socket, :books, books)}
  end
end
