use aiken/bytearray
use aiken/dict
use aiken/hash.{Blake2b_224, Hash}
use aiken/list
use aiken/string
use aiken/transaction.{
  InlineDatum, Mint, OutputReference, ScriptContext, Spend, Transaction,
} as tx
use aiken/transaction/credential.{Script, VerificationKey}
use aiken/transaction/value

type VerificationKeyHash =
  Hash<Blake2b_224, VerificationKey>

type NFTHash =
  Hash<Blake2b_224, Script>

type TokenAction {
  Mint
  Burn
}

type LockAction {
  ProvideFunding
  WithdrawFund
}

//for investor to unlock fractional tokens
// 0 is fund it
// 1 is withdraw

// for project owner to withdraw investment funds

type LockDatum {
  projectOwner: VerificationKeyHash,
  nftLink: NFTHash,
}

type Action {
  a: Int,
  //nft
  b: Int,
}

// fracts

// When a user registers a project fundraise request
// An oracle is holding the datum with all the info fields
type OracleDatum {
  projectOwner: VerificationKeyHash,
  projectName: ByteArray,
  fundRequested: Int,
  maxPercentageShare: Int,
  nftLink: NFTHash,
}

type OracleAction {
  Delete
  Update
  Create
}

// divide the amount given by fundRequest, and the percentage
// should be the percent against the maxPercentageShar

// Helper function for signature check

fn tx_signed_by(tx: Transaction, pkh: VerificationKeyHash) {
  list.has(tx.extra_signatories, pkh)
}

fn calculate_ratio(
  token_frac tf: Int,
  fund_requested fr: Int,
  fund_provided fp: Int,
) -> Bool {
  fp / fr == tf / 100
}

// Minting policy validator

validator(
  nft_name: ByteArray,
  frac_name: ByteArray,
  utxo_ref: OutputReference,
  owner: VerificationKeyHash,
) {
  fn mint(rdmr: TokenAction, ctx: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = ctx
    expect tx.Mint(policy_id) = purpose
    let Transaction { inputs, outputs, mint, reference_inputs, .. } =
      transaction

    expect [(ref_asset_name, ref_amount), (frac_asset_name, frac_amount)] =
      mint
        |> value.from_minted_value
        |> value.tokens(policy_id)
        |> dict.to_list()
    when rdmr is {
      Mint -> {
        trace @"minting"
        expect
          list.any(inputs, fn(input) { input.output_reference == utxo_ref })
        expect tx_signed_by(transaction, owner)
        ref_amount == 1
      }

      // ref_amount == 1
      Burn -> {
        expect tx_signed_by(transaction, owner)
        ref_amount == -1
      }
    }
    // ref_amount == -1
  }
}

// Fake mint

validator {
  fn fakemint(redeemer: TokenAction, ctx: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = ctx
    expect tx.Mint(policy_id) = purpose
    let Transaction { inputs, outputs, mint, reference_inputs, .. } =
      transaction

    when redeemer is {
      Mint -> 1 == 1
      Burn -> 1 == 1
    }
  }
}

// Validator for locking the newly minted tokens so other activities can occur
// 1. Project owner when minting the tokens mentioned above, receives the NFT to her wallet
// But send the fractional tokens to the locked validator
// 2. The investor sends ADA to the lock validator, and gets back the correct portion of fraction 
// tokens.

// Recommended from TXPIPE

// validator {
//   fn lockValid(
//     datum: Data,
//     rdmr: Data,
//     ctx: ScriptContext,
//   ) -> Bool {
//   expect datum: LockDatum = datum
//   expect rdmr: LockAction = rdmr

type TDatum {
  a: Int,
}

type TAction {
  One
}

type RedeemerAction {
  msg: ByteArray,
}

validator {
  fn lockTest(dt: TDatum, rd: TAction, ctx: ScriptContext) -> Bool {
    when rd is {
      One -> True
    }
  }
}

validator {
  fn lockValid(datum: LockDatum, rdmr: LockAction, ctx: ScriptContext) -> Bool {
    // expect ScriptContext { transaction, purpose } = ctx

    // // For provide funding, check signature and ratio between ada and fraction shares
    // // We need access to inputs and outputs
    // expect Transaction {
    //   inputs,
    //   outputs,
    //   reference_inputs,
    //   extra_signatories,
    //   ..
    // } = transaction

    // expect Some(refInput) = list.head(reference_inputs)
    // expect InlineDatum(therefOne) = refInput.output.datum
    // expect orclDtm: OracleDatum = therefOne
    // let OracleDatum {
    //   projectOwner,
    //   projectName,
    //   maxPercentageShare,
    //   nftLink,
    //   fundRequested,
    // } = orclDtm

    // // Here we are looking for the VALUE of ADA asset to retrieve the amount the user invests in project
    // expect Some(oneOutput) =
    //   list.find(
    //     outputs,
    //     fn(output) { list.has(value.policies(output.value), #"") },
    //   )
    // expect providedAmount = value.lovelace_of(oneOutput.value)
    // expect Some(ownersHash) = list.head(extra_signatories)

    // // Get the assets from the output of the transaction
    // expect Some(txOut) = list.head(outputs)
    // expect Some(txInput) = list.head(inputs)

    // expect [
    //   (ada_policyid, ada_name, ada_amount),
    //   (fract_policyid, fract_name, fract_amount),
    // ] =
    //   txOut.value
    //     |> value.flatten

    when rdmr is {
      ProvideFunding -> True
      WithdrawFund -> True
    }
    // when rd is {
    //   ProvideFunding ->
    //     tx_signed_by(transaction, ownersHash)? && calculate_ratio(
    //       fract_amount,
    //       fundRequested,
    //       providedAmount,
    //     )?
    //   // Project owner should be able to withdraw 10% of the funds in one transaction, not all.
    //   WithdrawFund -> {
    //     let ownerCheck = projectOwner == ownersHash
    //     let computationCheck =
    //       value.lovelace_of(txOut.value) * 10 <= value.lovelace_of(
    //         txInput.output.value,
    //       )

    //     ownerCheck? && computationCheck?
    //   }
    // }
  }
}

// Oracle validator, checks the NFT token ownership

validator {
  fn oraclev(
    datum dt: OracleDatum,
    redeemer rd: OracleAction,
    ctx: ScriptContext,
  ) -> Bool {
    expect tx.ScriptContext { transaction, purpose } = ctx
    expect tx.Transaction { mint, inputs, outputs, reference_inputs, .. } =
      transaction
    let OracleDatum {
      projectOwner,
      projectName,
      maxPercentageShare,
      nftLink,
      fundRequested,
    } = dt

    // list.find() returns Option<a>
    // Here we are looking for the output that has the NFT == 1
    expect Some(nftOutput) =
      list.find(
        outputs,
        fn(output) {
          expect Some(assets) =
            list.head(value.flatten(value.without_lovelace(output.value)))

          expect (pid, asset_name, amount) = assets

          amount == 1
        },
      )

    // Get the NNFT policy from the VALUE
    expect Some(nftPolicy) = list.head(value.policies(nftOutput.value))

    // Get datum of the input, only one in UPDATE action
    expect Some(theTxInput) = list.head(inputs)
    expect InlineDatum(theDatum) = theTxInput.output.datum
    expect theInputOracleDatum: OracleDatum = theDatum

    // Get datum of the output, only one output in UPDATE action with new datum
    expect Some(theTxOutput) = list.head(outputs)
    expect InlineDatum(theOutDatum) = theTxOutput.datum
    expect theOracleOutputDatum: OracleDatum = theOutDatum

    // When Deleting Oracle, we basically burn the NFT and remove datum
    expect [(asset_name, amount)] =
      mint
        |> value.from_minted_value
        |> value.tokens(nftLink)
        |> dict.to_list()

    when rd is {
      Create -> nftPolicy == nftLink
      Update ->
        tx_signed_by(transaction, theInputOracleDatum.projectOwner) && theInputOracleDatum != theOracleOutputDatum
      Delete ->
        tx_signed_by(transaction, theInputOracleDatum.projectOwner) && amount == -1
    }
  }
}
