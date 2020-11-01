defmodule ZipInfo.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      import ZipInfo.Case
    end
  end

  setup context do
    if io = context[:io] do
      {:ok, io: open(io)}
    else
      :ok
    end
  end

  def open(path) do
    file = File.open!(path, [:read, :binary])
    on_exit(fn -> File.close(file) end)
    file
  end
end
