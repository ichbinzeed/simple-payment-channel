# ⚡ SimplePaymentChannel — Streaming Payments in Solidity

> Part of my Solidity learning journey — implementing unidirectional payment channels with off-chain signatures.

[![Solidity](https://img.shields.io/badge/Solidity-0.8.x-363636?logo=solidity)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Tested_with-Foundry-red)](https://book.getfoundry.sh/)
[![Tests](https://img.shields.io/badge/Tests-5%20passing-brightgreen)]()

---

## What this is

A smart contract that allows Alice to stream payments to Bob using **off-chain signed messages** — with only 2 on-chain transactions regardless of how many payments happen in between.

This is the foundation of **unidirectional payment channels**: think paying per minute of service, per API call, or per unit of work — without paying gas every time.

---

## How it works

```
Alice deploys contract + deposits ETH  →  channel is open

Alice signs "Bob = 1 ETH"   (off-chain, free)
Alice signs "Bob = 4 ETH"   (off-chain, free)
Alice signs "Bob = 9 ETH"   (off-chain, free)
         │
         │  Bob keeps only the last one
         ▼
Bob calls close(9 ETH, signature)
  └── contract verifies signature came from Alice
  └── Bob receives 9 ETH
  └── Alice recovers 1 ETH
  └── contract self-destructs
```

Each message is **cumulative** — not "pay me 2 more ETH" but "total owed so far is X ETH". Bob always keeps the latest, highest one.

---

## Key concepts implemented

| Concept                                    | Where                |
| ------------------------------------------ | -------------------- |
| Off-chain signature verification           | `isValidSignature()` |
| Cumulative payment messages                | `close()`            |
| Channel expiration + timeout recovery      | `claimTimeout()`     |
| Extending the channel lifetime             | `extend()`           |
| Ethereum prefix hash (`eth_sign` standard) | `prefixed()`         |
| `ecrecover` to authenticate the sender     | `recoverSigner()`    |

---

## Why only 2 on-chain transactions?

The signed messages never touch the blockchain — Alice sends them directly to Bob (email, API, anything). The contract only gets involved twice:

| Step                        | On-chain? | Gas cost  |
| --------------------------- | --------- | --------- |
| Alice deploys + deposits    | Yes       | Paid once |
| Alice sends signed message  | No        | Free      |
| Alice sends signed message  | No        | Free      |
| ... repeat 10,000 times ... | No        | Free      |
| Bob closes the channel      | Yes       | Paid once |

---

## Replay attack prevention

The signed message includes the **contract address** — so a valid signature on this channel cannot be reused on a different one.

```solidity
bytes32 messageHash = keccak256(abi.encodePacked(address(this), amount));
```

---

## Tests (Foundry)

Actors: Alice (owner + signer), Bob (recipient), Carol (adversary).

| Test                       | What it checks                                                                  |
| -------------------------- | ------------------------------------------------------------------------------- |
| `testSetUp`                | Sender is Alice, recipient is Bob, balance is 10 ETH                            |
| `testClose`                | Bob closes with a valid signature, receives the correct amount                  |
| `testInvalidClose`         | Carol can't use Alice's signature / wrong amount reverts / wrong signer reverts |
| `testExtend`               | Alice can push the expiration date forward                                      |
| `testClaimTimeout`         | Alice recovers funds after expiration                                           |
| `testClaimTimeoutTooEarly` | `claimTimeout` reverts before expiration is reached                             |

```bash
forge test -v
```

---

## Compared to ReceiverPays

This builds on my previous project ([ReceiverPays](../ReceiverPays/)) with a key architectural difference:

|              | ReceiverPays            | SimplePaymentChannel       |
| ------------ | ----------------------- | -------------------------- |
| Recipients   | Multiple                | One (fixed at deploy)      |
| Messages     | Independent per payment | Cumulative (last one wins) |
| On-chain txs | One per claim           | Always 2 total             |
| Nonce needed | Yes                     | No                         |
| Timeout      | No                      | Yes                        |

---

## Run it yourself

```bash
git clone <this-repo>
cd SimplePaymentChannel
forge install
forge test
```

---

## What I'm learning

I'm working through the [Solidity docs](https://docs.soliditylang.org/) hands-on, building each pattern from scratch. This project covers:

- Unidirectional payment channel architecture
- Off-chain signing and on-chain verification
- Cumulative vs independent payment models
- Timeout and expiration mechanics
- Adversarial test cases with Foundry's `vm.prank`, `vm.warp`, and `vm.expectRevert`

---

## About me

I'm a data scientist expanding into blockchain development — bringing the same rigorous, test-driven mindset I use in Python to smart contract engineering.

🔗 [LinkedIn](https://www.linkedin.com/in/ichbinzeed)
