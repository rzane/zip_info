defmodule ZipInfo.Entry do
  defstruct [:name, :size, :compressed_size, :position]

  @type position :: {non_neg_integer(), non_neg_integer()}

  @type t :: %__MODULE__{
          name: binary(),
          size: non_neg_integer(),
          compressed_size: non_neg_integer(),
          position: position()
        }
end
