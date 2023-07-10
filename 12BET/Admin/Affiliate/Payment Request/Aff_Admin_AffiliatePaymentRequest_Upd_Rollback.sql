/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_AffiliatePaymentRequest_Upd_Rollback]
	@DetailXML 	XML
	,@ErrCode	INT 			= 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000) 	= '' OUTPUT
AS

/*
	Created: 20230621@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Affiliate - Payment Request - Rollback Update payment request by TransID

	Revisions:
		- 20230621@Eddie: Initialize SP [RedmineID: #189465]
*/

BEGIN
	SET NOCOUNT ON

	IF @ErrCode = 0 OR @DetailXML  IS NULL
	BEGIN
		SELECT @ErrCode = 106, @ErrMsg = 'Please check ErrCode or DetailXML try again!'
		RETURN
	END
	
	DECLARE @Status	VARCHAR(50)
	
	SELECT @Status = t.c.value('@NewStatus', 'VARCHAR(50)')
	FROM @DetailXML.nodes('root/row') AS t(c)
	OPTION (OPTIMIZE FOR (@DetailXML = NULL))
	
	DECLARE @Tmp TABLE (AffID INT, RefID BIGINT, TransID BIGINT, Status NVARCHAR(50), CompletedDate DATETIME, AdminDesc NVARCHAR(300), AffDesc NVARCHAR(300), Creator INT, TypeId TINYINT)

	INSERT INTO @Tmp(AffID, RefID, TransID, Status, CompletedDate, AdminDesc, AffDesc, Creator, TypeId)
	SELECT t.c.value('@AffID', 'INT')
		  ,t.c.value('@RefID', 'BIGINT')
		  ,t.c.value('@TransID', 'BIGINT')
		  ,t.c.value('@OldStatus', 'NVARCHAR(50)')
		  ,t.c.value('@OldCompletedDate', 'DATETIME')
		  ,t.c.value('@OldAdminDesc', 'NVARCHAR(300)')
		  ,t.c.value('@OldAffDesc', 'NVARCHAR(300)')
		  ,t.c.value('@OldCreator', 'INT')
		  ,t.c.value('@OldTypeId', 'TINYINT')
	FROM @DetailXML.nodes('root/row') AS t(c)
	OPTION (OPTIMIZE FOR (@DetailXML = NULL))

	IF @Status = 'Approved'
	BEGIN
	
		BEGIN TRY
			UPDATE p WITH (ROWLOCK)
			SET p.Status			= t.Status
				,p.CompletedDate 	= t.CompletedDate
				,p.AdminDesc		= t.AdminDesc
				,p.AffDesc			= t.AffDesc
			FROM dbo.AffPayout p
				CROSS JOIN @Tmp t 
			WHERE p.AffID = t.AffID AND p.RefID = t.RefID AND t.TypeId = 1
	
			UPDATE at WITH(ROWLOCK)
			SET at.Status			= t.Status
				,at.CompletedDate	= t.CompletedDate
				,at.Creator			= t.Creator
			FROM dbo.AffTrans at
				CROSS JOIN @Tmp t 
			WHERE at.TransID = t.TransID AND t.TypeId = 2
			
			SELECT @ErrCode = 0, @ErrMsg = ''
		END TRY
		BEGIN CATCH
			SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
		END CATCH 
		
	END
	ELSE 
	BEGIN
		SELECT @ErrCode = 107, @ErrMsg = 'Update rollback process is unsuccessful. Please try again!'
	END
END
GO