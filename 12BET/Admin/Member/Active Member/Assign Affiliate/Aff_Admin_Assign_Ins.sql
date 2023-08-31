/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/  
CREATE PROCEDURE [dbo].[Aff_Admin_Assign_Ins]    
	@UserId				INT
	,@AffName   		VARCHAR(50)
	,@DepositUsername 	NVARCHAR(30)
	,@IP    			VARCHAR(45) = ''
	,@ErrCode   		INT = 0 OUTPUT
	,@ErrMsg   			NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20230908@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Member - Active Member - Assign Affiliate - Insert into MemberInfo

	Revisions:
	- 20230908@Eddie: Initialize SP [RedmineID: #180516]

	Param's Explanation:    
			- @DepositUsername: Deposit user need to assign affiliate
*/    
    
BEGIN
	SET NOCOUNT ON

	DECLARE @AffId INT

	SELECT @AffName = LTRIM(RTRIM(ISNULL(@AffName, '')))
	SELECT @DepositUsername = LTRIM(RTRIM(ISNULL(@DepositUsername, '')))

	-- Checking affiliate to assign
	EXEC dbo.Aff_Admin_Assign_Check @AffName = @AffName, @AffId = @AffId OUTPUT, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid Affiliate'
		RETURN
	END

	-- Once again, checking deposit user has assigned already or not yet
	IF EXISTS(SELECT 1 FROM dbo.MemberInfo WITH (NOLOCK) WHERE UserName = CONVERT(VARCHAR(50), '12Bet$' + @DepositUsername))
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'This member is assigned affiliate!'
		RETURN
	END

	DROP TABLE IF EXISTS #depositMember

	-- Insert into MemberInfo
	SELECT TOP(1) c.custid  AS IBCCustID    
		,@AffId     		AS AffID    
		,dc.AffiliateID   	AS AffiliateIDDeposit -- to check affid from DepositDB
		,'12Bet$' + dc.username AS UserName
		,c.username    		AS IBCUserName
		,c.creatdate    	AS CreatedDate
		,0       			AS IsRemoved
		,dc.custid     		AS DepositCustID
		,''      			AS FirstName
		,''      			AS LastName
		,dc.currency    	AS Currency
		,c.recommend    	AS Recommend
		,''      			AS Email
		,dc.creatdate   	AS RegisteredDate
		,dc.ClickId    		AS ClickId
		,CURRENT_TIMESTAMP	AS AssignDate
	INTO #depositMember
	FROM [DBDEPOSIT2].deposit_db.dbo.v_Aff_DepCust dc WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON c.username2 = CONVERT(VARCHAR(50), '12Bet$' + dc.Username)
	WHERE dc.username = @DepositUsername AND ISNULL(dc.AffiliateID, 0) <> 0

	BEGIN TRY
		INSERT INTO dbo.MemberInfo (
			IBCCustID
			,AffID
			,UserName
			,IBCUserName
			,CreatedDate
			,IsRemoved
			,DepositCustID
			,FirstName
			,LastName
			,Currency
			,Recommend
			,Email
			,RegisteredDate
			,ClickId
			,AssignDate
		)
		SELECT
			IBCCustID
			,AffID
			,UserName
			,IBCUserName
			,CreatedDate
			,IsRemoved
			,DepositCustID
			,FirstName
			,LastName
			,Currency
			,Recommend
			,Email
			,RegisteredDate
			,ClickId
			,AssignDate
		FROM #depositMember
		WHERE RegisteredDate IS NOT NULL
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 103, @ErrMsg = 'Insert MemberInfo Unsuccessfully!'
		RETURN
	END CATCH

	-- Write log info
	DECLARE @LogData NVARCHAR(4000), @LogData1 NVARCHAR(4000), @SPName VARCHAR(100), @CurrencyName NVARCHAR(50)

	SELECT @CurrencyName = ec.Currency
	FROM dbo.Exchange_Current ec WITH (NOLOCK)
		INNER JOIN #depositMember dm ON dm.Currency = ec.ExchangeID

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	SELECT @LogData =  CONVERT(NVARCHAR(MAX), ( SELECT
													IBCCustID   	AS '@IBCCustID'
													,AffID    		AS '@AffID'
													,AffiliateIDDeposit AS '@AffiliateIDDeposit'
													,UserName   	AS '@UserName'
													,IBCUserName  	AS '@IBCUserName'
													,DepositCustID  AS '@DepositCustID'
													,IsRemoved   	AS '@IsRemoved'
													,FirstName   	AS '@FirstName'
													,LastName   	AS '@LastName'
													,@CurrencyName  AS '@Currency'
													,Recommend   	AS '@Recommend'
													,Email    		AS '@Email'
													,RegisteredDate AS '@RegisteredDate'
													,ClickId   		AS '@ClickId'
													,AssignDate  	AS '@AssignDate'
													,CreatedDate  	AS '@FistDepositDate'
													,CASE WHEN RegisteredDate IS NULL THEN 'Failed' ELSE 'Success' END AS '@Status'
												FROM #depositMember
												FOR XML PATH('row'), ROOT('root')))

	SELECT @LogData1 =  CONVERT(NVARCHAR(MAX), ( SELECT @DepositUsername AS '@MemberUserName'    
												 FOR XML PATH('row'), ROOT('root')))

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId  	= @UserId    
		,@AffId  	= @AffId    
		,@SPName 	= @SPName    
		,@OldData 	= ''    
		,@NewData 	= @LogData    
		,@IP  		= @IP    
		,@IsShow 	= 0 -- no need show View Log because UI wanna show only deposit username

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog    
		@UserId  	= @UserId    
		,@AffId  	= @AffId    
		,@SPName 	= @SPName    
		,@OldData 	= ''    
		,@NewData 	= @LogData1    
		,@IP  		= @IP    

	DROP TABLE #depositMember
END