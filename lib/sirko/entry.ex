defmodule Sirko.Entry do
  @moduledoc """
  Describes data which gets sent by the client.
  """

  @enforce_keys [:current_path, :referrer_path]

  defstruct current_path: nil,
            referrer_path: nil,
            assets: []

  @type t :: %__MODULE__{
          current_path: String.t(),
          referrer_path: String.t(),
          assets: [String.t()]
        }

  @spec new(attrs :: Keyword.t()) :: t()
  def new(attrs) do
    struct(__MODULE__, attrs)
  end
end
