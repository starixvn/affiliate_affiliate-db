/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_User_UserInfoUpd]
	@AffId				INT
	,@UserId			INT
	,@Phone				VARCHAR(50) 	= NULL
	,@ContactApps		NVARCHAR(2000) 	= NULL
	,@SiteURL			VARCHAR(100) 	= NULL
	,@MoreSiteURLs		VARCHAR(1000) 	= NULL
	,@NoSiteDesc		NVARCHAR(1000) 	= NULL
	,@Player_Username	NVARCHAR(50) 	= NULL
	,@TargetCountryCode	VARCHAR(2)		= NULL
	,@Language			NVARCHAR(20) 	= 'en-US'
	,@IP				VARCHAR(50)
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			NVARCHAR(2000) 	= '' OUTPUT
AS  

/*
	Creator: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: User - My Account - Update user info
	
	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
		- 20231027@Eddie: Update TargetCountry [RedmineId : #181590]
		- 20240821@Eddie: Change metadata "bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" [RedmineID: #209409]
*/

BEGIN
	SET NOCOUNT ON

	-- Check if change player_username
	IF EXISTS (SELECT 1 FROM dbo.AffDetail WITH (NOLOCK) WHERE AffID = @AffId AND Player_Username <> @Player_Username)
	BEGIN
		IF EXISTS (SELECT 1 FROM dbo.AffPayout WITH (NOLOCK) WHERE AffID = @AffId AND Status = 'Pending')
		BEGIN
			-- Oops, this account is having 1 pending pay out request, please update this transaction first!
			SELECT @ErrCode = 1001, @ErrMsg = dbo.Aff_f_GetMessageById(301, @Language)

			RETURN
		END
	END

	DECLARE @Player_IBCCustId INT
	SELECT  @Player_IBCCustId = custid
	FROM DBEXT.bodb02.dbo.Customer WITH (NOLOCK)
	WHERE username2 = '12BET$' + @Player_Username

	DECLARE @UpdatedData TABLE
	(
		-- del
		Phone_Del				VARCHAR(50)
		,ContactApps_Del		NVARCHAR(2000)
		,SiteURL_Del			VARCHAR(100)
		,MoreSiteURLs_Del		VARCHAR(1000)
		,NoSiteDesc_Del			NVARCHAR(1000)
		,PreferredPayment_Del	VARCHAR(20)
		,Player_IBCCustId_Del	INT
		,Player_Username_Del	NVARCHAR(100)
		,TargetCountryCode_Del	VARCHAR(2)
		-- insert
		,Phone_Ins				NVARCHAR(50)
		,ContactApps_Ins		NVARCHAR(2000)
		,SiteURL_Ins			VARCHAR(100)
		,MoreSiteURLs_Ins		VARCHAR(1000)
		,NoSiteDesc_Ins			NVARCHAR(1000)
		,PreferredPayment_Ins	VARCHAR(20)
		,Player_IBCCustId_Ins	INT
		,Player_Username_Ins	NVARCHAR(100)
		,TargetCountryCode_Ins	VARCHAR(2)
	)

	BEGIN TRY
		UPDATE dbo.AffDetail WITH (ROWLOCK, UPDLOCK)
		SET Phone				= ISNULL(@Phone, Phone)
			,ContactApps		= ISNULL(@ContactApps, ContactApps)
			,SiteURL			= ISNULL(@SiteURL, SiteURL)
			,MoreSiteURLs		= ISNULL(@MoreSiteURLs, MoreSiteURLs)
			,NoSiteDesc			= ISNULL(@NoSiteDesc, NoSiteDesc)
			,PreferredPayment	= 'Player' -- default user update
			,Player_IBCCustId	= ISNULL(@Player_IBCCustId, Player_IBCCustId)
			,Player_Username	= ISNULL(@Player_Username, Player_Username)
			,TargetCountryCode	= ISNULL(@TargetCountryCode, TargetCountryCode)
		OUTPUT
			DELETED.Phone
			,DELETED.ContactApps
			,DELETED.SiteURL
			,DELETED.MoreSiteURLs
			,DELETED.NoSiteDesc
			,DELETED.PreferredPayment
			,DELETED.Player_IBCCustId
			,DELETED.Player_Username
			,DELETED.TargetCountryCode
			,INSERTED.Phone
			,INSERTED.ContactApps
			,INSERTED.SiteURL
			,INSERTED.MoreSiteURLs
			,INSERTED.NoSiteDesc
			,INSERTED.PreferredPayment
			,INSERTED.Player_IBCCustId
			,INSERTED.Player_Username
			,INSERTED.TargetCountryCode
		INTO @UpdatedData
		(
			Phone_Del
			,ContactApps_Del
			,SiteURL_Del
			,MoreSiteURLs_Del
			,NoSiteDesc_Del
			,PreferredPayment_Del
			,Player_IBCCustId_Del
			,Player_Username_Del
			,TargetCountryCode_Del
			,Phone_Ins
			,ContactApps_Ins
			,SiteURL_Ins
			,MoreSiteURLs_Ins
			,NoSiteDesc_Ins
			,PreferredPayment_Ins
			,Player_IBCCustId_Ins
			,Player_Username_Ins
			,TargetCountryCode_Ins
		)
		WHERE AffID = @AffId
	END TRY
	BEGIN CATCH
		-- Update process is unsuccessful. Please try again!
		SELECT @ErrCode = 1006, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)

		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)

	SELECT  @OldData = CONVERT(NVARCHAR(MAX),
					   (
							SELECT DISTINCT a.Phone_Del 	AS '@Phone'
									,a.ContactApps_Del 		AS '@ContactApps'
									,a.SiteURL_Del 			AS '@SiteURL'
									,a.MoreSiteURLs_Del 	AS '@MoreSiteURLs'
									,a.NoSiteDesc_Del 		AS '@NoSiteDesc'
									,a.PreferredPayment_Del AS '@PreferredPayment'
									,a.Player_IBCCustId_Del AS '@Player_IBCCustId'
									,a.Player_Username_Del 	AS '@Player_Username'
									,tc.CountryName 		AS '@TargetCountry'
							FROM @UpdatedData a
								INNER JOIN TargetCountry tc WITH (NOLOCK) ON a.TargetCountryCode_Del = tc.CountryCode
							FOR XML PATH('row'), ROOT('root')
					   ))
	
	SELECT  @NewData = CONVERT(NVARCHAR(MAX),
	                   (
							SELECT DISTINCT a.Phone_Ins 	AS '@Phone'
									,a.ContactApps_Ins 		AS '@ContactApps'
									,a.SiteURL_Ins 			AS '@SiteURL'
									,a.MoreSiteURLs_Ins 	AS '@MoreSiteURLs'
									,a.NoSiteDesc_Ins 		AS '@NoSiteDesc'
									,a.PreferredPayment_Ins AS '@PreferredPayment'
									,a.Player_IBCCustId_Ins AS '@Player_IBCCustId'
									,a.Player_Username_Ins 	AS '@Player_Username'
									,tc.CountryName 		AS '@TargetCountry'
							FROM @UpdatedData a
								INNER JOIN TargetCountry tc WITH (NOLOCK) ON a.TargetCountryCode_Ins = tc.CountryCode
							FOR XML PATH('row'), ROOT('root')
					   ))
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= @AffId
		,@SPName	= @SPName
		,@OldData	= @OldData
		,@NewData	= @NewData
		,@IP		= @IP
		,@Language	= @Language
END
GO