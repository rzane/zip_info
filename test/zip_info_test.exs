defmodule ZipInfoTest do
  use ZipInfo.Case

  alias ZipInfo.CentralDirectory
  alias ZipInfo.Header

  @tag io: "test/fixtures/fixture.zip"
  test "fixture.zip", %{io: io} do
    assert {:ok, 2} = ZipInfo.count(io)
    assert {:ok, [a, _]} = ZipInfo.list(io)
    assert {:ok, "Hello!" <> _} = ZipInfo.read(io, a)
    assert {:ok, "Hello"} = ZipInfo.read(io, a, bytes: 5)
  end

  @tag io: "test/fixtures/fixture-data-descriptor.zip"
  test "fixture-data-descriptor", %{io: io} do
    assert {:ok, 2} = ZipInfo.count(io)
    assert {:ok, [_, b]} = ZipInfo.list(io)
    assert {:ok, <<_::binary-size(24)>>} = ZipInfo.read(io, b)
    assert {:ok, <<_::binary-size(5)>>} = ZipInfo.read(io, b, bytes: 5)
  end

  @tag io: "test/fixtures/fixture-corrupt.zip"
  test "fixture-corrupt", %{io: io} do
    assert {:error, :invalid} = ZipInfo.count(io)
    assert {:error, :invalid} = ZipInfo.list(io)
  end

  @tag io: "test/fixtures/fixture.zip"
  test "CentralDirectory.find/1", %{io: io} do
    assert {:ok, directory} = CentralDirectory.find(io)
    assert directory.count == 2
    assert directory.start == 170
  end

  @tag io: "test/fixtures/fixture.zip"
  test "Header.read/2", %{io: io} do
    assert {:error, :invalid} = Header.read(io)

    assert {:ok, header} = Header.read(io, 170)
    assert header.name == "a.txt"
    assert header.size == 22
    assert header.compressed_size == 22
    assert header.offset == 0
    assert header.comment == ""

    assert {:ok, header} = Header.read(io)
    assert header.name == "b.txt"
    assert header.size == 22
    assert header.compressed_size == 22
    assert header.offset == 85
    assert header.comment == ""

    assert :eof = Header.read(io)
  end
end
