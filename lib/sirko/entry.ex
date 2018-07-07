defmodule Sirko.Entry do
  @moduledoc """
  Describes data which gets sent by the client.
  """

  defstruct current_path: nil,
            referrer_path: nil,
            assets: []

  @type t :: %__MODULE__{
          current_path: String.t(),
          referrer_path: String.t(),
          assets: [String.t()]
        }
end
