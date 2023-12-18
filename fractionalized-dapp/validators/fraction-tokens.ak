use aiken/bytearray
use aiken/dict
use aiken/hash.{Blake2b_224, Hash}
use aiken/list
use aiken/transaction.{
  InlineDatum, Mint, OutputReference, ScriptContext, Spend, Transaction,
} as tx
use aiken/transaction/credential.{VerificationKey}
use aiken/transaction/value

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
// should be the percent against the maxPercentageShar

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
    let Transaction { inputs, outputs, mint, reference_inputs, .. } = transaction

    let oneInput = list.head(inputs)

    // expect { output } = oneInput
    // expect theOracleOne: OracleDatum = output.datum
    expect [(ref_asset_name, ref_amount), (frac_asset_name, frac_amount)] =
      mint
        |> value.from_minted_value
        |> value.tokens(policy_id)
        |> dict.to_list()

    // expect tx_signed_by(transaction, owner)
    when rd is {
      Mint -> {
        expect
          list.any(inputs, fn(input) { input.output_reference == utxo_ref })
        ref_amount == 1 
      }
      Burn -> todo @"burn the asset"
    }
  }
}

