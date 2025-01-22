/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_WriteLog]
	@Creator	INT
	,@AffId		INT = 0
	,@TypeName	VARCHAR(50) = ''
	,@RefNo		BIGINT = 0 OUTPUT
	,@SPName	VARCHAR(50)
	,@IP		VARCHAR(50) = ''
	,@Details	NVARCHAR(4000)
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: UserLog - Log data
	
	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

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