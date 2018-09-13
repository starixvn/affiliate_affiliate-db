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
	SELECT IBCCustId AS CustId
	FROM Affiliate_12BET.dbo.MemberInfo WITH (NOLOCK)
	WHERE AffId IN (927841, 92040664, 92040667)
GO