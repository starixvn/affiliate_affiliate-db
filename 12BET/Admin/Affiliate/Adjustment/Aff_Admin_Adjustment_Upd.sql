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

	Param's Explanation
		.@XmlData = <root><r Username="" Amount="" Description=""/></root>
*/

BEGIN
	SET NOCOUNT ON
	--money
	DECLARE @ID INT = 1, @LogData NVARCHAR(MAX), @SPName VARCHAR(50), @AffId INT
	
	DECLARE @MinMoney DECIMAL(38,6) = -922337203685479, @MaxMoney DECIMAL(38,6) = 922337203685476

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
						   CASE WHEN af.AffID IS NULL THEN 'This username does not exist.' + CASE WHEN e.r IS NOT NULL THEN 'This username is duplicate.' ELSE '' END
							    WHEN e.r IS NOT NULL THEN 'This username is duplicate.'
						   ELSE '' END
			,i.Currency	 = CASE WHEN  af.AffID IS NOT NULL THEN af.Currency ELSE i.Currency END
			,i.AffID	 = CASE WHEN  af.AffID IS NOT NULL THEN af.AffID ELSE i.AffID END
	FROM #Input i
		LEFT JOIN dbo.AffInfo af WITH(NOLOCK) ON af.UserName = i.Username
	OUTER APPLY(
			SELECT TOP 1 1 AS r FROM #Input p WHERE p.Username = i.Username AND p.ID <> i.ID
	) AS e
	
	UPDATE i
		SET i.ErrorMsg = COALESCE(i.ErrorMsg,'') + 
					     CASE WHEN ISNUMERIC(i.Amount) = 0 OR i.Amount LIKE '%e%' THEN ' amount is invalid.' 
						 ELSE CASE WHEN i.Amount Like '%-%' THEN 'The amount is too small.' 
							  ELSE 'The amount is too big.' END 
						 END
			,i.IsInvalid = 1
	FROM #Input i
	WHERE ISNUMERIC(i.Amount) = 0 
		OR CHARINDEX('.', REPLACE(REPLACE(REPLACE(I.Amount, '+', ''),'-', ''),',','') + '.') > 16
		OR i.Amount LIKE '%e%'

	UPDATE i
		SET i.ErrorMsg = COALESCE(i.ErrorMsg, '') + 
						 CASE WHEN CONVERT(DECIMAL(38,6), i.Amount) + ISNULL(CONVERT(DECIMAL(38,6), a.BalBroughtForward), 0) > @MaxMoney THEN 'The amount is too big.'
							  WHEN CONVERT(DECIMAL(38,6), i.Amount) + ISNULL(CONVERT(DECIMAL(38,6), a.BalBroughtForward), 0) < @MinMoney THEN 'The amount is too small.'
						 ELSE '' END
	FROM #Input i
	CROSS APPLY(
		SELECT b.BalBroughtForward
		FROM dbo.Aff_f_GetBalBroughtForward(i.AffId) b 
	) AS a
	WHERE i.IsInvalid = 0
	
	IF EXISTS(SELECT TOP 1 1 FROM #Input WHERE ISNULL(ErrorMsg, '') <> '')
	BEGIN
		SELECT @ErrCode = 101
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
			,CONVERT(MONEY, Amount)
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

		SELECT @AffId = AffID, @LogData = 'Amount=' + CONVERT(VARCHAR(50), Amount) FROM #Input WHERE ID = @ID

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