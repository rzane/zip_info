defmodule ZipInfo.Header do
  @moduledoc """
  Represents a file inside the ZIP archive.
  """

  @size 46
  @signature <<0x50, 0x4B, 0x01, 0x02>>
  @end_signature <<0x50, 0x4B, 0x05, 0x06>>

  @type location :: integer() | :cur

  @type t :: %__MODULE__{
          name: binary(),
          comment: binary(),
          offset: non_neg_integer(),
          size: non_neg_integer(),
          compressed_size: non_neg_integer()
        }

  defstruct [
    :name,
    :comment,
    :size,
    :offset,
    :compressed_size
  ]

  @doc false
  @spec read(IO.device(), location()) :: {:ok, t} | {:error, ZipInfo.reason()} | :eof
  def read(io, location \\ :cur) do
    with {:ok, data} <- :file.pread(io, location, @size),
         {:ok, header, sizes} <- parse(data),
         {:ok, name} <- :file.read(io, sizes.name),
         {:ok, _} <- :file.position(io, {:cur, sizes.extra}),
         {:ok, comment} <- :file.read(io, sizes.comment) do
      {:ok, %__MODULE__{header | name: name, comment: comment}}
    end
  end

  defp parse(<<
         @signature,
         _version::little-size(16),
         _min_version::little-size(16),
         _flags::little-size(16),
         _compression_method::little-size(16),
         _mtime::little-size(16),
         _mdate::little-size(16),
         _crc32::binary-size(4),
         compressed_size::little-size(32),
         size::little-size(32),
         name_length::little-size(16),
         extra_length::little-size(16),
         comment_length::little-size(16),
         _disk_start::little-size(16),
         _internal_file_attributes::little-size(16),
         _external_file_attributes::little-size(32),
         offset::little-size(32)
       >>) do
    header = %__MODULE__{size: size, compressed_size: compressed_size, offset: offset}
    sizes = %{name: name_length, extra: extra_length, comment: comment_length}
    {:ok, header, sizes}
  end

  defp parse(<<@end_signature>> <> _), do: :eof
  defp parse(_), do: {:error, :invalid}
end
