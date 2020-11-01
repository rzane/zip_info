defmodule ZipInfo do
  @moduledoc """
  Extracts information from a ZIP file.

  All functions in this module expect a readable, binary IO object.

      iex> File.open("path/to/example.zip", [:read, :binary])
      {:ok, #PID}

  """

  alias ZipInfo.CentralDirectory
  alias ZipInfo.Header
  alias ZipInfo.LocalHeader

  @type reason :: File.posix() | :badarg | :terminated | :invalid

  @doc """
  Count the number of files contained in the ZIP file.

  ## Examples

      iex> ZipInfo.count(io)
      {:ok, 2}

  """
  @spec count(IO.device()) :: {:ok, non_neg_integer()} | {:error, reason}
  def count(io) do
    with {:ok, zip} <- CentralDirectory.find(io) do
      {:ok, zip.count}
    end
  end

  @doc """
  List the files contained in the ZIP file.

  ## Examples

      iex> ZipInfo.list(io)
      {:ok, [%ZipInfo.Header{name: "a.txt"}, %ZipInfo.Header{name: "b.txt"}]}

  """
  @spec list(IO.device()) :: {:ok, [Header.t()]} | {:error, reason}
  def list(io) do
    with {:ok, zip} <- CentralDirectory.find(io) do
      list(io, zip.start, [])
    end
  end

  defp list(io, offset, headers) do
    case Header.read(io, offset) do
      {:ok, header} -> list(io, :cur, headers ++ [header])
      {:error, reason} -> {:error, reason}
      :eof -> {:ok, headers}
    end
  end

  @doc """
  Read raw, compressed bytes from the ZIP for a given entry.

  This will not attempt to decompress the data.

  ## Options

    `:bytes` - The maximum number of bytes to read.

  ## Examples

      iex> ZipInfo.read(io, header)
      {:ok,  "this is content."}

  """
  @spec read(IO.device(), Header.t(), Keyword.t()) :: {:ok, binary()} | {:error, reason}
  def read(io, %Header{offset: offset, compressed_size: size}, opts \\ []) do
    bytes = Keyword.get(opts, :bytes, size)
    LocalHeader.read_data(io, offset, min(bytes, size))
  end

  @doc """
  Format an error returned by this library.

  ## Examples

      iex> ZipInfo.format_error(:invalid)
      "file is corrupt or invalid"

      iex> ZipInfo.format_error(:ebadf)
      "bad file number"

  """
  def format_error(:invalid) do
    "file is corrupt or invalid"
  end

  def format_error(reason) do
    reason
    |> :file.format_error()
    |> to_string()
  end
end
