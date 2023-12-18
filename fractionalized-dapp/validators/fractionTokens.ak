//////////////////////////// HELPER ///////
///////////////////////////////////////////////////

use aiken/bytearray
use aiken/dict
use aiken/hash.{Blake2b_224, Hash}
use aiken/list
use aiken/transaction.{
  InlineDatum, Mint, OutputReference, ScriptContext, Spend, Transaction,
}
use aiken/transaction/credential.{VerificationKey}
use aiken/transaction/value

// reference Prefix
const refPrefix = #"000643b0"

// fraction Prefix
const fracPrefix = #"001bc280"

// PKH 
type VerificationKeyHash =
  Hash<Blake2b_224, VerificationKey>

type MintAction {
  a: Int,
  b: Int,
  tn: ByteArray,
}

type TokenDatum {
  a: Int,
}

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
) {
  fn mint(redeemer: MintAction, ctx: ScriptContext) -> Bool {
    todo @"mintnft"
  }
}
