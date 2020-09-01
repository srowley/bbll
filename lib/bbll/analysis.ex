defmodule BBLL.Analysis do

  alias BBLL.Draft

  defguard is_numeric_id(id) when byte_size(id) < 7

  @leagues_data Enum.map(Draft.all_leagues(), &Draft.new_from_json/1)
  @players_data BBLL.Players.from_json()

  def all_adps do
    all_players_picked()
    |> Enum.take(162)
    |> Enum.map(fn id -> {player_name(id), adp(id), elem(draft_positions(id), 1)} end)
    |> Enum.sort_by(&elem(&1, 1))
  end

  def all_players_picked do
    @leagues_data
    |> List.flatten()
    |> Enum.map(fn pick -> pick.player_data end)
    |> Enum.uniq()
  end

  def owners(player_id) when is_numeric_id(player_id) do
    @leagues_data
    |> Enum.map(fn picks -> Enum.find(picks, %{owner: "None"}, fn pick -> pick.player == player_id end) end)
    |> Enum.map(fn pick -> Map.get(pick, :owner) end)
  end

  def owners(name) do
    Enum.find(@players_data, fn player_record -> player_record.name == name end)
    |> Map.get(:id)
    |> owners()
  end

  def draft_positions(player_id) when is_numeric_id(player_id) do
    @leagues_data
    |> Enum.map(fn draft -> Enum.find(draft, fn picks -> picks.player == player_id end) end)
    |> Enum.with_index()
    |> Enum.map(fn {pick, index} -> %{
      owner: pick[:owner] || "None",
      overall: pick[:overall] || "Not Drafted",
      round_and_pick: pick[:round_and_pick] || "Not Drafted",
      league: pick[:league] || ("BBLL" <> to_string(index + 1))
      }
    end)
  end

  def draft_positions(name), do: draft_positions(player_id(name))

  def adp(player_id) when is_numeric_id(player_id) do
    draft_positions =
      player_id
      |> draft_positions()
      |> Enum.reject(fn pick -> pick.owner == "None" end)
      |> Enum.map(fn pick -> pick.overall end)

    Enum.sum(draft_positions)
    |> Kernel./(length(draft_positions))
  end

  def adp(name), do: adp(player_id(name))

  def highest(player_id) when is_numeric_id(player_id) do
    player_id
    |> draft_positions()
    |> Enum.reject(fn pick -> pick.owner == "None" end)
    |> Enum.map(fn pick -> pick.overall end)
    |> Enum.min()
  end

  def highest(name), do: highest(player_id(name))

  def lowest(player_id) when is_numeric_id(player_id) do
    player_id
    |> draft_positions()
    |> Enum.reject(fn pick -> pick.owner == "None" end)
    |> Enum.map(fn pick -> pick.overall end)
    |> Enum.max()
  end

  def lowest(name), do: lowest(player_id(name))

  def player_name(id) do
    Enum.find(@players_data, fn player_record -> player_record.id == id end)
    |> Map.get(:name)
  end

  def player_id(name) do
    Enum.find(@players_data, fn player_record -> player_record.name == name end)
    |> Map.get(:id)
  end

  def adp_to_round(adp, rounds) do
    round = ceil(floor(adp) / rounds)
    pick = rem(floor(adp), rounds) |> to_string |> String.pad_leading(2, "0")
    if pick == 0 do
      "#{round}.#{rounds}"
    else
      "#{round}.#{pick}"
    end
  end

  def adp_summary_data do
    all_players_picked()
    |> Enum.map(fn p ->
      %{
        name: player_name(p.id),
        team: p.team,
        position: p.position,
        adp: adp(p.id),
        highest: highest(p.id),
        lowest: lowest(p.id),
        draft_history: draft_positions(p.id)}
      end)
    |> Enum.sort_by(fn x -> x.adp end)
  end

  def adp_summary_to_csv do
    format_history = fn pick_list -> Enum.map_join(pick_list, ",", fn pair -> ~s|"#{elem(pair, 0)}","#{elem(pair, 1)}","#{elem(pair, 2)}"| end) end
    pick_to_string = fn pick -> ~s|"#{pick.name}","#{pick.team}","#{pick.position}","#{pick.adp}","#{pick.highest}","#{pick.lowest}",#{format_history.(pick.draft_history)}| end

    adp_summary_data()
    |> Enum.map_join("\n", pick_to_string)
    |> String.replace_prefix("", "Name,Team,Position,ADP,Highest,Lowest,BBLL1 Owner,BBLL1 Overall,BBLL1 Pick,BBLL2 Owner,BBLL 2 Overall,BBLL2 Pick,BBLL3 Owner,BBL3 Overall,BBLL3 Pick,BBLL4 Owner,BBLL4 Overall,BBLL4 Pick\n")
    |> to_file("picks.csv")
  end

  def man_crush do
    @leagues_data
    |> List.flatten()
    |> Enum.frequencies_by(fn pick -> {pick.owner, pick.player_data.name} end)
    |> Enum.map(fn record -> %{owner: elem(elem(record, 0), 0), player_name: elem(elem(record, 0), 1), num_leagues: elem(record, 1)} end)
    |> Enum.sort_by(fn %{num_leagues: num_leagues, owner: owner} -> {num_leagues, owner} end, :desc)
  end

  def man_crush_to_csv do
    man_crush()
    |> Enum.map_join("\n", fn record -> ~s|"#{record.owner}","#{record.player_name}","#{record.num_leagues}"| end)
    |> String.replace_prefix("", "Owner,Player,# Leagues\n")
    |> to_file("man_crush.csv")
  end

  defp to_file(string, file), do: File.write!(file, string)
end
