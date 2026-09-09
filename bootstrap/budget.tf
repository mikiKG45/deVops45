# --- Cost guardrail: $10 monthly budget ---
# Gabe's requirement: know when you're burning the free credit. We track GROSS
# usage (include_credit = false) so alerts fire based on real resource consumption,
# not on the credit-adjusted net (which would read ~$0 until the credit runs out).

resource "aws_budgets_budget" "monthly" {
  name         = "devops45-monthly-10usd"
  budget_type  = "COST"
  limit_amount = "10"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_types {
    include_credit = false # count usage BEFORE free credits are applied -> early warning
    include_refund = false
    include_tax    = true
  }

  # Warn at 80% of the $10 (i.e. $8) of ACTUAL spend.
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  # Warn at 100% ($10) of ACTUAL spend.
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  # Warn when AWS FORECASTS you'll cross $10 by month end — catches a runaway
  # cluster you forgot to destroy, before it actually hits the limit.
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}
