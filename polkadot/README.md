# 💠 Polkadot Staking Guide: How to Join a Nomination Pool <a id="top"></a>

<img src="https://github.com/mART321/ITstake/blob/main/img/ITR%20redesign.png" alt="stake banner" style="width: 100%; height: 100%; object-fit: cover;" />

## 📚 Table of Contents

- [🔰 Introduction](#introduction)
- [🪪 1. Wallet Creation](#1-wallet-creation)
- [🔌 2. Checking the Minimum Stake](#2-checking-the-minimum-stake)
- [💸 3. Funding the Wallet](#3-funding-the-wallet)
- [🏦 4. Joining a Nomination Pool](#4-joining-a-nomination-pool)
- [✅ 5. Participation Verification](#5-participation-verification)
- [🏁 Conclusion](#conclusion)

---

## 🔰 Introduction <a id="introduction"></a>

**Polkadot** is a scalable multi-chain network that enables interoperability between different blockchains. Staking DOT tokens helps secure the network and allows you to earn rewards.

This guide walks you through the steps to join a nomination pool using the `Polkadot.js` interface.

---

### 🪪 1. Wallet Creation <a id="1-wallet-creation"></a>

<details open>
<summary>1. Install the Polkadot.js Extension</summary>

[Go to installation](https://polkadot.js.org/extension/)

<img src="https://github.com/mART321/ITstake/blob/main/img/sait.png" alt="extension install" style="width: 40%; height: 40%; object-fit: cover;" />
<img src="https://github.com/mART321/ITstake/blob/main/img/dwn.png" alt="extension download" style="width: 40%; height: 40%; object-fit: cover;" />
</details>

<details open>
<summary>2. Open the extensions menu and find Polkadot{.js}</summary>

Ensure the extension is active and visible.
</details>

<details open>
<summary>3. Create a new account</summary>

Click the extension icon → **+** → **Create new account**

<img src="https://github.com/mART321/ITstake/blob/main/img/c1.png" alt="create account" style="width: 40%; height: 40%; object-fit: cover;" />
</details>

<details open>
<summary>4. Save the seed phrase</summary>

This is the only way to recover your account. Store it securely.

<img src="https://github.com/mART321/ITstake/blob/main/img/c2.jpeg" alt="seed phrase" style="width: 40%; height: 40%; object-fit: cover;" />
</details>

<details open>
<summary>5. Finalize account setup</summary>

Set a name and password to complete setup.

<img src="https://github.com/mART321/ITstake/blob/main/img/c3.png" alt="account ready" style="width: 40%; height: 40%; object-fit: cover;" />
</details>

<details open>
<summary>6. Confirm account appears</summary>

The wallet should look like this:

<img src="https://github.com/mART321/ITstake/blob/main/img/c4.png" alt="account shown" style="width: 40%; height: 40%; object-fit: cover;" />
</details>

---

## 📉 2. Checking the Minimum Stake <a id="2-checking-the-minimum-stake"></a>

1. Open the [Chain State section](https://polkadot.js.org/apps/?rpc=wss%3A%2F%2Fpolkadot.api.onfinality.io%2Fpublic-ws#/chainstate)

2. Select from the dropdown:

<details open>
<summary>- module: `staking`</summary>
<img src="https://github.com/mART321/ITstake/blob/main/img/pd1.png" style="width: 60%; height: 60%; object-fit: cover;" />
</details>

<details open>
<summary>- method: `minNominatorBond()`</summary>
<img src="https://github.com/mART321/ITstake/blob/main/img/pd23.png" style="width: 60%; height: 60%; object-fit: cover;" />
</details>

3. Click the **“+”** button to check the current threshold.

<details open>
<summary>Example output</summary>
<img src="https://github.com/mART321/ITstake/blob/main/img/pd4.png" style="width: 60%; height: 60%; object-fit: cover;" />
</details>

Note: If the result is `2,500,000,000,000`, that means **2.5 DOT**. One DOT equals 10^12 Plancks. Thresholds may change, so check before staking.

---

## 💸 3. Funding the Wallet <a id="3-funding-the-wallet"></a>

Transfer **DOT** tokens to your account address from a centralized exchange (such as Binance, Kraken, or Bybit).

Recommended to deposit slightly more than the minimum stake (e.g. 0.3–0.5 DOT) to cover fees and variations in network parameters.

---

## 🏦 4. Joining a Nomination Pool <a id="4-joining-a-nomination-pool"></a>

1. Go to the [Staking → Pools section](https://polkadot.js.org/apps/?rpc=wss://polkadot-mainnet-rpc.itrocket.net#/staking/pools)

2. Use the search bar or scroll to find a nomination pool.

<details open>
<img src="https://github.com/mART321/ITstake/blob/main/img/pd5.png" style="width: 50%; height: 50%; object-fit: cover;" />
</details>

3. Click **Join** next to the pool of your choice.

<details open>
<img src="https://github.com/mART321/ITstake/blob/main/img/pd6.png" style="width: 50%; height: 50%; object-fit: cover;" />
</details>

4. Specify the amount you want to stake (above minimum).

<details open>
<img src="https://github.com/mART321/ITstake/blob/main/img/pd7.png" style="width: 50%; height: 50%; object-fit: cover;" />
</details>

5. Confirm the transaction in Polkadot.js Extension.

<details open>
<img src="https://github.com/mART321/ITstake/blob/main/img/34.png" style="width: 50%; height: 50%; object-fit: cover;" />
</details>

---

## ✅ 5. Participation Verification <a id="5-participation-verification"></a>

1. Return to **Pools** and check that your account is listed as a member.

<details open>
<img src="https://github.com/mART321/ITstake/blob/main/img/pd8.png" style="width: 50%; height: 50%; object-fit: cover;" />
</details>

2. Rewards will begin to accrue after 1–2 eras.

---

## 🏁 Conclusion <a id="conclusion"></a>

You have successfully staked your DOT tokens by joining a nomination pool. Your contribution helps secure the Polkadot network and earns you rewards over time.

---

[🔝 Back to top](#top)

