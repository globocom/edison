defmodule EdisonTest do
  use ExUnit.Case
  import Edison
  doctest Edison

  alias Support.Error1
  alias Support.Error2
  alias Support.Error3

  setup do
    on_exit(fn ->
      :fuse.remove(:circuit_that_rescue_from_any_error)
      :fuse.remove(:circuit_that_rescue_from_error1)
      :fuse.remove(:circuit_that_rescue_from_error1_and_error2)
      :fuse.remove(:circuit_that_rescue_everything_except_error1)
      :ok
    end)
  end

  describe "error rescuing" do
    test "rescue from any error" do
      circuit_breaker :circuit_that_rescue_from_any_error do
        raise Error1
      end
      circuit_breaker :circuit_that_rescue_from_any_error do
        raise Error2
      end
      circuit_breaker :circuit_that_rescue_from_any_error do
        raise Error3
      end
      assert true # Nothing failed if arrived here
    end

    test "rescue from a specific error" do
      circuit_breaker :circuit_that_rescue_from_error1 do
        raise Error1
      end
      assert true # Nothing failed if arrived here
    end

    test "rescue from some specific errors and open the circuit" do
      circuit_breaker :circuit_that_rescue_from_error1_and_error2 do
        raise Error1
      end
      circuit_breaker :circuit_that_rescue_from_error1_and_error2 do
        raise Error2
      end
    end

    test "does not rescue from errors different from the specifie one" do
      assert_raise(Error2, fn ->
        circuit_breaker :circuit_that_rescue_from_error1 do
          raise Error2
        end
      end)
    end

    test "does not rescue from errors different from the specified ones" do
      assert_raise(Error3, fn ->
        circuit_breaker :circuit_that_rescue_from_error1_and_error2 do
          raise Error3
        end
      end)
    end

    test "does not rescue from errors on exception cases" do
      assert_raise(Error1, fn ->
        circuit_breaker :circuit_that_rescue_everything_except_error1 do
          raise Error1
        end
      end)
    end

    test "rescue from any other erro than the exception cases" do
      circuit_breaker :circuit_that_rescue_everything_except_error1 do
        raise Error2
      end
      circuit_breaker :circuit_that_rescue_everything_except_error1 do
        raise Error3
      end
      assert true # Nothing failed if arrived here
    end
  end

  test "open the circuit after rescuing many times in the threshold interval" do
    result = circuit_breaker :circuit_that_rescue_from_any_error do
      raise Error1
    end
    assert result == {:unavailable, :circuit_closed}

    result = circuit_breaker :circuit_that_rescue_from_any_error do
      raise Error2
    end
    assert result == {:unavailable, :circuit_closed}

    result = circuit_breaker :circuit_that_rescue_from_any_error do
      raise Error3
    end
    assert result == {:unavailable, :circuit_open}
  end

  test "repass the expression return if nothing goes wrong" do
    result = circuit_breaker :circuit_that_rescue_from_any_error do
      "return"
    end

    assert result == "return"
  end

  test "is available if the circuit was not created at" do
    assert Edison.state_of(:circuit_that_rescue_from_any_error) == {:available, :circuit_closed}
  end

  test "is available if the circuit does not failed less than the threashold" do
    circuit_breaker :circuit_that_rescue_from_any_error do
      raise Error1
    end
    assert Edison.state_of(:circuit_that_rescue_from_any_error) == {:available, :circuit_closed}
  end

  test "is unavailable if the circuit failed more than the threshold" do
    circuit_breaker :circuit_that_rescue_from_any_error do
      raise Error1
    end
    circuit_breaker :circuit_that_rescue_from_any_error do
      raise Error1
    end
    assert Edison.state_of(:circuit_that_rescue_from_any_error) == {:unavailable, :circuit_open}
  end
end
