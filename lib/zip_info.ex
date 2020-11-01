defmodule ZipInfo do
  @moduledoc """
  Reads and parses the headers inside a zip file.
  """

  alias ZipInfo.Entry

  @type error :: File.posix() | :badarg | :terminated

  @doc false
  @spec read(IO.device()) :: {:ok, Entry.t()} | {:error, error} | :eof
  def read(io) do
    with {:ok, data} <- binread(io, 30),
         {:ok, header, meta} <- parse(data),
         {:ok, name} <- binread(io, meta.name_length),
         {:ok, extra} <- binread(io, meta.extra_length),
         {:ok, _} <- ignore(io, header.compressed_size) do
      {:ok, %Entry{header | name: name, extra: extra}}
    end
  end

  defp binread(io, count) do
    case IO.binread(io, count) do
      :eof -> :eof
      {:error, reason} -> {:error, reason}
      value -> {:ok, value}
    end
  end

  defp ignore(io, offset) do
    :file.position(io, {:cur, offset})
  end

  # https://en.wikipedia.org/wiki/Zip_(file_format)#Local_file_header
  defp parse(
         <<0x04034B50::little-size(32), _version::little-size(16), flags::little-size(16),
           _compression_method::little-size(16), _last_modified_time::little-size(16),
           _last_modified_date::little-size(16), _crc32::little-size(32),
           compressed_size::little-size(32), size::little-size(32), name_length::little-size(16),
           extra_length::little-size(16)>>
       ) do
    header = %Entry{
      flags: flags,
      size: size,
      compressed_size: compressed_size
    }

    meta = %{
      name_length: name_length,
      extra_length: extra_length
    }

    {:ok, header, meta}
  end

  # https://en.wikipedia.org/wiki/Zip_(file_format)#Central_directory_file_header
  defp parse(<<0x02014B50::little-size(32)>> <> _) do
    :eof
  end

  defp parse(_) do
    {:error, :corrput}
  end
end
