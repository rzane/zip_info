defmodule ZipInfo do
  @moduledoc """
  Reads and parses the headers inside a zip file.
  """

  defstruct [
    :filename,
    :filename_length,
    :extra,
    :extra_length,
    :compressed_size,
    :uncompressed_size
  ]

  @type error :: File.posix() | :badarg | :terminated

  @type t :: %__MODULE__{
          filename: binary(),
          filename_length: non_neg_integer(),
          extra: binary(),
          extra_length: non_neg_integer(),
          compressed_size: non_neg_integer(),
          uncompressed_size: non_neg_integer()
        }

  @doc false
  @spec read(IO.device()) :: {:ok, t()} | {:error, error} | :eof
  def read(io) do
    with {:ok, data} <- binread(io, 30),
         {:ok, header} <- parse(data),
         {:ok, filename} <- binread(io, header.filename_length),
         {:ok, extra} <- binread(io, header.extra_length),
         {:ok, _} <- ignore(io, header.compressed_size) do
      {:ok, %__MODULE__{header | filename: filename, extra: extra}}
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

  defmacrop uint(size) do
    quote do: little - signed - integer - size(unquote(size))
  end

  # https://en.wikipedia.org/wiki/Zip_(file_format)#Local_file_header
  defp parse(
         <<80, 75, 3, 4, _version::uint(16), _flag::uint(16), _compression_method::uint(16),
           _mtime::uint(16), _mdate::uint(16), _crc32::uint(32), compressed_size::uint(32),
           uncompressed_size::uint(32), filename_length::uint(16), extra_length::uint(16)>>
       ) do
    header = %__MODULE__{
      compressed_size: compressed_size,
      uncompressed_size: uncompressed_size,
      filename_length: filename_length,
      extra_length: extra_length
    }

    {:ok, header}
  end

  # https://en.wikipedia.org/wiki/Zip_(file_format)#Central_directory_file_header
  defp parse(<<80, 75, 1, 2>> <> _), do: :eof

  defp parse(_), do: {:error, :corrput}
end
