defmodule ZipInfo.Entry do
  @size 46
  @signature <<0x50, 0x4B, 0x01, 0x02>>

  defstruct [
    :name,
    :comment,
    :compressed_size,
    :size,
    :offset
  ]

  def read(io, offset \\ :cur) do
    with {:ok, data} <- :file.pread(io, offset, @size),
         {:ok, entry, sizes} <- parse(data),
         {:ok, name} <- :file.read(io, sizes.name),
         {:ok, _} <- :file.position(io, {:cur, sizes.extra}),
         {:ok, comment} <- :file.read(io, sizes.comment) do
      {:ok, %__MODULE__{entry | name: name, comment: comment}}
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
    entry = %__MODULE__{size: size, compressed_size: compressed_size, offset: offset}
    sizes = %{name: name_length, extra: extra_length, comment: comment_length}
    {:ok, entry, sizes}
  end

  defp parse(_), do: {:error, :invalid}
end
