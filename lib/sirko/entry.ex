defmodule Sirko.Entry do
  @moduledoc """
  Describes data which gets sent by the client.
  """

  defstruct current_path:  nil,
            referrer_path: nil,
            assets:        []
end
