defmodule ParseHelpers do
  def nil_or_str(str) when is_nil(str), do: nil
  def nil_or_str(str) do
    str = String.trim(str)
    if str == "", do: nil, else: str
  end
end