/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_OfferAffiliate_Ins]
	 @UserId		INT
	 ,@AffNameList	NVARCHAR(MAX) 
	 ,@PageId		INT
	 ,@IP			VARCHAR(50) = ''
	 ,@ErrCode		INT = 0 OUTPUT
	 ,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20211213@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Offer Affiliate - Assign

	Revisions:
		- 20211213@Malcolm: Initialize SP [RedmineID: #165915]
		- 20231122@Eddie: Change Datatype of IP [RedmineId : #181797]
		- 20240820@Eddie: STRING_SPLIT replace for strSplit function [RedmineID: #209409]

	Param's Explanation:

*/

BEGIN

	SET NOCOUNT ON
	DECLARE @TypeId INT, @Naff INT, @SPName VARCHAR(200), @NewData NVARCHAR(MAX), @ID INT = 1, @FileName NVARCHAR(200), @AffId INT

	EXEC dbo.Aff_CheckPermission 
		@CustId = @UserId
		,@FuncName = '[Media]'
		,@ErrCode = @ErrCode OUTPUT
		,@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	IF NOT EXISTS (SELECT 1 FROM dbo.OfferPage WITH(NOLOCK) WHERE PageId = @PageId)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'The offer page does not exist, please refresh the page and try again.'
		RETURN
	END

	SELECT @FileName = FileName FROM dbo.OfferPage WITH(NOLOCK) WHERE PageId = @PageId

	CREATE TABLE #tmpAff (ID INT IDENTITY(1, 1), AffId INT, Username NVARCHAR(40), IsAsian BIT)
	INSERT INTO #tmpAff (Username)
	SELECT DISTINCT RTRIM(LTRIM(s.value)) AS Username
	FROM STRING_SPLIT (@AffNameList, ',') s
	WHERE s.value <> ''
		
	SELECT @Naff = COUNT(1) FROM #tmpAff 

	IF @Naff > 500
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'The function can only copy up to 500 accounts per request.'
		RETURN
	END
	
	SELECT @TypeId = TypeId FROM AffType WITH(NOLOCK) WHERE Name = 'Asian'

	UPDATE t
		SET t.AffId = n.AffID, t.IsAsian = CASE WHEN ISNULL(n.AffType, 0) = @TypeId THEN 1 ELSE 0 END
	FROM #tmpAff t
	CROSS APPLY (
		SELECT ai.AffId, ai.AffType
		FROM dbo.AffInfo ai WITH(NOLOCK)
			INNER JOIN dbo.AffDetail d WITH(NOLOCK) ON d.AffID = ai.AffID
			INNER JOIN dbo.UserMarket m WITH(NOLOCK) ON m.MarketId = d.PreferredLanguage
		WHERE ai.UserName = t.Username AND m.CustId = @UserId
	) n

	IF EXISTS (SELECT 1 FROM #tmpAff WHERE AffId IS NULL)
	BEGIN
		SELECT @ErrCode = 103, 
			   @ErrMsg = '- The following affiliates do not exist: ' +
			             STUFF
						 (
							(
								SELECT ',' + t.Username 
								FROM #tmpAff t  
								WHERE t.AffId IS NULL 
								FOR XML PATH('')
							), 1, 1, ''
						 ) + ' <br /> '
	END

	IF EXISTS (SELECT 1 FROM #tmpAff WHERE IsAsian = 0)
	BEGIN
		SELECT @ErrCode = 103,
			   @ErrMsg = @ErrMsg + '- The following affiliates are not Asian affiliates: ' + 
						  STUFF
						  (
							(
								SELECT ',' + t.Username 
								FROM #tmpAff t  
								WHERE t.IsAsian = 0 
								FOR XML PATH('')
							), 1, 1, ''
						  ) + ' <br /> '
	END

	IF EXISTS (SELECT 1 FROM #tmpAff t INNER JOIN dbo.OfferAffiliate ea WITH(NOLOCK) ON ea.AffId = t.AffId)
	BEGIN
		SELECT @ErrCode = 103,
			   @ErrMsg = @ErrMsg + '- The following affiliates have already had offer page assigned: ' +
				          STUFF
						  (
							(
								SELECT ',' + t.Username 
								FROM #tmpAff t  
									INNER JOIN dbo.OfferAffiliate ea WITH(NOLOCK) ON ea.AffId = t.AffId
								FOR XML PATH('')
							), 1, 1, ''
						  ) + ' <br /> '
	END

	IF @ErrCode <> 0
		RETURN

	BEGIN TRY
		INSERT INTO dbo.OfferAffiliate (PageId, AffId)
		SELECT @PageId, AffId
		FROM #tmpAff
	END TRY
	BEGIN CATCH 
		SELECT @ErrCode = 104, @ErrMsg = 'Error occurs. Insert unsucessfully.'
		RETURN
	END CATCH

	--Write Log
	SELECT @SPName = OBJECT_NAME(@@PROCID)

	WHILE 1 = 1
	BEGIN
		IF NOT EXISTS (SELECT TOP 1 1 FROM #tmpAff WHERE ID = @ID)
			RETURN

		SELECT @AffId = AffId FROM #tmpAff WHERE ID = @ID

		SELECT @NewData = CONVERT(NVARCHAR(MAX), 
						  (
							SELECT t.AffId		AS '@AffId', 
								   t.Username	AS '@AffName',
								   @PageId		AS '@PageId', 
								   @FileName	AS '@FileName'
							FOR XML PATH('row'), ROOT('root')
						  ))
			  ,@AffId = t.AffId
		FROM #tmpAff t
        WHERE t.ID = @ID

		EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
			@UserId = @UserId
			,@SPName = @SPName
			,@AffId = @AffId
			,@NewData = @NewData
			,@IP = @IP
			,@Language = 'en-US'

		SET @ID += 1
	END

	DROP TABLE #tmpAff
END
GO
