/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_CountryDel]
    @Updatedby	INT,
    @IDList		NVARCHAR(MAX),
    @IP			NVARCHAR(15) = '',    
    @ErrCode	INT = 0 OUTPUT,
    @ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20130122@Joseph
	Task:
	DB: DBAFF
	Original:

	Revisions:
		- 20151221@Francis: Support SSO
		- 20170627@Percy: Remove check permission [RedmineID: #73925]

	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	DELETE [dbo].[Country] WITH (ROWLOCK, UPDLOCK)
	WHERE CountryID IN (SELECT val FROM dbo.strsplit(@IDList, ','))

	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
		RETURN
	END
	
	-- Write log
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000) 
	
	SELECT @SPName = OBJECT_NAME(@@PROCID), @Detail = 'Delete Country. IDList=' + ISNULL(@IDList, '0')

	EXEC [dbo].[Aff_WriteLog] 
		@Creator = @Updatedby,
		@AffID = @Updatedby,
		@Typename = 'Country', -- refer to table LogType
		@SPName = @SPName,
		@Details = @Detail,
		@IP = @IP
END
GO