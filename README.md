# AirdropVault-X 🎁

AirdropVault-X is a Clarity smart contract for trustless, decentralized token airdrops on the Stacks blockchain. It allows project owners to distribute SIP-010 tokens to eligible users, with strict eligibility rules and a simple claiming process.

## 🌐 Overview

This contract is designed to support marketing campaigns, community rewards, or user incentivization programs by distributing tokens without requiring centralized intervention.

## ✨ Features

- ✅ **Vault Initialization**: Admins create airdrop vaults for a specific SIP-010 token and total distribution amount.
- 🧾 **One-time Claim Enforcement**: Ensures each user can claim from a vault only once.
- 📤 **Token Claiming**: Users can claim their portion of tokens via a public function.
- 🔐 **Admin Controls**: Admins can end vaults, withdraw unclaimed tokens, and manage access.
- 📊 **Eligibility Checks**: Prevents multiple claims and allows for future whitelist/Merkle-based upgrades.

## 🧱 Contract Details

- **Contract Language**: Clarity
- **Token Standard**: SIP-010
- **File**: `airdrop-vault-x.clar`

## 🛠 Usage

### 1. Vault Creation (Admin Only)
```clarity
(create-vault token-contract token-id total-tokens-per-user)
