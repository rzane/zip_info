defmodule ZipInfo.Error do
  defexception [:message, :reason]

  @impl true
  def exception(reason: reason) do
    %ZipInfo.Error{reason: reason, message: translate(reason)}
  end

  defp translate(:corrupt), do: "the zip file might be corrupt"
  defp translate(reason), do: reason |> :file.format_error() |> to_string()
end
