/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet,bodbDownlineNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[Aff_CommGroupAssign]  
	@UserId int,  
	@GroupId int,  
	@AffIDList nvarchar(4000),      
	@IP varchar(20),  
	@Language varchar(5)= 'en-US',
	@ErrCode int = 0 OUTPUT,  
	@ErrMsg nvarchar(4000) = '' OUTPUT,  
	@RefNo bigint = null OUTPUT  
AS

/*  
	Created: 20090719@DungTong  
	Task: Assign a commission group (GroupID<1000) for multiple Affilites   
	DB: DBAFF
	Original:  
  
	Revisions:  
		- 20170627@Percy: Remove check permission [RedmineID: #73925]

	Parameters:  
		.@UserID: Administrator user id  
		.@GroupID: <1000  
		.@AfIDList: list of AffID separated by semi colon.Maximum of 200 AffIDs are assiged each time                  
		.@IP: IP of admin user                        
                            
*/

BEGIN
	SET NOCOUNT ON

	IF @ErrMsg <> ''
		RETURN

	IF @GroupID > 1000
		OR NOT EXISTS (SELECT 1 FROM dbo.CommGroup WITH(NOLOCK) WHERE GroupID = @GroupID AND IsDeleted = 0)
	BEGIN
		SELECT
			@ErrCode = 101,
			@ErrMsg = CASE @Language
						WHEN 'en-US' THEN 'Invalid Group. Please check.'
						WHEN 'zh-CN' THEN N'無效的群組.請確認.'
						WHEN 'zh-TW' THEN N'无效的群组请确认。'
						ELSE N'Invalid Group. Please check.'
					END
		RETURN
	END
  
	DECLARE @AffId INT, @NoAff INT, @CountCurrency INT

	BEGIN TRY
		SELECT @NoAff = COUNT(1)
		FROM dbo.AffInfo WITH(NOLOCK)
		WHERE AffID IN (SELECT CONVERT(INT, val) FROM dbo.strsplit(@AffIDList, ';'))
			AND Status = 'approved'

		IF @NoAff <> (SELECT COUNT(1) FROM dbo.strsplit(@AffIDList, ';'))
		BEGIN
			SELECT
				@ErrCode = 102,
				@ErrMsg = CASE @Language
							WHEN 'en-US' THEN 'Invalid Affiliate List. Please check.'
							WHEN 'zh-CN' THEN N'無效的工作夥伴名單.請確認.'
							WHEN 'zh-TW' THEN N'无效的工作伙伴名单，请确认。'
							ELSE N'Invalid Affiliate List. Please check.'
						END
			RETURN
		END

		SELECT @CountCurrency = COUNT(DISTINCT currency)
		FROM dbo.AffInfo WITH(NOLOCK)
		WHERE AffID IN (SELECT CONVERT(INT, val) FROM dbo.strsplit(@AffIDList, ';'))

		IF ISNULL(@CountCurrency, 0) > 1
		BEGIN
			SELECT
				@ErrCode = 104,
				@ErrMsg = CASE @Language
							WHEN 'en-US' THEN 'Currency of the group does not match with affiliate''s currency. Please check.'
							WHEN 'zh-CN' THEN N'貨幣的群組與工作夥伴的群組不相配.請確認.'
							WHEN 'zh-TW' THEN N'货币的群组与工作伙伴的群组不相配。请确认。'
							ELSE N'Currency of the group does not match with affiliate''s currency. Please check.'
						END
			RETURN
		END
	END TRY  
	BEGIN CATCH
		SELECT
			@ErrCode = 103,
			@ErrMsg = CASE @Language
						WHEN 'en-US' THEN 'Invalid Affiliate List. Please check.'
						WHEN 'zh-CN' THEN N'無效的工作夥伴名單.請確認.'
						WHEN 'zh-TW' THEN N'无效的工作伙伴名单，请确认。'
						ELSE N'Invalid Affiliate List. Please check.'
					END
		RETURN
	END CATCH  
  
	BEGIN TRANSACTION

	BEGIN TRY
		DELETE dbo.DeductionSetting WITH(ROWLOCK, UPDLOCK)
		WHERE GroupID IN (  
			SELECT GroupID FROM dbo.AffInfo WITH(NOLOCK)
			WHERE AffID IN (SELECT CONVERT(INT, val) FROM dbo.strsplit(@AffIDList, ';'))
				AND AffID = GroupID  
			)

		DELETE dbo.GroupSetting WITH(ROWLOCK, UPDLOCK)
		WHERE GroupID IN (  
			SELECT GroupID FROM dbo.AffInfo WITH(NOLOCK)
			WHERE AffID IN (SELECT CONVERT(INT, val) FROM dbo.strsplit(@AffIDList, ';'))
				AND AffID = GroupID  
			)

		DELETE dbo.CommGroup WITH(ROWLOCK, UPDLOCK)
		WHERE GroupID IN (  
			SELECT GroupID FROM dbo.AffInfo WITH(NOLOCK)
			WHERE AffID IN (SELECT CONVERT(INT, val) FROM dbo.strsplit(@AffIDList, ';'))
				AND AffID = GroupID  
			)

		UPDATE dbo.AffInfo WITH(ROWLOCK, UPDLOCK)
		SET GroupID = @GroupID
		WHERE AffID IN (SELECT CONVERT(INT, val) FROM dbo.strsplit(@AffIDList, ';'))
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		
		SELECT
			@ErrCode = 105,
			@ErrMsg = CASE @Language
						WHEN 'en-US' THEN 'There was an error when updating data.Please try again!'
						WHEN 'zh-CN' THEN N'當在更新資料時,會有錯誤.請重新再試一次!'
						WHEN 'zh-TW' THEN N'当在更新资料时，会有错误，请重新再试一次！'
						ELSE N'There was an error when updating data.Please try again!'
					END
		RETURN
	END CATCH

	COMMIT TRANSACTION

	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000)

	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = N'Assign a common commission group.GroupID=' + dbo.Aff_ToString(@GroupID) + '\n AffIDList=' + dbo.Aff_ToString(@AffIDList)

	IF (SELECT COUNT(1) FROM dbo.strsplit(@AffIDList, ';')) = 1
		SELECT @AffID = CAST(@AffIDList AS INT)
	ELSE
		SELECT @AffID = 0     

	EXEC [dbo].[Aff_WriteLog]  
		@Creator = @UserId,   
		@AffID = @AffID,  
		@Typename = 'CommissionGroup',   
		@SPName = @SPName ,  
		@IP = @IP,  
		@RefNo = @RefNo OUTPUT,   
		@Details = @Detail
END
GO