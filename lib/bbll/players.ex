defmodule BBLL.Players do
  def from_json do
    ["data", "BBLL_players.json"]
    |> Path.join()
    |> File.read!()
    |> Jason.decode!()
    |> get_in(["players", "player"])
    |> Enum.map(&string_to_atom_keys/1)
    |> Enum.filter(fn record -> record.position in ["QB", "RB", "TE", "WR"] end)
  end

  defp string_to_atom_keys(map) do
    map
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    |> Enum.into(%{})
  end
end
