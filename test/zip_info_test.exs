defmodule ZipInfoTest do
  use ZipInfo.Case

  alias ZipInfo.CentralDirectory

  @tag io: "test/fixtures/fixture.zip"
  test "CentralDirectory.find/1", %{io: io} do
    assert {:ok, directory} = CentralDirectory.find(io)
    assert directory.count == 2
    assert directory.start == 170
  end
end
