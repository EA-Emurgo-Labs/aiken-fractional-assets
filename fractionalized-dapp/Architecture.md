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

- `FractionTokensPolicy` - This is the minting policy that mints the NFT that will be hold by the oracle UTXO, to prove validity (state thread), the reference NFT, and the fractional tokens that will represent 1% equity per token (1 fraction = 1% equity, if a project gives max 10%, then 10 fraction tokens will be minted)
- `OracleValidator` - This is the validator that has the UTXO holding the NFT minted by `FractionTokensPolicy` and the `Datum` with all the Oracle's information
- `FundraisingValidator` - This is where all the funds provided by users for the project are going to be locked.


### Transaction Flows (CRUCIAL)

For simplicity let's define:
Project= `ELABO`
ProjectOwner=`Bob`
FundsProvider=`Alice`

`Short description scenario`

To make it super simple for the purpose of this flow, lets assume that the project will request 1000ADA investment for a maximum giveaway equity share of 10%. Which means that if someone provides 1000ada has 10% equity to the company. That means

\\ Equity Shares
If ALice provides 1000 ADA she gets 10% equity therefore she can withdraw all 10 fractional tokens.
If ALice provides 500ADA she gets 5% equity therefore she can withdraw all 5 tokens that represent 1% of ownership each
etc. etc.

1. Bob registers his project by submitting a transaction to the blockchain. This tx does the following:
    a. Mints an NFT to to be used as the validation mechanism of the Oracles UTXO
    b. That NFT is then locked in the `OracleValidator` under a UTXO with a datum that holds all the information of the fundraising request from the project
    c. Based on the fundraising request a reference NFT and the fractionalized tokens will be minted from th same minting policy of the oracle nft and they will be locked in the `FundraisingValidator`
2. Alice now wants to provide funds to the project and receive the Equity Tokens (fractional). She submits a tx to the blockchain which does the following:
    a. The oracle datum needs to be checked, to see how much equity is available to be given
    b. The amount of funds that ALice provides is checked against the projects requested amount
    c. This tx is basically a spending/consuming transaction. It consumes the UTXO that holds the reference NFT and the fractional tokens, and Alice will get back the analogous amount of fractional tokens based on the funding she provided.
    d. The Oracle's datum should also be updated here with an updated field showing how much equity has been given/or is available for others to provide funds (any ideas for this welcome)

3. Everyone (in our case alice) can update the Oracle's datum field that shows the equity given/remained available by submitting a TX that gives funds to a project. But only the owner/creator of the Oracle can delete the oracle, or update the rest of the data fields.

4. Only the owner of the project (Bob) who created the oracle when registered the project in the first place, can consume and withdraw the funds from the UTXO under the FundraisingValidator. The logic for this will be more detailed in the Aiken contract.

5. The owner of the project can submit a transaction to delete the Oracle, which will burn all the token (more to think about this, as we need to do something to the funds that have already been provided.)


### Development Plan

1. Wallet integration - Start with Nami
2. ContextAPI to pass wallet data around the dapp
3. Start developing the minting policy with Aiken
4. Start developing the validator of the oracle with Aiken
5. Start developing the fundraising validator with Aiken
6. Start developing the offchain code with lucid

1-3 -> Complete in December
4-6 -> Complete by 15th of January


### Oracle Related Flow

1. User submits a tx to register a project
2. An NFT and the fraction tokens are minted in this transaction and the Oracle datum gets created and stored in a utxo
3. THe fraction tokens are sent and locked under the LockValidator
4. The NFT and the datum are at a utxo under the Oracle Validator which is responsible for creation, update and deletion of the Oracle
5. A user provides funding to a project in exchange for the fraction tokens. The user receives the equivalent amount. Those tokens cannot be faked by others, they are minted using same UTXO reference as the original NFT.
6. A project owner withdraws funds from a project. He should be the creator of the original NFT related to the project to make that happen.
