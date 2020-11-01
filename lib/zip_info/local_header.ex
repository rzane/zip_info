defmodule ZipInfo.LocalHeader do
  @moduledoc false

  @size 30
  @signature <<0x50, 0x4B, 0x03, 0x04>>

  @doc false
  def read_data(io, location, bytes) do
    with {:ok, data} <- :file.pread(io, location, @size),
         {:ok, offset} <- parse_offset(data) do
      :file.pread(io, {:cur, offset}, bytes)
    end
  end

  defp parse_offset(
         <<@signature, _::binary-size(22), name_length::little-size(16),
           extra_length::little-size(16)>>
       ) do
    {:ok, name_length + extra_length}
  end

  defp parse_offset(_), do: {:error, :invalid}
end
