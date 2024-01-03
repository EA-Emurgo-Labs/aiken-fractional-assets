use aiken/dict
use aiken/list
use aiken/option
use aiken/transaction.{Output, ScriptContext, Transaction} as tx
use aiken/transaction/credential.{Address}
use aiken/transaction/value.{AssetName, PolicyId}
use bond/types.{AssetClass, BondStateDatum, ProjectOracleDatum}

type BondStateAction {
  Mint
  Burn
}

validator(
  // Name of asset should be same as project name
  asset_name: AssetName,
  // Address which has information about Project
  oracle_address: Address,
  // Address where minted Bond State token will go
  bond_sale_address: Address,
) {
  fn bond_state_policy(redeemer: BondStateAction, ctx: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = ctx
    let Transaction { outputs, reference_inputs, extra_signatories, .. } =
      transaction

    expect tx.Mint(policy_id) = purpose
    expect [(asset, amount)] =
      transaction.mint
        |> value.from_minted_value()
        |> value.tokens(policy_id)
        |> dict.to_list()

    when redeemer is {
      Mint ->
        handle_bond_state_mint(
          policy_id,
          asset,
          amount,
          asset_name,
          oracle_address,
          bond_sale_address,
          transaction,
        )
      Burn ->
        // TODO: [Piyush] Need to check for burn
        False
    }
  }
}

fn handle_bond_state_mint(
  policy_id: PolicyId,
  minted_asset_name: AssetName,
  minted_amount: Int,
  nft_asset_name: AssetName,
  oracle_address: Address,
  bond_sale_address: Address,
  transaction: Transaction,
) -> Bool {
  let Transaction { outputs, extra_signatories, .. } = transaction

  expect Some(project_oracle_data) =
    outputs
      |> list.find(fn(o) { o.address == oracle_address })
      |> option.and_then(fn(o) { fetch_inline_data(o) })

  expect project_oracle_dtm: ProjectOracleDatum = project_oracle_data

  expect Some(bond_op) =
    list.find(outputs, fn(o) { o.address == bond_sale_address })
  expect Some(bond_data) = fetch_inline_data(bond_op)
  expect bond_datum: BondStateDatum = bond_data

  let token_must_sent_to_bond =
    value.quantity_of(bond_op.value, policy_id, minted_asset_name) == 1

  let is_signed_by_owner = list.has(extra_signatories, project_oracle_dtm.owner)

  token_must_sent_to_bond && is_signed_by_owner && minted_amount == 1 && minted_asset_name == nft_asset_name && bond_datum.total_bond_sold == 0
}

fn fetch_inline_data(output: Output) -> Option<Data> {
  when output.datum is {
    InlineDatum(data) -> Some(data)
    _ -> None
  }
}
