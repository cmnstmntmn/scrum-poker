defmodule ScrumPokerWeb.HomeLive do
  use ScrumPokerWeb, :live_view
  use ScrumPokerNative, :live_view

  alias ScrumPokerWeb.Presence

  @topic "users:poker"

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(ScrumPoker.PubSub, @topic)

    presences = Presence.list(@topic)
    socket = socket
    |> assign(diff: nil, revealed: false, result: nil, room_id: nil)
    |> assign(current_user: nil, spectator: false, joined: false, vote: nil)
    |> assign(users: simple_presence_map(presences))

    {:ok, socket}
  end

  @impl true
  def handle_event("join", %{"name" => name}, socket) do
    user_name = name |> String.trim() |> String.capitalize()

    if connected?(socket) do
      {:ok, _} = Presence.track(self(), @topic, user_name, %{
        username: user_name,
        joined: true,
        voted: false,
        vote: ''
      })
    end

    presences = Presence.list(@topic)
    socket = assign(socket, joined: true, current_user: user_name, users: simple_presence_map(presences))

    {:noreply, socket}
  end

  @impl true
  def handle_event("update", %{"room" => room, "name" => name, "spectator" => spectator}, socket) do
    socket = assign(socket,
      room_id: return_string_or_nil(room),
      current_user: return_string_or_nil(name),
      spectator: return_bool_from_string(spectator)
    )

    {:noreply, socket}
  end

  def handle_event("select", %{"vote" => vote}, socket) do
    %{current_user: current_user} = socket.assigns
    is_deselected = vote == socket.assigns.vote
    vote_value = if is_deselected, do: '', else: vote

    %{metas: [meta | _]} = Presence.get_by_key(@topic, current_user)
    new_meta = %{meta | voted: !is_deselected, vote: vote_value}
    Presence.update(self(), @topic, current_user, new_meta)

    users_count = socket.assigns.users |> Map.size()
    vote_count = Presence.list(@topic) |> Enum.filter(fn {_, %{metas: [meta | _]}} -> meta.voted end) |> Enum.count()
    votes = Presence.list(@topic) |> Enum.map(fn {_, %{metas: [meta | _]}} -> meta.vote end)
    result = get_result(users_count, vote_count, votes)

    Phoenix.PubSub.broadcast(ScrumPoker.PubSub, @topic, %{event: "result", payload: result})

    socket = assign(socket, vote: vote_value, result: result)
    {:noreply, socket}
  end

  def handle_info(%{event: "result", payload: result}, socket) do
    socket = assign(socket, result: result)
    {:noreply, socket}
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    socket =
      socket
      |> remove_presences(diff.leaves)
      |> add_presences(diff.joins)

    {:noreply, socket}
  end

  defp return_string_or_nil(""), do: nil
  defp return_string_or_nil(value), do: value

  defp return_bool_from_string("true"), do: true
  defp return_bool_from_string("false"), do: false

  defp get_result(users_count, vote_count, votes) when users_count == vote_count, do: find_most_frequent(votes)
  defp get_result(_, _, _), do: nil

  defp find_most_frequent(list) do
    list
    |> Enum.frequencies()
    |> Enum.max_by(fn {_item, count} -> count end)
    |> elem(0)
  end

  defp simple_presence_map(presences) do
    Enum.into(presences, %{}, fn {user_id, %{metas: [meta | _]}} -> {user_id, meta} end)
  end

  defp remove_presences(socket, leaves) do
    user_ids = Enum.map(leaves, &elem(&1, 0))
    presences = Map.drop(socket.assigns.users, user_ids)
    assign(socket, :users, presences)
  end

  defp add_presences(socket, joins) do
    presences = Map.merge(socket.assigns.users, simple_presence_map(joins))
    assign(socket, :users, presences)
  end
end
