defmodule Edison do
  @defaults [
    threshold: 2,
    threshold_interval: 60_000,
    reset_after: 5_000,
    rescue_from: nil
  ]

  @available_state {:available, :circuit_closed}
  @on_error_unavailable_state {:unavailable, :circuit_closed} # Error happened but circuit did not opened yet
  @on_open_unavailable_state {:unavailable, :circuit_open}

  defmacro circuit_breaker(name, function) do
    config = :edison
    |> Application.get_env(:circuit_breaker, [])
    |> Keyword.get(name, @defaults)
    |> Enum.into(%{})

    config = Map.merge(@defaults |> Enum.into(%{}), config)
    circuit_breaker_quoted(config, name, function)
  end

  def state_of(name) do
    case :fuse.ask(name, :sync) do
      :ok -> @available_state
      {:error, :not_found} -> @available_state
      :blown -> {:unavailable, :circuit_open}
    end
  end

  defp circuit_breaker_quoted(config, name, function) do
    exceptions = parse_rescue_from(config[:rescue_from])
    fuse_opts_quoted = {
      {:standard, config[:threshold], config[:threshold_interval]},
      {:reset, config[:reset_after]}
    }
    |> Macro.escape
    hooks_quoted = (config[:hooks] || []) |> Macro.escape

    quote do
      require Logger

      case :fuse.ask(unquote(name), :sync) do
        :ok -> unquote(try_execute(function, exceptions, hooks_quoted, name))
        :blown ->
          unquote(hooks_quoted) |> Enum.each(&(&1.on_open(unquote(name))))
          unquote(@on_open_unavailable_state)
        {:error, :not_found} ->
          :fuse.install(unquote(name), unquote(fuse_opts_quoted))
          unquote(try_execute(function, exceptions, hooks_quoted, name))
      end
    end
  end

  defp try_execute(function, %{exception_rescue: false, quoted: exceptions_quoted}, hooks_quoted, name) do
    quote do
      try do
        unquote(try_body(function))
      rescue unquote(rescue_clause(exceptions_quoted, var_name: :e)) ->
        unquote(on_error_body(name, hooks_quoted))
      end
    end
  end

  defp try_execute(function, %{exception_rescue: true, quoted: exceptions_quoted}, hooks_quoted, name) do
    quote do
      try do
        unquote(try_body(function))
      rescue
      unquote(rescue_clause(exceptions_quoted, var_name: :e)) ->
        reraise(unquote(Macro.var(:e, nil)), System.stacktrace())
      unquote(Macro.var(:e, nil)) ->
        unquote(on_error_body(name, hooks_quoted))
      end
    end
  end

  defp rescue_clause(exceptions_quoted, var_name: var_name) when is_atom(var_name) do
    var = Macro.var(var_name, nil)
    if exceptions_quoted do
      quote do
        unquote(var) in unquote(exceptions_quoted)
      end
    else
      var
    end
  end

  defp parse_rescue_from(%{except: exceptions}) do
    %{exception_rescue: true, quoted: exceptions |> Macro.escape}
  end

  defp parse_rescue_from(exceptions) when is_nil(exceptions) do
    %{exception_rescue: false, quoted: nil}
  end

  defp parse_rescue_from(exceptions) do
    %{exception_rescue: false, quoted: exceptions |> Macro.escape}
  end

  defp try_body(function) do
    quote do
      result = unquote(function)
      |> case do
        [do: func] -> func
        func -> func
      end
      result
    end
  end

  defp on_error_body(name, hooks_quoted) do
    quote do
      Logger.warn("[Edison] Circuit Breaker #{unquote(name)} has rescued from an error on #{__MODULE__} returned an error: #{inspect unquote(Macro.var(:e, nil))}. #{Exception.format_stacktrace(System.stacktrace())}")
      :fuse.melt(unquote(name))
      unquote(hooks_quoted) |> Enum.each(&(&1.on_error(unquote(name))))
      unquote(@on_error_unavailable_state)
    end
  end

end
