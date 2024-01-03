use aiken/hash.{Blake2b_224, Hash}
use aiken/transaction/credential.{VerificationKey}
use aiken/transaction/value.{AssetName, PolicyId}

pub type AssetClass =
  (PolicyId, AssetName)

pub type Fractional =
  (Int, Int)

pub type PubKeyHash =
  Hash<Blake2b_224, VerificationKey>

pub type POSIXTime =
  Int

pub type ProjectOracleDatum {
  owner: PubKeyHash,
  tot_bond_sale: Int,
  price: Fractional,
  in_token_asset: AssetClass,
  interest_rate: Fractional,
  sale_start_date: POSIXTime,
  sale_end_date: POSIXTime,
}

pub type BondStateDatum {
  // Total bond sold
  total_bond_sold: Int,
}
