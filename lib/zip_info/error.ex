defmodule ZipInfo.Error do
  defexception [:message, :reason]

  @impl true
  def exception(reason: reason) do
    %ZipInfo.Error{reason: reason, message: translate(reason)}
  end

  defp translate(:invalid), do: "the zip file has an invalid format"
  defp translate(reason), do: reason |> :file.format_error() |> to_string()
end
