defmodule ZipInfo.Entry do
  defstruct [:name, :size, :compressed_size]

  @type t :: %__MODULE__{
          name: binary(),
          size: non_neg_integer(),
          compressed_size: non_neg_integer()
        }
end
