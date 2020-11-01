defmodule ZipInfoTest do
  use ZipInfo.Case

  alias ZipInfo.Entry

  @tag io: "test/fixtures/fixture.zip"
  test "list/1", %{io: io} do
    assert {:ok, [a, b]} = ZipInfo.list(io)
    assert a == %Entry{name: "a.txt", size: 22, compressed_size: 22}
    assert b == %Entry{name: "b.txt", size: 22, compressed_size: 22}
  end

  @tag io: "test/fixtures/fixture-data-descriptor.zip"
  test "list/1 with a data descriptor", %{io: io} do
    assert {:ok, [a, b]} = ZipInfo.list(io)
    assert a == %Entry{name: "a.txt", size: 22, compressed_size: 24}
    assert b == %Entry{name: "b.txt", size: 22, compressed_size: 24}
  end

  @tag io: "test/fixtures/fixture-corrupt.zip"
  test "list/1 when io is corrupt", %{io: io} do
    assert {:error, :invalid} = ZipInfo.list(io)
  end

  @tag io: "test/fixtures/fixture.zip"
  test "stream!/1", %{io: io} do
    assert [_, _] = Enum.to_list(ZipInfo.stream!(io))
  end

  @tag io: "test/fixtures/fixture-data-descriptor.zip"
  test "stream!/1 with a data descriptor", %{io: io} do
    assert [_, _] = Enum.to_list(ZipInfo.stream!(io))
  end

  @tag io: "test/fixtures/fixture-corrupt.zip"
  test "stream!/1 when io is corrupt", %{io: io} do
    assert_raise ZipInfo.Error, "the zip file has an invalid format", fn ->
      Stream.run(ZipInfo.stream!(io))
    end
  end
end
