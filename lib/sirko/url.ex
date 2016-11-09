defmodule Sirko.Url do
  def extract_path(nil), do: nil

  def extract_path(url) do
    %{ path: path } = URI.parse(url)

    path
  end
end
