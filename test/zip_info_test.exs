defmodule ZipInfoTest do
  use ZipInfo.Case
  doctest ZipInfo

  @tag io: "test/fixtures/fixture.zip"
  test "ZipInfo.read/1", %{io: io} do
    assert {:ok, a} = ZipInfo.read(io)
    assert a.filename == "a.txt"

    assert {:ok, b} = ZipInfo.read(io)
    assert b.filename == "b.txt"

    assert :eof = ZipInfo.read(io)
  end
end
