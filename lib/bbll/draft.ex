defmodule BBLL.Draft do

  @player_data BBLL.Players.from_json()

  def all_leagues, do: ["BBLL1", "BBLL2", "BBLL3", "BBLL4", "BBLL5", "BBLL6", "BBLL7"]

  def new_from_json(league_name) do
    league_name <> "_draftresults.json"
    |> BBLL.import()
    |> get_in(["draftResults", "draftUnit", "draftPick"])
    |> Enum.reject(fn pick -> pick["player"] == "" end)
    |> Enum.map(fn pick -> Map.take(pick, ["franchise", "player", "pick", "round"]) end)
    |> Enum.map(&string_to_atom_keys/1)
    |> Enum.map(fn pick -> Map.put(pick, :overall, convert_to_overall(pick)) end)
    |> Enum.map(fn pick -> Map.put(pick, :round_and_pick, format_round_and_pick(pick)) end)
    |> Enum.map(fn pick -> Map.put(pick, :player_data, player_data(pick.player)) end)
    |> Enum.map(fn pick -> Map.put(pick, :owner, BBLL.Franchise.owner(pick.franchise)) end)
    |> Enum.map(fn pick -> Map.put(pick, :league, league_name) end)
  end

  defp convert_to_overall(pick) do
    (String.to_integer(pick.round) - 1) * 14 + String.to_integer(pick.pick)
  end

  defp format_round_and_pick(pick) do
    String.replace_prefix(pick.round, "0", "") <> "." <> pick.pick
  end

  defp string_to_atom_keys(map) do
    map
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    |> Enum.into(%{})
  end

  defp player_data(id) do
    Enum.find(@player_data, fn player -> player.id == id end)
  end
end
