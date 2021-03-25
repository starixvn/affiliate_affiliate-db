/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbAdminNet,bodbDownlineNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Aff_LogAction_Sel]
	@IsShow BIT = 1
AS

/*
	Creator: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: UserLog - Log data
	
	Revisions:
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
*/

BEGIN
	SET NOCOUNT ON

	SELECT ActionId, Description AS ActionName
	FROM LogAction WITH(NOLOCK)
	WHERE IsShow = @IsShow OR @IsShow IS NULL
	ORDER BY Description ASC
END
GO