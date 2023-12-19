use aiken/bytearray
use aiken/dict
use aiken/hash.{Blake2b_224, Hash}
use aiken/list
use aiken/transaction.{
  InlineDatum, Mint, OutputReference, ScriptContext, Spend, Transaction,
} as tx
use aiken/transaction/credential.{Script, VerificationKey}
use aiken/transaction/value

// PKH 
type VerificationKeyHash =
  Hash<Blake2b_224, VerificationKey>

type NFTHash =
  Hash<Blake2b_224, Script>

type TokenAction {
  Mint
  Burn
}

// When a user registers a project fundraise request
// An oracle is holding the datum with all the info fields
type OracleDatum {
  projectOwner: VerificationKeyHash,
  fundRequested: Int,
  maxPercentageShare: Int,
  nftLink: NFTHash,
}

// divide the amount given by fundRequest, and the percentage
// should be the percent against the maxPercentageShar

// Helper function for signature check

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
    redeemer rd: TokenAction,
    ctx: ScriptContext,
  ) -> Bool {
    let ScriptContext { transaction, purpose } = ctx
    expect tx.Mint(policy_id) = purpose
    let Transaction { inputs, outputs, mint, reference_inputs, .. } =
      transaction

    // Extract datum from Input
    expect Some(oneInput) = list.head(inputs)
    expect InlineDatum(theOracleOne) = oneInput.output.datum
    expect orclDtm: OracleDatum = theOracleOne
    let OracleDatum { projectOwner, maxPercentageShare, nftLink, fundRequested } =
      orclDtm

    expect [(ref_asset_name, ref_amount), (frac_asset_name, frac_amount)] =
      mint
        |> value.from_minted_value
        |> value.tokens(policy_id)
        |> dict.to_list()

    when rd is {
      Mint -> {
        expect
          list.any(inputs, fn(input) { input.output_reference == utxo_ref })
        expect tx_signed_by(transaction, owner)
        ref_amount == 1 && frac_amount == maxPercentageShare
      }
      Burn -> {
        expect tx_signed_by(transaction, projectOwner)
        ref_amount == -1 && frac_amount == -maxPercentageShare
      }
    }
  }
}
// Validator for locking the newly minted tokens so other activities can occur
