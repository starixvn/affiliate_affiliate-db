/*<info serverAlias="DBAFFN8G-Affiliate_N8G" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_ExchangeOanda_Import]
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Import data from ExchangeDailyOanda

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	DECLARE @LastImportedTime DATETIME
	SELECT  @LastImportedTime = CONVERT(DATETIME, SValue)
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'LastImportedTime_ExchangeOanda'

	IF DATEDIFF(HOUR, @LastImportedTime, GETDATE()) < 6
		RETURN

	DECLARE @CurrentDate SMALLDATETIME
	SELECT  @CurrentDate = CONVERT(DATE, GETDATE())

	-- from yesterday to tomorrow
	DECLARE @tblExchangeDate TABLE (ExchangeDate SMALLDATETIME)
	INSERT INTO @tblExchangeDate (ExchangeDate)
	SELECT DATEADD(DAY, -1, @CurrentDate)
	UNION ALL
	SELECT @CurrentDate
	UNION ALL
	SELECT DATEADD(DAY, 1, @CurrentDate)

	DECLARE @tblExchangeOanda TABLE (ExchangeDate SMALLDATETIME, ExchangeId INT, Code VARCHAR(5), ActualRate FLOAT, VND FLOAT, EUR FLOAT, USD FLOAT, CNY FLOAT, MYR FLOAT, IsNew BIT)
	INSERT INTO @tblExchangeOanda (ExchangeDate, ExchangeId, Code, ActualRate, VND, EUR, USD, CNY, MYR, IsNew)
	SELECT e.ExchangeDate, e.ExchangeId, e.Code, e.ActualRate, e.VND, e.EUR, e.USD, e.CNY, e.MYR, 1 AS IsNew
	FROM @tblExchangeDate t
		CROSS APPLY (
			SELECT e.ExchangeDate, e.ExchangeId, e.Code, e.ActualRate, e.VND, e.EUR, e.USD, e.CNY, e.MYR
			FROM bodb02.dbo.ExchangeDailyOanda e WITH (NOLOCK)
			WHERE t.ExchangeDate = e.ExchangeDate
		) e

	;WITH CTE_ExchangeOanda AS
	(
		SELECT ExchangeId, MAX(ExchangeDate) AS ExchangeDate
		FROM dbo.ExchangeOanda WITH (NOLOCK)
		WHERE ExchangeDate <= DATEADD(DAY, 1, @CurrentDate)
		GROUP BY ExchangeId
	)
	INSERT INTO @tblExchangeOanda (ExchangeDate, ExchangeId, Code, ActualRate, VND, EUR, USD, CNY, MYR, IsNew)
	SELECT e.ExchangeDate, e.ExchangeId, e.Code, e.ActualRate, e.VND, e.EUR, e.USD, e.CNY, e.MYR, 0 AS IsNew
	FROM dbo.ExchangeOanda e WITH (NOLOCK)
		INNER JOIN CTE_ExchangeOanda c ON e.ExchangeDate = c.ExchangeDate AND e.ExchangeId = c.ExchangeId

	DELETE r
	FROM (
		SELECT *, ROW_NUMBER() OVER(PARTITION BY ExchangeId, ActualRate, VND, EUR, USD, CNY, MYR ORDER BY ExchangeDate DESC) AS RowNum
		FROM @tblExchangeOanda
	) r
	WHERE r.RowNum > 1

	IF EXISTS (SELECT 1 FROM @tblExchangeOanda WHERE IsNew = 1)
	BEGIN
		INSERT INTO dbo.ExchangeOanda (ExchangeDate, ExchangeId, Code, ActualRate, VND, EUR, USD, CNY, MYR)
		SELECT ExchangeDate, ExchangeId, Code, ActualRate, VND, EUR, USD, CNY, MYR
		FROM @tblExchangeOanda
		WHERE IsNew = 1
	END

	UPDATE dbo.SystemSettings WITH (ROWLOCK)
	SET SValue = CONVERT(VARCHAR(20), GETDATE(), 120)
	WHERE SName = 'LastImportedTime_ExchangeOanda'
END
GO