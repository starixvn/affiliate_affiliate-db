/*<info serverAlias="DBEXT-bodb02" selecters="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
USE [bodb02]
GO

ALTER FUNCTION [dbo].[Aff_f_GetTestingCustId]
(
)
RETURNS TABLE
AS

/*
	Created: 20180601@Percy
	DB: DBEXT.bodb02
	Task: Job - Get testing custid

	Revisions:
		- 20180601@Percy: Initialize function [RedmineID: #87923]
*/

RETURN
	SELECT CustId
	FROM
	(
		VALUES
			-- AFF
			(32048676),(32048678),(32048681),
			(32152690),(32152692),(32152695),
			(32152696),(32152698),(32152699)
	) AS t (CustId)
GO