defmodule ScrumPokerWeb.HomeLive do
  use ScrumPokerWeb, :live_view
  use ScrumPokerNative, :live_view

  alias ScrumPokerWeb.Presence

  @topic "users:poker"

  @impl true
  def mount(_params, _session, socket) do
    if(connected?(socket)) do
      Phoenix.PubSub.subscribe(ScrumPoker.PubSub, @topic);
    end

    presences = Presence.list(@topic)
    socket = socket
    |> assign(diff: nil)
    |> assign(revealed: false)
    |> assign(result: nil)
    |> assign(room_id: nil)
    |> assign(current_user: nil, spectator: false, joined: false, vote: nil)
    |> assign(users: simple_presence_map(presences))

    {:ok, socket}
  end

  @impl true
  def handle_event("join", %{"name" => name}, socket) do
    userName = name |> String.trim() |> String.capitalize()

    if(connected?(socket)) do
      pid = self() |> :erlang.pid_to_list() |> List.to_string();
      regex = ~r/<0\.(\d+)\.0>/
      [_, pidId] = Regex.run(regex, pid)

      {:ok, _} = Presence.track(self(), @topic, userName , %{
        username: userName,
        joined: true,
        voted: false,
        vote: ''
      })
    end

    presences = Presence.list(@topic)
    socket = assign(socket, joined: true, current_user: userName, users: simple_presence_map(presences))

    {:noreply, socket}
  end

  def handle_event("update", %{"room" => room, "name" => name, "spectator" => spectator}, socket) do
    socket = assign(socket,
      room_id: return_string_or_nil(room),
      current_user: return_string_or_nil(name),
      spectator: return_bool_from_string(spectator)
    )

    {:noreply, socket}
  end

  defp return_string_or_nil(value) do
    case value do
      "" -> nil
      _ -> value
    end
  end

  defp return_bool_from_string(value) do
    case value do
      "true" -> true
      "false" -> false
    end
  end

  def handle_event("select", %{"vote" => vote}, socket) do
    %{current_user: current_user} = socket.assigns
    isDeselected = vote == socket.assigns.vote
    voteValue = if isDeselected, do: '', else: vote

    %{metas: [meta | _]} = Presence.get_by_key(@topic, current_user)
    new_meta = %{meta | voted: !isDeselected, vote: voteValue}
    Presence.update(self(), @topic, current_user, new_meta)

    users_count = socket.assigns.users |> Map.size()
    vote_count = Presence.list(@topic) |> Enum.filter(fn {_, %{metas: [meta | _]}} -> meta.voted end) |> Enum.count()
    votes = Presence.list(@topic) |> Enum.map(fn {_, %{metas: [meta | _]}} -> meta.vote end)
    result = get_result(users_count, vote_count, votes)

    Phoenix.PubSub.broadcast(ScrumPoker.PubSub, @topic, %{event: "result", payload: result})

    socket = assign(socket, vote: voteValue, result: result)
    {:noreply, socket}
  end

  defp get_result(users_count, vote_count, votes) do
    case users_count === vote_count do
      false -> nil
      _ -> find_most_frequent(votes)
    end
  end

  def find_most_frequent(list) do
    frequencies = Enum.frequencies(list)

    list
    |> Enum.max_by(fn item -> frequencies[item] end)
  end

  defp simple_presence_map(presences) do
    Enum.into(presences, %{}, fn {user_id, %{metas: [meta | _]}} -> {user_id, meta} end)
  end

  def handle_info(%{event: "result", payload: vote}, socket) do
    socket = assign(socket, result: vote)
    {:noreply, socket}
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    socket =
      socket
      |> remove_presences(diff.leaves)
      |> add_presences(diff.joins)

    {:noreply, socket}
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
