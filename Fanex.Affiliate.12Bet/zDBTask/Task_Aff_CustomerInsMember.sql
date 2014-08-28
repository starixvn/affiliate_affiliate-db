ALTER PROCEDURE [dbo].[Task_Aff_CustomerInsMember] 
	@AffId INT	= NULL
	,@CreatedDate SMALLDATETIME = NULL
AS
/*  
Created: 20120704@Johnny
Task : Task Add members are missed in Deposit DB into MemberInfo table
DB: DB052.Affiliate_12BET
Revisions:    
	- 20140708@Bobby: Apply MemberClickDetail info
	- 20140801@Bobby: Update ins MemberClickDetail

Params Explaination:
	-@CreatedDate: NULL = [current_timestamp]
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @CreateToDate SMALLDATETIME;

	-- run to import yesterday missing members  
	SELECT @CreatedDate = ISNULL(@CreatedDate, CAST(DATEADD(DD, -1, CURRENT_TIMESTAMP) AS DATE))
		, @CreateToDate = DATEADD(DD, 1, @CreatedDate)
	
	-- Select member from deposit customer
	SELECT d.IBCCustID
		,AffiliateId AS AffId
		,d.UserName
		,d.IBCUserName
		,CURRENT_TIMESTAMP AS CreatedDate
		,d.CustId AS DepositCustID
		,d.FirstName
		,d.LastName
		,d.Currency
		,d.IBCAgentID AS Recommend
		,d.Email
		,d.creatdate AS RegisteredDate
		,0 IsRemove
		,d.ClickId
		,ISNULL(c.DomainReferrer, 'none') AS DomainReferrer
		,c.RedirectURL AS URLRedirect
		,c.SportCode
		,c.LanguageCode
		,c.URLReferrer
		,ISNULL(c.DeviceType, 0) DeviceType
	INTO #depositMember
	FROM [DBDeposit].deposit_db.dbo.Deposit_Customer d WITH (NOLOCK)
		LEFT JOIN dbo.ClickStatistics1 c WITH (NOLOCK)
		ON d.ClickID = c.ClickID 
		LEFT JOIN dbo.MemberInfo m WITH (NOLOCK)
		ON d.IBCCustID = m.IBCCustID AND d.AffiliateID = m.AffID
	WHERE (CreatDate >= @CreatedDate AND creatdate < @CreateToDate)
		AND AffiliateId > 0
		AND (
			@Affid IS NULL
			OR AffiliateId = @Affid
			)
		AND ActStatus IN (2, 9)
		AND d.IBCCustID IS NOT NULL
		AND m.IBCCustID IS NULL

	/*
	Check to update/insert MemberInfo & MemberClickDetail
	*/
	IF EXISTS(SELECT TOP 1 1 FROM #depositMember)
	BEGIN
		-- MemberInfo
		INSERT INTO dbo.MemberInfo (
			[IBCCustID]
			,[AffID]
			,[UserName]
			,[IBCUserName]
			,[CreatedDate]
			,[RegisteredDate]
			,[IsRemoved]
			,[DepositCustID]
			,[FirstName]
			,[LastName]
			,[Currency]
			,[Email]
			,[Recommend]
			,[ClickId]
		)
		SELECT src.IBCCustID
			,src.AffID
			,'12bet$' + src.UserName
			,src.IBCUserName
			,src.CreatedDate
			,src.RegisteredDate
			,src.IsRemove
			,src.DepositCustID
			,src.FirstName
			,src.LastName
			,src.Currency
			,src.Email
			,src.Recommend
			,src.ClickId
		FROM #depositMember src

		--Ins MemberClickDetail
		DELETE #depositMember
		WHERE ClickId IS NULL OR ClickId = 0
		
		MERGE INTO [dbo].[MemberClickDetail] AS t
		USING #depositMember AS s 
			ON t.DepositCustID = s.DepositCustID
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
				)
		;
	END

	DROP TABLE #depositMember;
	RETURN;

END
GO

GRANT EXECUTE ON [dbo].[Task_Aff_CustomerInsMember] TO [Dot_Member]
GO

GRANT VIEW DEFINITION ON [dbo].[Task_Aff_CustomerInsMember] TO [vnteam]
GO
