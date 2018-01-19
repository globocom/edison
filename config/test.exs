use Mix.Config

config :edison, :circuit_breaker,
  circuit_that_rescue_from_any_error: [
    threshold: 1,
    threshold_interval: 10000,
    reset_after: 1000
  ],
  circuit_that_rescue_from_error1: [
    threshold: 1,
    threshold_interval: 10000,
    reset_after: 1000,
    rescue_from: Support.Error1
  ],
  circuit_that_rescue_from_error1_and_error2: [
    threshold: 1,
    threshold_interval: 10000,
    reset_after: 1000,
    rescue_from: [Support.Error1, Support.Error2]
  ],
  circuit_that_rescue_everything_except_error1: [
    threshold: 1,
    threshold_interval: 10000,
    reset_after: 1000,
    rescue_from: %{except: [Support.Error1]}
  ]
