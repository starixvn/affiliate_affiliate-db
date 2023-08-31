/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Assign_Affiliate]
	@UserId				INT
	,@AffName			VARCHAR(50)
	,@DepositUsername	VARCHAR(50) OUTPUT
	,@AffId				INT = 0 OUTPUT
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS
/*  
	Created: 20230828@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Member - Active Member - Assign Affiliate - Check Affiliate to assign and insert into MemberInfo

	Revisions:
		- 20230828@Eddie: Initialize SP [RedmineID: #180516]
		
	Param's Explanation:
		- @DepositUsername: Deposit user need to assign affiliate
*/

BEGIN
	SET NOCOUNT ON
	
	SELECT @AffName = LTRIM(RTRIM(ISNULL(@AffName, '')))
	SELECT @DepositUsername = LTRIM(RTRIM(ISNULL(@DepositUsername, '')))
	
	-- Checking affiliate to assign
	SELECT @AffId = AffId 
	FROM dbo.AffInfo WITH (NOLOCK)
	WHERE UserName = @AffName
		AND Status = 'approved'
		AND IsClosed = 0
	
	SELECT @AffId = ISNULL(@AffId, 0)
	
	IF @AffId = 0
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
	
	-- Insert into MemberInfo
	SELECT TOP(1) c.custid		AS IBCCustID
		,@AffId 				AS AffID
		,'12Bet$' + dc.username	AS UserName
		,c.username 			AS IBCUserName
		,CURRENT_TIMESTAMP 		AS CreatedDate
		,0 						AS IsRemoved
		,dc.custid 				AS DepositCustID
		,'' 					AS FirstName
		,'' 					AS LastName
		,dc.currency 			AS Currency
		,c.recommend 			AS Recommend
		,'' 					AS Email
		,dc.creatdate 			AS RegisteredDate
		,dc.ClickId				AS ClickId
	INTO #depositMember
	FROM [DBDeposit].deposit_db.dbo.Deposit_Customer dc WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON c.username2 = CONVERT(VARCHAR(50), '12Bet$' + dc.Username)
	WHERE dc.username = @DepositUsername AND ISNULL(dc.AffiliateID, 0) = 0 
	
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
		)
	SELECT IBCCustID
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
	FROM #depositMember
	WHERE RegisteredDate IS NOT NULL
	
	-- Write log info
	DECLARE @LogData NVARCHAR(4000), @SPName VARCHAR(100), @CurrencyName NVARCHAR(50)
	
	SELECT @CurrencyName = dm.Currency  
	FROM dbo.Exchange_Current ec WITH (NOLOCK)
		INNER JOIN #depositMember dm ON dm.Currency = ec.ExchangeID

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	SELECT @LogData = 	CONVERT(NVARCHAR(MAX), 
						(	
							SELECT 
								IBCCustID 		AS '@IBCCustID'
								,AffID 			AS '@AffID'
								,UserName 		AS '@UserName'
								,IBCUserName 	AS '@IBCUserName'
								,DepositCustID 	AS '@DepositCustID'
								,IsRemoved 		AS '@IsRemoved'
								,FirstName 		AS '@FirstName'
								,LastName 		AS '@LastName'
								,@CurrencyName 	AS '@Currency'
								,Recommend 		AS '@Recommend'
								,Email 			AS '@Email'
								,RegisteredDate AS '@RegisteredDate'
								,ClickId 		AS '@ClickId'
								,CASE WHEN RegisteredDate IS NULL THEN 'Failed' ELSE 'Success' END AS '@Status'
							FROM #depositMember
							FOR XML PATH('row'), ROOT('root')
						))

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= @AffId
		,@SPName	= @SPName
		,@OldData	= ''
		,@NewData	= @LogData
	
	DROP TABLE #depositMember
END
GO