defmodule ZipInfoTest do
  use ZipInfo.Case

  alias ZipInfo.CentralDirectory
  alias ZipInfo.Entry

  @tag io: "test/fixtures/fixture.zip"
  test "CentralDirectory.find/1", %{io: io} do
    assert {:ok, directory} = CentralDirectory.find(io)
    assert directory.count == 2
    assert directory.start == 170
  end

  @tag io: "test/fixtures/fixture.zip"
  test "Entry.read/2", %{io: io} do
    assert {:error, :invalid} = Entry.read(io)

    assert {:ok, entry} = Entry.read(io, 170)
    assert entry.name == "a.txt"
    assert entry.size == 22
    assert entry.compressed_size == 22
    assert entry.offset == 0
    assert entry.comment == ""

    assert {:ok, entry} = Entry.read(io)
    assert entry.name == "b.txt"
    assert entry.size == 22
    assert entry.compressed_size == 22
    assert entry.offset == 85
    assert entry.comment == ""
  end
end
