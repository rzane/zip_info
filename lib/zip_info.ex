defmodule ZipInfo do
  @moduledoc """
  Extracts information from a ZIP file.
  """

  # The standard format for ZIP files is as follows:
  #
  #     [local header 1]                  <- We want to parse this
  #     [compressed data 1 (known size)]  <- Ignore this
  #     [local header 2]                  <- We want to parse this
  #     [compressed data 2 (known size)]  <- Ignore this
  #     [central directory]               <- We're done!
  #
  # However, some zip files (created with `-fd`) only give us partial
  # information and require us to scan the file byte-by-byte.
  #
  #     [local header 1]                 <- We want to parse this
  #     [compress data 1 (unknown size)] <- Ignore this
  #     [data descriptor 1]              <- We also need to parse this
  #     [local header 2]                 <- We want to parse this
  #     [compress data 2 (unknown size)] <- Ignore this
  #     [data descriptor 2]              <- We also need to parse this
  #     [central directory]              <- We're done!
  #
  # For more information, see: https://en.wikipedia.org/wiki/Zip_(file_format)

  alias ZipInfo.Entry

  @local_header <<80, 75, 3, 4>>
  @central_directory <<80, 75, 1, 2>>

  @type error :: File.posix() | :badarg | :terminated | :corrupt

  @doc """
  Creates a new stream that will emit information about each
  file in the ZIP.

  ## Examples

      iex> {:ok, file} = File.open("fixture.zip", [:read, :binary])
      {:ok, #PID<0.107.0>}

      iex> file |> ZipInfo.stream!() |> Enum.to_list()
      [%ZipFile.Entry{name: "a.txt", size: 22, compressed_size: 20}]

  """
  @spec stream!(IO.device()) :: Enum.t()
  def stream!(io) do
    Stream.unfold(:ok, fn :ok -> read!(io) end)
  end

  @doc """
  Lists all of the files in the ZIP.

  ## Examples

      iex> {:ok, file} = File.open("fixture.zip", [:read, :binary])
      {:ok, [%ZipFile.Entry{name: "a.txt", size: 22, compressed_size: 20}]}

  """
  def list(io) do
    list(io, [])
  end

  defp list(io, entries) do
    case read(io) do
      {:ok, entry} -> list(io, entries ++ [entry])
      {:error, reason} -> {:error, reason}
      :eof -> {:ok, entries}
    end
  end

  @doc false
  @spec read!(IO.device()) :: Entry.t() | nil
  def read!(io) do
    case read(io) do
      {:ok, entry} -> {entry, :ok}
      {:error, reason} -> raise ZipInfo.Error, reason: reason
      :eof -> nil
    end
  end

  @doc false
  @spec read(IO.device()) :: {:ok, Entry.t()} | {:error, error} | :eof
  def read(io) do
    with {:ok, data} <- binread(io, 30),
         {:ok, entry, meta} <- parse_local_header(data),
         {:ok, name} <- binread(io, meta.name_length),
         {:ok, _} <- move(io, meta.extra_length),
         {:ok, entry} <- advance(io, entry) do
      {:ok, %Entry{entry | name: name}}
    end
  end

  # This file probably contains a data descriptor. Search for the next
  # header byte-by-byte, then rewind once we've found it.
  defp advance(io, %Entry{compressed_size: 0} = entry) do
    with {:ok, data} <- binread(io, 12) do
      case parse_data_descriptor(data) do
        {:ok, size, compressed_size} ->
          # Reset to begining of header
          with {:ok, _} <- move(io, -4) do
            {:ok, %Entry{entry | size: size, compressed_size: compressed_size}}
          end

        :error ->
          # Try again, starting one byte ahead
          with {:ok, _} <- move(io, -11) do
            advance(io, entry)
          end
      end
    end
  end

  defp advance(io, %Entry{compressed_size: offset} = entry) do
    with {:ok, _} <- move(io, offset) do
      {:ok, entry}
    end
  end

  defp binread(io, count) do
    case IO.binread(io, count) do
      :eof -> :eof
      {:error, reason} -> {:error, reason}
      value -> {:ok, value}
    end
  end

  defp move(io, count) do
    :file.position(io, {:cur, count})
  end

  # This matches a local header
  defp parse_local_header(
         <<@local_header, _version::little-size(16), _flags::little-size(16),
           _compression_method::little-size(16), _last_modified_time::little-size(16),
           _last_modified_date::little-size(16), _crc32::little-size(32),
           compressed_size::little-size(32), size::little-size(32), name_length::little-size(16),
           extra_length::little-size(16)>>
       ) do
    entry = %Entry{size: size, compressed_size: compressed_size}
    meta = %{name_length: name_length, extra_length: extra_length}
    {:ok, entry, meta}
  end

  # This matches the start of the central directory, which tells us that
  # there are no more local headers to parse.
  defp parse_local_header(@central_directory <> _) do
    :eof
  end

  # This scenario would happen under two circumstances:
  #   1. The IO isn't at the start position.
  #   2. You gave us something that doesn't look like a ZIP.
  defp parse_local_header(_), do: {:error, :corrput}

  # This will match the last 8 bytes of a data descriptor, as indicated
  # by the presence of a local header or central directory signature in the
  # last four bytes.
  defp parse_data_descriptor(bytes) do
    case bytes do
      <<compressed_size::little-size(32), size::little-size(32), @local_header>> ->
        {:ok, size, compressed_size}

      <<compressed_size::little-size(32), size::little-size(32), @central_directory>> ->
        {:ok, size, compressed_size}

      _ ->
        :error
    end
  end
end
