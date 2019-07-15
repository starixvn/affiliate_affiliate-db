USE Affiliate_12BET
GO

/*
	Created: 20190715@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Re-import data from backup table
*/

INSERT INTO dbo.rptMemberDaily (WinlostDate,AffId,IBCCustId,ProductId,Deposit,Withdrawal,Bonus,Adjustment,Turnover,Winloss,Currency,ExRate,AffExRate)
SELECT WinlostDate,AffId,IBCCustId,ProductId,Deposit,Withdrawal,Bonus,Adjustment,Turnover,Winloss,Currency,ExRate,AffExRate
FROM DBDWCSS.Affiliate_12BET_20190710.dbo.rptMemberDaily WITH (NOLOCK)
WHERE winlostdate >= '2019-06-28' and winlostdate <= '2019-07-04'
	AND productid = -1

GO