defmodule ZipInfo do
  @moduledoc """
  Extracts information from a ZIP file.

  All functions in this module expect a readable, binary IO object.

      iex> File.open("path/to/example.zip", [:read, :binary])
      {:ok, #PID}

  """

  alias ZipInfo.CentralDirectory
  alias ZipInfo.Header

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

  defp list(io, offset, entries) do
    case Header.read(io, offset) do
      {:ok, header} -> list(io, :cur, entries ++ [header])
      {:error, reason} -> {:error, reason}
      :eof -> {:ok, entries}
    end
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
