/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Adjustment_Upd]
	@XmlData	XML
	,@UserId	INT
	,@IP		VARCHAR(20) = ''
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000) = '' OUTPUT
	,@Language	VARCHAR(10) = 'en-US'
AS

/*
	Created: 20210113@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Affiliate - Adjustment - Import Data

	Revisions:
		- 20210113@Malcolm: Initialize SP [RedmineID: #147902]
		- 20210128@Malcolm: Convert amount from varchar(max) to money [RedmineID: #147902]

	Param's Explanation
		.@XmlData = <root><r Username="" Amount="" Description=""/></root>
*/

BEGIN
	SET NOCOUNT ON
	--money
	DECLARE @ID INT = 1, @LogData NVARCHAR(MAX), @SPName VARCHAR(50), @AffId INT
	
	DECLARE @MinMoney DECIMAL(38,6) = -922337203685477.5808, @MaxMoney DECIMAL(38,6) = 922337203685477.5807

	SELECT @ErrCode = 0, @ErrMsg = ''

	-- Check permisison
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[AffAdjustment]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	CREATE TABLE #Input 
	(
		ID			INT IDENTITY(1,1), 
		AffID		INT, 
		Username	NVARCHAR(30), 
		Amount		VARCHAR(MAX), 
		Description NVARCHAR(300), 
		Currency	INT, 
		AffExRate	FLOAT, 
		ErrorMsg	VARCHAR(MAX),
		IsInvalid	BIT DEFAULT(0)
	)

	INSERT INTO #Input (Username, Amount, Description)
	SELECT 
		t.c.value('@Username', 'NVARCHAR(30)')
		,t.c.value('@Amount', 'VARCHAR(MAX)')
		,t.c.value('@Description', 'NVARCHAR(300)')
	FROM @XmlData.nodes('root/r') t(c)
	OPTION (OPTIMIZE FOR (@XmlData = NULL))

	UPDATE i
		SET i.ErrorMsg	 = COALESCE(i.ErrorMsg,'') + 
						   CASE WHEN ISNULL(i.Username,'') = '' THEN 'Username cannot be blank.'
								WHEN af.AffID IS NOT NULL AND (ISNULL(af.Status, '') <> 'Approved' OR Ma.r IS NULL) THEN 'Username is invalid'
								WHEN af.AffID IS NULL THEN CHAR(13) + CHAR(10) + 'This username does not exist.' + CASE WHEN e.r IS NOT NULL THEN CHAR(13) + CHAR(10) + 'This username is duplicate.' ELSE '' END
							    WHEN e.r IS NOT NULL THEN CHAR(13) + CHAR(10) + 'This username is duplicate.'
						   ELSE '' END
			,i.Currency	 = CASE WHEN  af.AffID IS NOT NULL THEN af.Currency ELSE i.Currency END
			,i.AffID	 = CASE WHEN  af.AffID IS NOT NULL THEN af.AffID ELSE i.AffID END
	FROM #Input i
		LEFT JOIN dbo.AffInfo af WITH(NOLOCK) ON af.UserName = i.Username 
		LEFT JOIN dbo.AffDetail d WITH(NOLOCK) ON d.AffID = af.AffID
	OUTER APPLY(SELECT TOP 1 1 AS r FROM #Input p WHERE p.Username = i.Username AND p.ID <> i.ID) AS e
	OUTER APPLY (SELECT TOP 1 1 AS r FROM UserMarket u WHERE u.CustId = @UserId AND u.MarketId = d.PreferredLanguage) AS Ma

	UPDATE i
		SET i.ErrorMsg = COALESCE(i.ErrorMsg, '') + 
						 CASE WHEN i.Amount LIKE '%[^0-9,.+-]%' THEN CHAR(13) + CHAR(10) + 'The amount is invalid.'
							  WHEN ISNUMERIC(i.Amount) = 0      THEN CHAR(13) + CHAR(10) + 'The amount is invalid.'
							  WHEN CHARINDEX('.', REPLACE(REPLACE(REPLACE(I.Amount, '+', ''),'-', ''),',','') + '.') > 16 
									THEN CASE WHEN i.Amount LIKE '-%' THEN  CHAR(13) + CHAR(10) + 'The amount is too small.' 
										 ELSE CHAR(13) + CHAR(10) + 'The amount is too big.' END
							  WHEN CONVERT(DECIMAL(38,6), REPLACE(i.Amount, ',', '')) > @MaxMoney THEN CHAR(13) + CHAR(10) + 'The amount is too big.'
							  WHEN CONVERT(DECIMAL(38,6), REPLACE(i.Amount, ',', '')) < @MinMoney THEN CHAR(13) + CHAR(10) + 'The amount is too small.'
							  WHEN CONVERT(DECIMAL(38,6), REPLACE(i.Amount, ',', '')) + ISNULL(CONVERT(DECIMAL(38,6), a.BalBroughtForward), 0) > @MaxMoney 
									THEN CHAR(13) + CHAR(10) + 'The amount is too big.'
							  WHEN CONVERT(DECIMAL(38,6), REPLACE(i.Amount, ',', '')) + ISNULL(CONVERT(DECIMAL(38,6), a.BalBroughtForward), 0) < @MinMoney 
									THEN CHAR(13) + CHAR(10) + 'The amount is too small.'
							  WHEN CONVERT(DECIMAL(38,6), REPLACE(i.Amount, ',', '')) = 0 THEN CHAR(13) + CHAR(10) + 'The amount is invalid.'
						 ELSE '' END
	FROM #Input i
	OUTER APPLY(
		SELECT TOP 1 b.BalBroughtForward
		FROM dbo.Aff_f_GetBalBroughtForward(i.AffId) b 
	) a
	
	IF EXISTS(SELECT TOP 1 1 FROM #Input WHERE ISNULL(ErrorMsg, '') <> '')
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'The upload process is not completed. There are some invalid username/amount in your file.'
		SELECT Username, Amount, ErrorMsg FROM #Input WHERE ISNULL(ErrorMsg, '') <> ''
		RETURN
	END

	UPDATE i
		SET i.AffExRate = e.ActualRate
	FROM #Input i
		INNER JOIN dbo.Exchange_Current e WITH(NOLOCK) ON e.ExchangeID = i.Currency

	BEGIN TRY
		INSERT INTO dbo.AffTrans
		(	
			AffID
			,TransDate
			,CompletedDate
			,Amount
			,Status
			,Description
			,Creator
			,Currency
			,TransType
			,AffExRate
		)
		SELECT 
			AffID
			,GETDATE()
			,GETDATE()
			,CONVERT(MONEY, REPLACE(Amount, ',', ''))
			,'Completed'
			,Description
			,@UserId
			,Currency
			,203
			,AffExRate
		FROM #Input
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 104, @ErrMsg = dbo.Aff_f_GetMessageById(1303, @Language)
		RETURN
	END CATCH
	
	-- Write Log
	SELECT @SPName = OBJECT_NAME(@@PROCID)

	WHILE 1 = 1
	BEGIN
		IF NOT EXISTS(SELECT TOP 1 1 FROM #Input WHERE ID = @ID)
			BREAK

		SELECT @AffId = AffID, @LogData = 'Amount=' + CONVERT(VARCHAR(50), CONVERT(MONEY, REPLACE(Amount, ',', ''))) FROM #Input WHERE ID = @ID

		EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
			@UserID = @UserId
			,@AffID = @AffId
			,@SPName = @SPName
			,@OldData = ''
			,@NewData = @LogData
			,@IP = @IP
			,@Language = @Language

		SET @ID += 1
	END

	DROP TABLE #Input
	
END
GO