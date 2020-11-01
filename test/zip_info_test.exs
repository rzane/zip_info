defmodule ZipInfoTest do
  use ZipInfo.Case

  alias ZipInfo.CentralDirectory
  alias ZipInfo.Header

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

  @tag io: "test/fixtures/fixture.zip"
  test "ZipInfo.list/1", %{io: io} do
    assert {:ok, [_, _]} = ZipInfo.list(io)
  end
end
