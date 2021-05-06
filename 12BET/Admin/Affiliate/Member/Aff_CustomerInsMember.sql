/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_CustomerInsMember] 
	@IBCCustID 			INT
	,@AffID 			INT
	,@Username 			VARCHAR(30)
	,@IBCUsername 		VARCHAR(30)
	,@DepositCustID 	INT
	,@FirstName 		NVARCHAR(50)
	,@LastName 			NVARCHAR(50)
	,@Currency 			INT
	,@Recommend 		INT
	,@Email 			NVARCHAR(50)
AS
/*  
Created: 20090724@VietHoang
Task : Add new member when customer is first deposit
DB: DB052.Affiliate_12BET
Revisions:    
	- 20120110@Johnny: Update click Status when member deposit money at 1st time
	- 20120409@Johnny: Make local test version is the same as live version
	- 20140708@Bobby: Apply MemberClickDetail info
	- 20140801@Bobby: Update ins MemberClickDetail
	- 20141013@Bobby: Enhance checking Deposit member by updating [d.AffiliateID = @AffId] 
	- 20151013@Bobby: Check for validation of member affiliate
	- 20210416@Malcolm: Change format when writing logs [RedmineId : #152449]
	- 20210423@Malcolm: Get currency name[RedmineId : #152449]
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @RegisteredDate DATETIME
		,@ClickId 			BIGINT
		,@CurrencyName		NVARCHAR(50)
	
	SELECT @AffId			= ISNULL(@AffId, 0)
		, @IBCCustID		= ISNULL(@IBCCustID, 0)
	
	IF(@AffId <= 0 	OR  @IBCCustID <=0 ) RETURN;
	
	SELECT TOP(1) @IBCCustID AS IBCCustID
		,@AffID AS AffID
		,@UserName AS UserName
		,@IBCUserName AS IBCUserName
		,CURRENT_TIMESTAMP AS CreatedDate
		,0 AS IsRemoved
		,@DepositCustID AS DepositCustID
		,@FirstName AS FirstName
		,@LastName AS LastName
		,@Currency AS Currency
		,@Recommend AS Recommend
		,@Email AS Email
		,d.creatdate AS RegisteredDate
		,d.ClickId
		,ISNULL(c.DomainReferrer, 'none') AS DomainReferrer
		,ISNULL(c.RedirectURL, 'none') AS URLRedirect
		,ISNULL(c.SportCode, 'none') AS SportCode
		,ISNULL(c.LanguageCode, 'none') AS LanguageCode
		,ISNULL(c.URLReferrer, 'none') AS URLReferrer
		,ISNULL(c.DeviceType, 0) AS DeviceType
	INTO #depositMember
	FROM [DBDeposit].deposit_db.dbo.Deposit_Customer d WITH (NOLOCK)
		LEFT JOIN dbo.ClickStatistics1 c WITH (NOLOCK)
		ON d.ClickID = c.ClickID
	WHERE d.custid = @DepositCustID
		AND d.AffiliateID = @AffId
	
	-- MemberInfo
	INSERT INTO MemberInfo (
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
	FROM #depositMember d
	WHERE RegisteredDate IS NOT NULL

	DELETE d
	FROM #depositMember d
	WHERE d.ClickID IS NULL OR d.ClickID = 0
	
	-- MemberClickDetail
	MERGE INTO [dbo].[MemberClickDetail] AS t
	USING #depositMember AS s 
		ON t.DepositCustID = s.DepositCustID
			AND s.ClickID > 0
	WHEN MATCHED THEN
		UPDATE 
		SET IBCCustID = s.IBCCustID
	WHEN NOT MATCHED BY TARGET THEN
		INSERT ([DepositCustID]
			,[ClickId]
			,[DomainReferrer]
			,[LanguageCode]
			,[SportCode]
			,[URLRedirect]
			,[URLReferrer]
			,[DeviceType]
			,[AffID]
			,[CreatedDate]
			,[IBCCustID]
			)
		VALUES (s.[DepositCustID]
			,s.[ClickId]
			,s.[DomainReferrer]
			,s.[LanguageCode]
			,s.[SportCode]
			,s.[URLRedirect]
			,s.[URLReferrer]
			,s.[DeviceType]
			,s.[AffID]
			,s.[RegisteredDate]
			,s.[IBCCustID]
		);
	
	-- get info to write log
	SELECT @RegisteredDate = RegisteredDate
		,@ClickId = ClickId
	FROM #depositMember
	
	DROP TABLE #depositMember

	/*
	- Write log info
	*/
	SELECT @CurrencyName = currency  FROM dbo.Exchange_Current WITH(NOLOCK) WHERE ExchangeId = @Currency

	DECLARE @LogData NVARCHAR(4000)
		,@SPName VARCHAR(100)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	SELECT @LogData = 	CONVERT(NVARCHAR(MAX), 
						(	
							SELECT 
								@IbcCustID AS '@IBCCustID'
								,@UserName AS '@UserName'
								,@IBCUserName AS '@IBCUserName'
								,@DepositCustID AS '@DepositCustID'
								,@FirstName AS '@FirstName'
								,@LastName AS '@LastName'
								,@CurrencyName AS '@Currency'
								,@Recommend AS '@Recommend'
								,@Email AS '@Email'
								,@RegisteredDate AS '@RegisteredDate'
								,@ClickId AS '@ClickId'
								,CASE WHEN @RegisteredDate IS NULL THEN 'Failed' ELSE 'Success' END AS '@Status'
							FOR XML PATH('row'), ROOT('root')
						))

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @AffID,
		@AffId		= @AffID,
		@SPName		= @SPName,
		@OldData	= '',
		@NewData	= @LogData,
		@IP			= '127.0.0.1',
		@Language	= 'en-US'
END
GO


