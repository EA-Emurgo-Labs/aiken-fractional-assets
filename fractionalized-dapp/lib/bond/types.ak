use aiken/hash.{Blake2b_224, Hash}
use aiken/transaction/credential.{Address, VerificationKey}
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
  out_token_asset: AssetClass,
  interest_rate: Fractional,
  sale_start_date: POSIXTime,
  sale_end_date: POSIXTime,
}

pub type BondStateDatum {
  // Total bond sold
  total_bond_sold: Int,
}

pub type BondSaleDatum {
  // Bond Sale Token buyer address
  buyer_address: Address,
  // Requested Bond Token
  requested_amount: Int,
  // Optional Management fee
  management_fee: Option<Int>,
  // Pubkey hash of buyer 
  buyer_pubkey: PubKeyHash,
  // Batcher fee in lovelace
  batcher_fee: Int,
}
