/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbAdminNet,bodbDownlineNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Aff_LogAction_Sel]
	@IsShow BIT = 1
   ,@ActionName VARCHAR(200) = NULL
AS

/*
	Creator: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: UserLog - Log data
	
	Revisions:
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
		- 20210219@Malcolm: get action name and actionIds [RedmineId : #149209]
		- 20231115@Eddie: Action Search function [RedmineID: #195391]
*/

BEGIN
	SET NOCOUNT ON

	;WITH CTE AS
	(
		SELECT Description
		FROM LogAction l WITH(NOLOCK)
		WHERE l.IsShow = @IsShow OR @IsShow IS NULL
		GROUP BY Description
	)
	SELECT e.Description AS ActionName, ActionIds
	FROM CTE e
	CROSS APPLY
	(
		SELECT STUFF(
						(
							SELECT ',' + CONVERT(VARCHAR(20), l.ActionId)
							FROM LogAction l WITH(NOLOCK)
							WHERE l.Description = e.Description 
								AND (l.IsShow = @IsShow OR @IsShow IS NULL)
							FOR XML PATH('')
						),1,1,''
					)
	) _(ActionIds)
	WHERE (@ActionName IS NULL OR e.Description LIKE '%' + CONVERT(NVARCHAR(4000), @ActionName) + '%')
	ORDER BY e.Description ASC

END
GO