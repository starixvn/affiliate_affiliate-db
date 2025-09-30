/*<info serverAlias="DBEXT-bodb02" executers="bodbAdminNet,bodbDownlineNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Aff_DummyAccID]
	@Username VARCHAR(50) = '',
	@CustId INT = 0 OUTPUT
AS

/*
	Created: 20130315@Peter
	Task: Get Player CustId by Player Username
	DB: DBEXT.bodb02

	Revisions:
		- 20180207@Percy: Add default value [RedmineID: #90545]
*/

BEGIN
	SELECT @CustId = CustId
	FROM dbo.custInfo WITH (NOLOCK)
	WHERE username = @Username
END
GO