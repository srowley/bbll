defmodule BBLL.Franchise do

  @franchise_key %{
      "0011" => "Ephraim",
      "0013" => "Volki",
      "0010" => "Irin",
      "0002" => "Aaron",
      "0005" => "Danny",
      "0004" => "Dave",
      "0006" => "Steve",
      "0012" => "Eric",
      "0001" => "Moishe",
      "0007" => "Erik",
      "0009" => "TNT",
      "0003" => "Jerry",
      "0008" => "Bob",
      "0014" => "Chad"
    }

  def owner(id) do
    Enum.find(@franchise_key, fn {franchise, _owner}-> franchise == id end)
    |> elem(1)
  end
end
