# --------------------------------------------------------------------------------------------------
# Migrations to 1.0.0
# Replacing `enabled` argument in secure-bucket module with `count` meta-argument
# --------------------------------------------------------------------------------------------------

moved {
  from = module.audit_log_bucket
  to   = module.audit_log_bucket[0]
}
