defmodule ZipInfoTest do
  use ZipInfo.Case
  doctest ZipInfo

  @tag io: "test/fixtures/fixture.zip"
  test "ZipInfo.read/1", %{io: io} do
    assert {:ok, header} = ZipInfo.read(io)

    assert header == %ZipInfo{
             name: "a.txt",
             compressed_size: 22,
             uncompressed_size: 22
           }
  end
end
