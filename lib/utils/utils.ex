defmodule Ex.Utils do
  @moduledoc false

  @spec atomize_map_keys(map) :: map | no_return
  def atomize_map_keys(map) do
    Enum.into(map, %{}, &atomize_map_key/1)
  end

  @spec struct_to_map(map) :: map
  def struct_to_map(%{__struct__: _} = struct) do
    struct
    |> Map.from_struct()
    |> struct_to_map()
  end

  def struct_to_map(map) when is_map(map) do
    Enum.into(map, %{}, &do_struct_to_map/1)
  end

  ## Private functions

  defp atomize_map_key({key, value}) when is_binary(key) do
    value = atomize_nested_map(value)
    {String.to_atom(key), value}
  end

  defp atomize_map_key({key, value}) when is_atom(key) do
    value = atomize_nested_map(value)
    {key, value}
  end

  defp atomize_map_key({key, _value}) do
    raise ArgumentError, "only strings and atoms supported as a key, got: #{inspect(key)}"
  end

  defp atomize_nested_map(%{__struct__: _} = value) do
    value
  end

  defp atomize_nested_map(value) when is_map(value) do
    atomize_map_keys(value)
  end

  defp atomize_nested_map(value) do
    value
  end

  defp do_struct_to_map({field, value}) do
    {field, do_struct_to_map(value)}
  end

  defp do_struct_to_map(%{__struct__: _} = struct) do
    struct_to_map(struct)
  end

  defp do_struct_to_map(map) when is_map(map) do
    struct_to_map(map)
  end

  defp do_struct_to_map(key_value) do
    key_value
  end
end
