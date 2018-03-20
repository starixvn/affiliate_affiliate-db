/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_CheckSum]
	@Date		SMALLDATETIME	= NULL,
	@IsMatch	BIT				= 1 OUTPUT
AS

/*
	Created by Percy:
	Date: 2017-10-20
	DB: DBAFF12BET.Affiliate_12BET
	Task: Check Sum data

	Revisions:
		- 20171020@Percy: Add new SP [RedmineID: #84602]
		- 20180320@Percy: Add more condition to check [RedmineID: #90861]
*/

BEGIN
	SET NOCOUNT ON

	-- Default: the day before yesterday
	IF @Date IS NULL
	BEGIN
		SELECT @Date = DATEADD(DAY, -2, CONVERT(DATE, GETDATE()))
	END

	IF EXISTS (SELECT TOP 1 SportType FROM dbo.MemberDaily_Invalid WITH (NOLOCK) WHERE WinlostDate >= @Date AND Reason = 'Invalid CreateDate')
	BEGIN
		SELECT @IsMatch = 0
		
		SELECT
			'MemberDaily_Invalid'
			+ ' - ' + CONVERT(VARCHAR(10), A.WinlostDate, 101)
			+ ' - ' + ISNULL(s.SportName, CONVERT(VARCHAR(20), A.SportType)) AS Description,
			A.Deposit, A.Withdrawal, A.Bonus, A.Adjustment, A.Turnover, A.Winlost
		FROM
		(
			SELECT
				WinlostDate, SportType,
				SUM(ISNULL(Deposit, 0))		AS Deposit,
				SUM(ISNULL(Withdrawal, 0))	AS Withdrawal,
				SUM(ISNULL(Bonus, 0))		AS Bonus,
				SUM(ISNULL(Adjustment, 0))	AS Adjustment,
				SUM(ISNULL(Turnover, 0))	AS Turnover,
				SUM(ISNULL(Winlost, 0))		AS Winlost
			FROM dbo.MemberDaily_Invalid WITH (NOLOCK)
			WHERE WinlostDate >= @Date
			GROUP BY WinlostDate, SportType
		) AS A
			LEFT JOIN dbo.SportType s WITH (NOLOCK) ON A.SportType = s.SportID
		ORDER BY WinlostDate, SportType
	END
	ELSE
	BEGIN
		SELECT @IsMatch = 1
	END
END
GO