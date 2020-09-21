/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet,bodbAdminNet,bodbDownlineNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_WriteLog]
	@Creator	INT
	,@AffId		INT = 0
	,@TypeName	VARCHAR(50) = ''
	,@RefNo		BIGINT = 0 OUTPUT
	,@SPName	VARCHAR(50)
	,@IP		VARCHAR(20) = ''
	,@Details	NVARCHAR(4000)
AS

/*
	Creator: 20200220@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: UserLog - Log data
	
	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@SPName		= @SPName
		,@UserId	= @Creator
		,@AffId		= @AffId
		,@NewData	= @Details
		,@IP		= @IP
		,@IsWebCall	= 1
END
GO