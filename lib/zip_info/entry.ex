defmodule ZipInfo.Entry do
  defstruct [
    :name,
    :extra,
    :size,
    :compressed_size,
    :flags
  ]

  @type t :: %__MODULE__{
          name: binary(),
          extra: binary(),
          size: non_neg_integer(),
          compressed_size: non_neg_integer(),
          flags: non_neg_integer()
        }
end
