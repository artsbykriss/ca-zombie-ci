> For the complete documentation index, see [llms.txt](https://documents.peakdefi.com/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://documents.peakdefi.com/for-asset-managers/how-to-for-asset-managers.../making-a-trade.md).

# Open and Manage a Trade

Open and Close Buy / Sell / Margin Trades

## Open a Trade

To make an Order just click on the fund tab in your Dashboard or in the navigation tab on the Market tab and click on the the "Trade" button. You then can choose between 70+ Assets which you want to trade and how you want to trade (buy / sell / leverage), the amount of Reputation Token you want to stake (which determine the size of the position), the max accept. buy price and the Liquidity Provider.

![](https://2912952422-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-MGIrVj0_5_Ki3ix6PzR%2F-MHqNmgsAh_FVv_FtPY3%2F-MHtzYXJ9aW5yXYURb8N%2Fimage.png?alt=media\&token=184f450f-3a6b-40e0-99c8-1fc2d2026905)

{% hint style="info" %}
The order size depends on the amount of Reputation Token you are going to stake. E.g. if you have 100 Reputation Token which for instance represent a Managed Capital of 10.000 USDC and you want to invest 1000 USDC in this trade = 10% you have to stake 10% of your Reputation Token = 10.

The max acceptable buy price is the slippage (price tolerance) you accept. E.g. a max acceptable buy price of 3% means that you are willing to accept a buy price deviation of 3%.

Liquidity Provider is the exchange which you choose for executing the trade.
{% endhint %}

## Buy and Sell Orders

When you click on the "Trade" Button you can choose the Asset and your position (buy / sell / Margin Trades).

When you open a "Sell" order it means that you are betting on a price decrease and want to take advantage of it. This is also called a **Short Order**. A short order is created by taking out a loan denominated in the asset that you wish to short, with collateral denominated in USDC (or an other stable coin). The loaned asset is immediately converted to the stable currency. If the asset's price falls, the value of your debt also falls, meaning you need to pay back less money, giving you a profit. If the price rises, your debt increases, and you lose money.

{% hint style="info" %}
PEAKDEFI uses the service of [Compound Finance](https://compound.finance/) for executing leveraged long & short trades.
{% endhint %}

## Margin Trade

Margin Trades or leveraged orders enhance a trade position by a factor x. For instance, if you made a leveraged long order with 1.5x leverage, and the price of the underlying asset increased by 10%, your return would be 15%. Of course the same ratio applies if the price goes in the wrong direction, e.g. if the price of the asset decreased by 10%  you would lose 15%.

### Collateral

Leveraged long orders are made by taking out loans denominated in a stable currency (like DAI), with the collateral denominated in the asset you want to long. The loaned stable currency is immediately converted to the asset you want to long. This means that you would be exposed to the asset's price changes not only through the collateral, but also through the loaned assets, effectively amplifying your returns (and losses).

### Top Up

When making margin orders, PEAKDEFI takes out loans backed by collateral. If the ratio of collateral to debt (the collateral ratio) is too low, the loan platform (Compound) will liquidate the loan, which entails the loss of the collateral.

To prevent liquidation, you can top up an order's collateral on the platform. This action does not require additional staking of Reputation Token.

You can monitor your collateral status for each order in your Managers Dashboard.

## Monitor your Trades

You can monitor you trades and see your Trading History in the "Trades" area at your Dashboard. Here you can close an open position again or if your leveraged position is in danger (to be liquidated) you can Top Up your collateral.

![](https://2912952422-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-MGIrVj0_5_Ki3ix6PzR%2F-MHqNmgsAh_FVv_FtPY3%2F-MHu4yS0EKDQ7KFYHMc2%2Fimage.png?alt=media\&token=5a35c7a4-5fe9-47ba-a4a2-b9bbae49a457)

## Close your Trade

If you click on the "Close" Button you will get an overview about your trading details for this trade. You can see the Asset Price, the current amount of Reputation Token in this trade which you can (partially) redeem, the trade value in USDC and the ROI of this trade. If the trade is a margin trade you also see the collateral status.

![](https://2912952422-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-MGIrVj0_5_Ki3ix6PzR%2F-MHqNmgsAh_FVv_FtPY3%2F-MHu5lH3-1lmWDaYP99v%2Fimage.png?alt=media\&token=bd40cf72-9f20-4d89-a024-6e1d440b0fb0)

You close a position if you redeem the whole / max Reputation Token for this trade. If for instance you want to close only 50% of the position you can do it by redeeming only 50% of the max. By choosing the max. acceptable close price you are willing to accept this price deviation from current asset price to close the trade.&#x20;

{% hint style="info" %}
The "Reputation Token to Redeem" fluctuates as the price of the asset changes and therefore your ROI. If the trade turns negative the amount of reputation token in this trade also decreases under the value you put into the staking. If the trade turns profitable the amount of your reputation token also increases above the level that you put into staking.&#x20;
{% endhint %}
