defmodule BBLL do
  @moduledoc """
  Documentation for `Bbll`.
  """

  @doc """
  Hello world.

  ## Examples

  """
  def import(file_name) do
    ["data", file_name]
    |> Path.join()
    |> File.read!()
    |> Jason.decode!()
  end
end
