use aiken/dict
use aiken/list
use aiken/option
use aiken/transaction.{InlineDatum, Output, ScriptContext, Transaction} as tx
use aiken/transaction/credential.{Address}
use aiken/transaction/value
use bond/helper
use bond/types.{AssetClass, BondSaleDatum, ProjectOracleDatum}

// Used to validate if requested amount is correct and transaction is made between Sale start and end date
// also price and requested amount is checked

validator(
  token_name: ByteArray,
  oracle_address: Address,
  bond_sale_addr: Address,
) {
  fn bond_sale_phase_token(redeemer: Void, ctx: ScriptContext) -> Bool {
    let Transaction {
      reference_inputs,
      extra_signatories,
      validity_range,
      outputs,
      mint,
      ..
    } = ctx.transaction
    expect tx.Mint(policy_id) = ctx.purpose
    expect Some(project_oracle_utxo) =
      list.find(reference_inputs, fn(i) { i.output.address == oracle_address })
    expect InlineDatum(oracle_data) = project_oracle_utxo.output.datum
    expect project_oracle_datum: ProjectOracleDatum = oracle_data

    expect Some(bond_sale_op_utxo) =
      list.find(outputs, fn(o) { o.address == bond_sale_addr })

    expect InlineDatum(bond_sale_data) = bond_sale_op_utxo.datum
    expect bond_sale_datum: BondSaleDatum = bond_sale_data

    let must_mint_between_sale_phase =
      helper.is_tx_after(validity_range, project_oracle_datum.sale_start_date) && helper.is_tx_before(
        validity_range,
        project_oracle_datum.sale_end_date,
      )

    expect [(asset_name, amount)] =
      mint
        |> value.from_minted_value()
        |> value.tokens(policy_id)
        |> dict.to_list()

    let must_sign_by_buyer =
      list.has(extra_signatories, bond_sale_datum.buyer_pubkey)

    let is_burn = amount < 0

    is_burn || and {
      (asset_name == token_name)?,
      (amount == 1)?,
      must_sign_by_buyer?,
      must_output_correct_value(
        bond_sale_op_utxo,
        project_oracle_datum,
        bond_sale_datum,
      )?,
    }
  }
}

// Checks if requested amount is valid based on asset provided
// Checks if correct amount is allocated for Batcher
// Checks if valid fee is sent to management
fn must_output_correct_value(
  output: Output,
  project_oracle: ProjectOracleDatum,
  bond_sale_datum: BondSaleDatum,
) -> Bool {
  let (in_token_pid, in_token_asset) = project_oracle.in_token_asset
  let (price_n, price_d) = project_oracle.price
  let in_token_qty =
    value.quantity_of(output.value, in_token_pid, in_token_asset)

  let total_lovelace_paid =
    output.value
      |> value.add(in_token_pid, in_token_asset, -in_token_qty)
      |> value.lovelace_of()

  let fees_required =
    bond_sale_datum.batcher_fee + option.or_else(
      bond_sale_datum.management_fee,
      0,
    )

  let must_have_enough_token =
    price_n / price_d * in_token_qty == bond_sale_datum.requested_amount

  let must_pay_fee = total_lovelace_paid >= fees_required

  must_have_enough_token? && must_pay_fee?
}
