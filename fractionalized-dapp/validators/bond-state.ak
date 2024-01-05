use aiken/list
use aiken/transaction.{InlineDatum,
  Output, ScriptContext, Spend, Transaction} as tx
use aiken/transaction/credential.{Address}
use aiken/transaction/value.{AssetName, PolicyId}
use bond/types.{AssetClass, BondStateDatum, ProjectOracleDatum}

/// Bond state validator which checks if total bond sold is correct or not 
/// UTxO can be consumed if state token is burned
/// If we have continuous output to same script address total bond sold will be checked 
validator(bond_state_asset: AssetClass, bond_token_asset: AssetClass) {
  fn validate_bond_state(
    datum: BondStateDatum,
    redeemer: Void,
    ctx: ScriptContext,
  ) -> Bool {
    let (b_pid, b_asst_name) = bond_state_asset
    let (bond_token_pid, bond_asset_name) = bond_token_asset
    let Transaction { inputs, outputs, reference_inputs, mint, .. } =
      ctx.transaction
    expect Spend(utxo_ref) = ctx.purpose
    expect Some(own_input) = tx.find_input(inputs, utxo_ref)

    let own_output =
      list.find(outputs, fn(o) { own_input.output.address == o.address })

    when own_output is {
      Some(op) -> {
        expect minted_bond_token_qty =
          mint
            |> value.from_minted_value()
            |> value.quantity_of(bond_token_pid, bond_asset_name)

        expect InlineDatum(own_output_data) = op.datum
        expect own_op_bond_st_dtm: BondStateDatum = own_output_data

        let must_have_state_token_in_inputs =
          must_include_bond_token_with_qty(
            own_input.output,
            b_pid,
            b_asst_name,
            1,
          )
        let must_output_state_token =
          must_include_bond_token_with_qty(op, b_pid, b_asst_name, 1)
        let must_have_valid_sate_datum =
          own_op_bond_st_dtm.total_bond_sold == datum.total_bond_sold + minted_bond_token_qty

        must_have_state_token_in_inputs && must_output_state_token && must_have_valid_sate_datum
      }

      None ->
        // Token must be burned
        must_include_bond_token_with_qty(
          own_input.output,
          b_pid,
          b_asst_name,
          -1,
        )
    }
  }
}

fn must_include_bond_token_with_qty(
  output: Output,
  policy_id: PolicyId,
  asset_name: AssetName,
  qty: Int,
) -> Bool {
  value.quantity_of(output.value, policy_id, asset_name) == qty
}
