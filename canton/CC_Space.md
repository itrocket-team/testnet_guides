# CC Space

**Explorer · Data API · Monitoring · Analytics** for the Canton Network, by ITRocket.
**https://cc.itrocket.space**

If you know Etherscan, you know the first part: paste an identifier, read balances and transfers.
The rest is a REST API over the same indexed data, alerting on top of it, and network analytics.
**New accounts get 500 free credits.**

## 1. What CC Space is

The Canton Network explorer and data API: **https://cc.itrocket.space**. Mainnet
fully indexed, from the first migration to the update landing now. Six ways in:

**Explorer.** Search any party, transfer, validator or CNS name and read it as a page.
**Data API.** The same data over REST, around 50 endpoints, plus an x402 door where agents pay per request with no signup.
**Ask the API.** A question in plain language, answered from live data by an AI assistant that calls the endpoints for you.
**Analytics.** Network charts for traffic, supply, rewards and featured-app compliance.
**Updates & News.** Canton forum posts, releases, blog announcements and the SV operations schedule, all in one place, sorted by source, topic and who it concerns. Filter it down, then subscribe to exactly that slice.
**Alerts.** Downtime, balance changes, governance votes and news, pushed to email, Telegram, Slack or PagerDuty.

### Three main differences from Ethereum

| On Ethereum | On Canton |
| --- | --- |
| Address `0x1a2b…` | **Party ID** `name::1220<64 hex>`. The whole string is the identifier; truncate it and lookups fail. |
| Gas, paid per transaction from your wallet | **Traffic**, bought in advance by the validator that hosts your party. |
| Everything is public | **Private by default.** Public data is a subset, and the explorer shows you less than Etherscan does, on purpose. |

## 2. Your first task

Look up a party ID and read its transfers, first by eye, then in code.

### In the explorer, no account

Paste a party ID into search, or go straight to the URL. This is a real mainnet validator, so open
it and follow along:

```
https://cc.itrocket.space/blockchain/parties/ITRocket-validator-1::12200ac965a56eff577aa6754516dbc0dd07265a0bf9361466c573e71ab7491ec369
```

You get the party's main details plus an **Operations** table of everything it has done, split by
type.

### How to create or access an account

1. Click **Sign in** in the upper right corner of https://cc.itrocket.space/
2. Choose one of the following options:
   - Sign in with a Google account.
   - Sign up with an email address and verify it via the link sent to that address. If it does not
     arrive within a few minutes, check your Spam and Junk folders.

### Wallet creation

1. Go to the Credits page: https://cc.itrocket.space/account
2. Click **Create wallet and Enable Deposits**
3. Download the secret key and store it somewhere safe. It is the only way back into your wallet,
   and nobody can recover it for you
4. Protect your wallet via:
   - **Passkey**: click **Protect with passkey & continue** to unlock later with Touch ID, Windows
     Hello, or your device PIN.
   - **Password**: click **Use a wallet password**, then set and confirm a password and click
     **Encrypt wallet & continue**.

After this you get **500 free credits**, enough to try the paid features before you decide to fund
the wallet.

### API access via key

1. Go to Settings → API keys: https://cc.itrocket.space/account/settings/api-keys
2. Click **Create key**, give it a name (e.g. *Testing*), click **Create**
3. Copy and store the key, it is shown only once
4. Send a test request with the key as a bearer token. This one reads your balance, which is free
   and never billed, so confirming the key works costs nothing:

```bash
curl https://cc-api.itrocket.space/api/v1/credits/balance \
  -H "Authorization: Bearer YOUR_API_KEY"
```

Then the same party you just opened in the browser, this time its transfers:

```bash
curl "https://cc-api.itrocket.space/api/v1/parties/ITRocket-validator-1::12200ac965a56eff577aa6754516dbc0dd07265a0bf9361466c573e71ab7491ec369/operations?type=transfer&limit=25" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

The first call is free, the second costs one credit.

API reference: https://cc.itrocket.space/api-reference

## Extra task: first 20 participants get 100 CC each

Top up your wallet with **10 Canton Coin** and convert it into credits. The first **20** people to
complete both steps get **100 CC** added to their wallet. Counting starts on **17 September 2026 at
00:00 UTC**. This is also how you top up once the free
credits run out, so it is optional otherwise: 500 credits are enough for testing.

1. Go to https://cc.itrocket.space/account and copy the PartyID
2. Send Canton Coin to that PartyID from any exchange that lists Canton Coin, Bybit and Kraken
   among them, or from your own wallet
3. The balance shows up after a short delay. Once it does, enter the Canton Coin amount under
   **Convert CC to Credits**, check the displayed rate and credit amount, then click **Convert**

*Deposited funds, the 100 CC bonus included, can only be converted to credits: no withdrawals, no
transfers, no going back. Deposit only the amount you intend to convert. The bonus arrives in your
in-app wallet within 24 hours, and the offer runs until 20 wallets have been topped up.*

## 3. What trips people up

**Recipient and amount are hidden.** Not a bug, it's privacy. A row under **Private** shows who
sent it, which validator submitted it, and which asset moved. The recipient and the amount stay
hidden. So you can't reconcile a
party's totals from public transfers alone. Coming from a transparent chain, this is the number one
source of "the explorer is wrong".

**`402`.** A `402` means you are out of credits: the body carries what the call costs, your balance,
and where to top up.

**The explorer host is not the API host.** The site you browse is `cc.itrocket.space`; the API
lives on `cc-api.itrocket.space`. Send an `/api/v1` call to the first one and you get an HTML `404`
instead of JSON, which reads like the endpoint does not exist.

**There are no page numbers.** Paging is a cursor, not an offset. `limit` defaults to 10 and caps
at 100; to go further back, pass the `next_cursor` from the previous response as `before=`.


---

Building an agent? The same endpoints speak **x402**: it pays for each call in CC or USDCx as it
goes, no signup or API key. https://cc.itrocket.space/api-reference#tag/x402
