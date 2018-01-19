defmodule Support.Error1 do
  defexception [:term]

  def message(exception) do
    "#{__MODULE__}: #{exception.term}"
  end
end

defmodule Support.Error2 do
  defexception [:term]

  def message(exception) do
    "#{__MODULE__}: #{exception.term}"
  end
end

defmodule Support.Error3 do
  defexception [:term]

  def message(exception) do
    "#{__MODULE__}: #{exception.term}"
  end
end
