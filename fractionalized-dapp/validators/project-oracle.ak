use aiken/list
use aiken/transaction.{ScriptContext, Transaction} as tx
use bond/helper
use bond/types.{ProjectOracleDatum}

validator {
  fn project_oracle(
    datum: ProjectOracleDatum,
    _red: Void,
    ctx: ScriptContext,
  ) -> Bool {
    validate_project_oracle(datum, ctx)
  }
}

// Right now allowing project owner to do anything with script
// before bond sale starts
// TODO: [Piyush] Maybe add multiple action that could be done for script
fn validate_project_oracle(
  datum: ProjectOracleDatum,
  ctx: ScriptContext,
) -> Bool {
  let Transaction { extra_signatories, validity_range, .. } = ctx.transaction
  let is_signed_by_owner = list.has(extra_signatories, datum.owner)
  is_signed_by_owner && helper.is_tx_before(
    validity_range,
    datum.sale_start_date,
  )
}
