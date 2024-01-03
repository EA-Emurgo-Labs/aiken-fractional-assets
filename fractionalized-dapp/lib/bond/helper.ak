use aiken/interval.{Finite}
use aiken/list
use aiken/option
use aiken/transaction.{Output,
  OutputReference, Transaction, ValidityRange} as tx
use bond/types.{POSIXTime}

pub fn is_tx_before(range: ValidityRange, time: POSIXTime) -> Bool {
  when range.upper_bound.bound_type is {
    Finite(tx_final_time) -> tx_final_time <= time
    _ -> False
  }
}

pub fn is_tx_after(range: ValidityRange, time: POSIXTime) -> Bool {
  when range.lower_bound.bound_type is {
    Finite(tx_earliest_time) -> time <= tx_earliest_time
    _ -> False
  }
}
