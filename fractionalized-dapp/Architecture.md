# Purpose

The purpose of this document is to explain the functionality of this application and what a user can do with it.

### Description

A user can register a project via this app in order to promoto a fundraising request. SHe does that by submitting a tx to the Cardano blockchain. A `datum` is stored in the newly created UTXO that holds information regarding that request. This newly created UTXO also holds an NFT as well. This will be our `Oracle`.

The datum of the Oracle, will hold information such as, project name, owner, the NFT id (maybe), the requested fundraising amount, and the equity rate (i.e how much ownership will the funding provided represent). Based on the information hold in the `Oracle`'s datum an equivalent amount to the equity of fractional tokens will be minted, along with an NFT reference. We will use the CIP 25/68 with the prefix of `100` for NFT token name, and `444` for the fractional tokens.


### UI Components

1. A UI form card for a user to register their fundraising request
    a. This action will mint a unique UTXO that will hold the Oracle datum and the NFT (policy hash is the validation king)
    b. THis form should have the following fields, Project Name, AMount of funds in ADA, Equity Rate, Submit Button

2. A. A UI Form card for user to provide funding to the registered project of her choice, and receive the equity fractions
    a. when this happens a reference NFT will be minted with prefix of 100
    b. The `Oracle's` datum will be checked to calculate the equity share for the equivalent fraction tokens to be minted (also calculate how much equity is available to mint (mint validator))

2. B. Same UI form but user has now the option to update the Oracle datum (think how the Oracle datum gets update for new equity share available to be acquired)
    a. Delete oracle option in this form.

### Validators involved (Smart Contracts to build with Aiken)

- `FractionTokensPolicy` - This is the minting policy that mints the NFT that will be hold by the oracle UTXO, to prove validity (state thread), and the fractional tokens that will represent 1% equity per token (1 fraction = 1% equity, if a project gives max 10%, then 10 fraction tokens will be minted)
- `OracleValidator` - This is the validator that has the UTXO holding the NFT minted by `FractionTokensPolicy` and the `Datum` with all the Oracle's information
- `FundraisingValidator` - This is where all the funds provided by users for the project are going to be locked.


### Transaction Flows (CRUCIAL)

For simplicity let's define:
Project= `ELABO`
ProjectOwner=`Bob`
FundsProvider=`Alice`

`Short description scenario`

To make it super simple for the purpose of this flow, lets assume that the project will request 1000ADA investment for a maximum giveaway equity share of 10%. Which means that if someone provides 1000ada has 10% equity to the company. THat mean
If ALice provides 1000 ADA she gets 10% equity therefore she can withdraw all 10 fractional tokens.
If ALice provides 500ADA she gets 5% equity therefore she can withdraw all 5 tokens that represent 1% of ownership each
etc. etc.

1. Bob registers his project by submitting a transaction to the blockchain. This tx does the following:
    a. Mints an NFT to to be used as the validation mechanism of the Oracles UTXO
    b. That NFT is then locked in the `OracleValidator` under a UTXO with a datum that holds all the information of the fundraising request from the project
2. Alice now wants to provide funds to the project and receive the Equity Tokens (fractional). She submits a tx to the blockchain which does the following:
    a. The oracle datum needs to be checked, to see how much equity is available to be given
    b. The amount of funds that ALice provides is checked against the projects requested amount
    c. Based on the above ratio the equivalent amount of fractional tokens is minted with the nft
    d. Alice receives the fractional tokens
