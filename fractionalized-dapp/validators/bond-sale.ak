use aiken/list
use aiken/option
use aiken/transaction.{ScriptContext, Spend, Transaction} as tx
use aiken/transaction/value
use bond/types.{AssetClass, BondSaleDatum}

type BondSaleActions {
  // Fill bondsale token by batcher
  Fill
  // Cancel Buy by Buyer
  Cancel
}

validator(bond_sale_phase_token: AssetClass, bond_token: AssetClass) {
  fn bond_sale(
    datum: BondSaleDatum,
    redeemer: BondSaleActions,
    ctx: ScriptContext,
  ) {
    let Transaction { inputs, outputs, extra_signatories, .. } = ctx.transaction
    let (sp_policy_id, sp_token_name) = bond_sale_phase_token
    let (bt_policy_id, bt_token_name) = bond_token

    expect Spend(own_utxo_ref) = ctx.purpose
    expect Some(own_input) = tx.find_input(inputs, own_utxo_ref)

    // must burn sale phase token
    expect
      value.quantity_of(own_input.output.value, sp_policy_id, sp_token_name) == -1

    when redeemer is {
      Cancel -> list.has(extra_signatories, datum.buyer_pubkey)
      Fill -> {
        let tot_bond_token_sent =
          outputs
            |> list.find(fn(o) { o.address == datum.buyer_address })
            |> option.and_then(
                 fn(o) {
                   Some(value.quantity_of(o.value, bt_policy_id, bt_token_name))
                 },
               )
            |> option.or_else(0)

        tot_bond_token_sent == datum.requested_amount
      }
    }
  }
}
