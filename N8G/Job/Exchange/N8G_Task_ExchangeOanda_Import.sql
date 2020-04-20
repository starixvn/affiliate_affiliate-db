/*<info serverAlias="DBAFFN8G-Affiliate_N8G" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_ExchangeOanda_Import]
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Import Exchange data from ExchangeDailyOanda

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

	DECLARE @tblExchange TABLE
	(
		ExchangeId		INT
		,Code			VARCHAR(5)
		,ActualRate		FLOAT
		,VND			FLOAT
		,EUR			FLOAT
		,USD			FLOAT
		,CNY			FLOAT
		,MYR			FLOAT
		,ModifiedType	TINYINT -- 1 - insert, 2 - update
	)

	-- Yesterday data
	DECLARE @Yesterday SMALLDATETIME
	SELECT  @Yesterday = DATEADD(DAY, -1, @CurrentDate)
	
	BEGIN
		UPDATE e WITH (ROWLOCK)
		SET e.Code			= o.Code
			,e.ActualRate	= o.ActualRate
			,e.VND			= o.VND
			,e.EUR			= o.EUR
			,e.USD			= o.USD
			,e.CNY			= o.CNY
			,e.MYR			= o.MYR
		OUTPUT
			INSERTED.ExchangeId, INSERTED.Code, INSERTED.ActualRate, INSERTED.VND, INSERTED.EUR, INSERTED.USD, INSERTED.CNY, INSERTED.MYR, 1 -- insert (default)
		INTO @tblExchange
			(ExchangeId, Code, ActualRate, VND, EUR, USD, CNY, MYR, ModifiedType)
		FROM dbo.Exchange e
			INNER JOIN bodb02.dbo.ExchangeDailyOanda o WITH (NOLOCK) ON o.ExchangeId = e.ExchangeId
		WHERE o.ExchangeDate = @Yesterday
			AND (
				o.Code			<> e.Code
				OR o.ActualRate <> e.ActualRate
				OR o.VND		<> e.VND
				OR o.EUR		<> e.EUR
				OR o.USD		<> e.USD
				OR o.CNY		<> e.CNY
				OR o.MYR		<> e.MYR
			)

		INSERT INTO dbo.Exchange (ExchangeId, Code, ActualRate, VND, EUR, USD, CNY, MYR)
		OUTPUT
			INSERTED.ExchangeId, INSERTED.Code, INSERTED.ActualRate, INSERTED.VND, INSERTED.EUR, INSERTED.USD, INSERTED.CNY, INSERTED.MYR, 1 -- insert (default)
		INTO @tblExchange
			(ExchangeId, Code, ActualRate, VND, EUR, USD, CNY, MYR, ModifiedType)
		SELECT
			o.ExchangeId, o.Code, o.ActualRate, o.VND, o.EUR, o.USD, o.CNY, o.MYR
		FROM bodb02.dbo.ExchangeDailyOanda o WITH (NOLOCK)
			LEFT JOIN dbo.Exchange e WITH (NOLOCK) ON e.ExchangeId = o.ExchangeId
		WHERE o.ExchangeDate = @Yesterday
			AND e.ExchangeId IS NULL

		UPDATE t
		SET t.ModifiedType = 2 -- update due to exists
		FROM @tblExchange t
			INNER JOIN dbo.ExchangeOanda e WITH (NOLOCK) ON t.ExchangeId = e.ExchangeId
		WHERE e.ExchangeDate = @Yesterday

		IF EXISTS (SELECT 1 FROM @tblExchange WHERE ModifiedType = 2)
		BEGIN
			UPDATE e WITH (ROWLOCK)
			SET e.Code			= t.Code
				,e.ActualRate	= t.ActualRate
				,e.VND			= t.VND
				,e.EUR			= t.EUR
				,e.USD			= t.USD
				,e.CNY			= t.CNY
				,e.MYR			= t.MYR
			FROM dbo.ExchangeOanda e
				INNER JOIN @tblExchange t ON e.ExchangeId = t.ExchangeId
			WHERE e.ExchangeDate = @Yesterday
				AND t.ModifiedType = 2
		END

		IF EXISTS (SELECT 1 FROM @tblExchange WHERE ModifiedType = 1)
		BEGIN
			INSERT INTO dbo.ExchangeOanda (ExchangeDate, ExchangeId, Code, ActualRate, VND, EUR, USD, CNY, MYR)
			SELECT @Yesterday, ExchangeId, Code, ActualRate, VND, EUR, USD, CNY, MYR
			FROM @tblExchange
			WHERE ModifiedType = 1
		END

		IF EXISTS (SELECT 1 FROM @tblExchange)
		BEGIN
			DELETE dbo.ExchangeOanda WITH (ROWLOCK, UPDLOCK)
			WHERE ExchangeDate > @Yesterday
		END
	END

	-- Today & Tomorrow data
	DECLARE @ImportedDate SMALLDATETIME
	SELECT  @ImportedDate = DATEADD(DAY, 1, @Yesterday)

	WHILE @ImportedDate <= DATEADD(DAY, 2, @Yesterday)
	BEGIN
		DELETE @tblExchange

		INSERT INTO @tblExchange (ExchangeId, Code, ActualRate, VND, EUR, USD, CNY, MYR, ModifiedType)
		SELECT
			o.ExchangeId, o.Code, o.ActualRate, o.VND, o.EUR, o.USD, o.CNY, o.MYR
			,CASE
				WHEN e1.ExchangeId IS NOT NULL
					THEN CASE WHEN o.Code <> e1.Code OR o.ActualRate <> e1.ActualRate OR o.VND <> e1.VND OR o.EUR <> e1.EUR OR o.USD <> e1.USD OR o.CNY <> e1.CNY OR o.MYR <> e1.MYR
						THEN 2 -- update
						ELSE 0 END -- no action
				WHEN e2.ExchangeId IS NOT NULL
					THEN CASE WHEN o.Code <> e2.Code OR o.ActualRate <> e2.ActualRate OR o.VND <> e2.VND OR o.EUR <> e2.EUR OR o.USD <> e2.USD OR o.CNY <> e2.CNY OR o.MYR <> e2.MYR
						THEN 1 -- insert
						ELSE 0 END -- no action
				WHEN e3.ExchangeId IS NOT NULL
					THEN CASE WHEN o.Code <> e3.Code OR o.ActualRate <> e3.ActualRate OR o.VND <> e3.VND OR o.EUR <> e3.EUR OR o.USD <> e3.USD OR o.CNY <> e3.CNY OR o.MYR <> e3.MYR
						THEN 1 -- insert
						ELSE 0 END -- no action
				ELSE 1 END -- insert (new currencies)
		FROM bodb02.dbo.ExchangeDailyOanda o WITH (NOLOCK)
			LEFT JOIN dbo.ExchangeOanda e1 WITH (NOLOCK) ON o.ExchangeDate = e1.ExchangeDate AND o.ExchangeId = e1.ExchangeId
			LEFT JOIN dbo.ExchangeOanda e2 WITH (NOLOCK) ON e2.ExchangeDate = @CurrentDate AND o.ExchangeId = e2.ExchangeId AND @ImportedDate <> @CurrentDate
			LEFT JOIN dbo.Exchange e3 WITH (NOLOCK) ON o.ExchangeId = e3.ExchangeId
		WHERE o.ExchangeDate = @ImportedDate

		DELETE @tblExchange WHERE ModifiedType = 0

		IF EXISTS (SELECT 1 FROM @tblExchange WHERE ModifiedType = 2)
		BEGIN
			UPDATE e WITH (ROWLOCK)
			SET e.Code			= t.Code
				,e.ActualRate	= t.ActualRate
				,e.VND			= t.VND
				,e.EUR			= t.EUR
				,e.USD			= t.USD
				,e.CNY			= t.CNY
				,e.MYR			= t.MYR
			FROM dbo.ExchangeOanda e
				INNER JOIN @tblExchange t ON e.ExchangeId = t.ExchangeId
			WHERE e.ExchangeDate = @ImportedDate
				AND t.ModifiedType = 2
		END

		IF EXISTS (SELECT 1 FROM @tblExchange WHERE ModifiedType = 1)
		BEGIN
			INSERT INTO dbo.ExchangeOanda (ExchangeDate, ExchangeId, Code, ActualRate, VND, EUR, USD, CNY, MYR)
			SELECT @ImportedDate, ExchangeId, Code, ActualRate, VND, EUR, USD, CNY, MYR
			FROM @tblExchange
			WHERE ModifiedType = 1
		END

		SELECT @ImportedDate = DATEADD(DAY, 1, @ImportedDate)
	END

	-- Update SystemSettings
	UPDATE dbo.SystemSettings WITH (ROWLOCK)
	SET SValue = CONVERT(VARCHAR(20), GETDATE(), 120)
	WHERE SName = 'LastImportedTime_ExchangeOanda'
END
GO