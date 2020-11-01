defmodule ZipInfo.CentralDirectory do
  @moduledoc false

  @size 22
  @signature <<0x50, 0x4B, 0x05, 0x06>>

  @enforce_keys [:start, :count]
  defstruct [:start, :count]

  def find(io) do
    find(io, {:eof, -@size})
  end

  defp find(io, location) do
    with {:ok, data} <- :file.pread(io, location, @size),
         :cont <- parse(data),
         do: find(io, {:cur, -1})
  end

  defp parse(<<
         @signature,
         _disk_number::little-size(16),
         _start_disk_number::little-size(16),
         _count_on_disk::little-size(16),
         count::little-size(16),
         _central_directory_size::little-size(32),
         start::little-size(32),
         _comment_length::little-size(16)
       >>) do
    {:ok, %__MODULE__{start: start, count: count}}
  end

  defp parse(data) when byte_size(data) == @size, do: :cont
  defp parse(_), do: {:error, :invalid}
end
