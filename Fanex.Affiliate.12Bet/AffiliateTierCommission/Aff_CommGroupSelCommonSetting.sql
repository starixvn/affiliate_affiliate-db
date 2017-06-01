USE [Affiliate_12BET]
GO

ALTER PROCEDURE [Aff_CommGroupSelCommonSetting]	
AS

/*
	Created: 20090719@DungTong
	Task: Get Common Setting for Adding or Editing new Group
	DB: DB052.Affiliate_12Bet
	Original:

	Revisions:
		- 20170601@Percy: Add new column: isTest [RedmineID: #77521]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @isTest BIT = 0

	SELECT  @isTest = dbo.f_Aff_CheckSPVersion(@@PROCID)

	Select SportID, SportName
	from SportType (nolock)
	
	Select DTypeID, SportID,DTypeName, DTypeDesc, DeductedPercentage 
	from DeductionType (nolock)
	where IsTest <= @isTest
	
END
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelCommonSetting] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelCommonSetting] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelCommonSetting] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CommGroupSelCommonSetting] TO [vnteam]
