defmodule ZipInfo do
  @moduledoc """
  Reads and parses the headers inside a zip file.

  See: https://en.wikipedia.org/wiki/Zip_(file_format)#Local_file_header
  """

  defstruct [:name, :compressed_size, :uncompressed_size]

  @type error :: File.posix() | :badarg | :terminated | :corrupt

  @type t :: %__MODULE__{
          name: binary(),
          compressed_size: non_neg_integer(),
          uncompressed_size: non_neg_integer()
        }

  defmacrop uint(size) do
    quote do: little - signed - integer - size(unquote(size))
  end

  @doc false
  @spec read(IO.device()) :: {:ok, t()} | {:error, error}
  def read(io) do
    with {:ok, data} <- binread(io, 30),
         {:ok, {header, name_length, _extra_length}} <- parse(data),
         {:ok, name} <- binread(io, name_length) do
      {:ok, %__MODULE__{header | name: name}}
    end
  end

  defp binread(io, count) do
    case IO.binread(io, count) do
      :eof -> {:error, :eof}
      {:error, reason} -> {:error, reason}
      value -> {:ok, value}
    end
  end

  defp parse(
         <<80, 75, 3, 4, _version::uint(16), _flag::uint(16), _compression_method::uint(16),
           _mtime::uint(16), _mdate::uint(16), _crc32::uint(32), compressed_size::uint(32),
           uncompressed_size::uint(32), name_length::uint(16), extra_length::uint(16)>>
       ) do
    header = %__MODULE__{
      compressed_size: compressed_size,
      uncompressed_size: uncompressed_size
    }

    {:ok, {header, name_length, extra_length}}
  end

  defp parse(_), do: {:error, :corrupt}
end
