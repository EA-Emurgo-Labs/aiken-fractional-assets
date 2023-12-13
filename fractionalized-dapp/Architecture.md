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


### Transaction Flows (CRUCIAL)