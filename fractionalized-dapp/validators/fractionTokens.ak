use aiken/bytearray
use aiken/dict
use aiken/hash.{Blake2b_224, Hash}
use aiken/list
use aiken/transaction.{
  InlineDatum, Mint, OutputReference, ScriptContext, Spend, Transaction,
} as tx
use aiken/transaction/credential.{VerificationKey}
use aiken/transaction/value

// reference Prefix
const refPrefix = #"000643b0"

// fraction Prefix
const fracPrefix = #"001bc280"

// PKH 
type VerificationKeyHash =
  Hash<Blake2b_224, VerificationKey>

type Action {
  Mint
  Burn
}

type TokenDatum {
  a: Int,
}

// When a user registers a project fundraise request
// An oracle is holding the datum with all the info fields
type OracleDatum {
  projectOwner: VerificationKeyHash,
  fundRequest: Int,
  maxPercentageShare: Int,
}

// divide the amount given by fundRequest, and the percentage
// should be the percent against the maxPercentageShare

// Helper Functions //
fn make_token_names(tn) -> List<value.AssetName> {
  let tokenName: value.AssetName = tn
  let refTn = tokenName
  let fracTn = tokenName
  [refTn, fracTn]
}

fn fraction_token_prefix(tn) {
  let token_names = make_token_names(tn)
  let token_name_prefix =
    [refPrefix, fracPrefix]
  list.map2(token_name_prefix, token_names, fn(a, b) { bytearray.concat(a, b) })
}

fn compare_token_names(an: value.AssetName, tn: Option<ByteArray>) -> Bool {
  expect Some(tn) = tn
  an == tn
}

fn tx_signed_by(tx: Transaction, pkh: VerificationKeyHash) {
  list.has(tx.extra_signatories, pkh)
}

// Minting policy validator

validator(
  nft_name: ByteArray,
  frac_name: ByteArray,
  utxo_ref: OutputReference,
  owner: VerificationKeyHash,
) {
  fn mint(
    datum dt: OracleDatum,
    redeemer rd: Action,
    ctx: ScriptContext,
  ) -> Bool {
    let ScriptContext { transaction, purpose } = ctx
    expect tx.Mint(policy_id) = purpose
    let Transaction { inputs, outputs, mint, reference_inputs } = transaction

    let oneInput = list.head(inputs)

    expect [(ref_asset_name, ref_amount), (frac_asset_name, frac_amount)] =
      mint
        |> value.from_minted_value
        |> value.tokens(policy_id)
        |> dict.to_list()

    expect tx_signed_by(transaction, owner)
    when rd is {
      Mint -> {
        expect
          list.any(inputs, fn(input) { input.output_reference == utxo_ref })
        amount == 1 && asset_name == token_name
      }
      Burn -> todo @"burn the asset"
    }
  }
}
