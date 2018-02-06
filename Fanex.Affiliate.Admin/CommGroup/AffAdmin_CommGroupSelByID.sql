/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_CommGroupSelByID]		
	@LicenseeID		INT,
	@GroupID		INT,
	@UserId			INT,
	@UserCurrencies	VARCHAR(MAX) = ''
AS

/*
Created: 20131114@Joseph
Task : Search a Commission Group
DB: DB052.Affiliate_MYM
Original:
Revisions:	
	- 20131121@Joseph: filter by TestLevel
	- 20151118@Victor: Implement SSO from Internal Admin to Affiliate Admin site
	- 20180205@Percy: Replace @UserId, @LicenseeId to @UserCurrencies to get list of currencies [RedmineID: #90545]
*/

BEGIN
	SET NOCOUNT ON

	SELECT AffCurrencyID AS CurrencyID INTO #tmpCurrency 
	FROM dbo.AffAdmin_f_UserCurrency_Select(@UserID, @LicenseeID)

	DECLARE @IsITAdmin BIT
	SELECT @IsITAdmin = dbo.AffAdmin_f_IsITAdmin(@UserID, @LicenseeID)

	SELECT cg.GroupID,GroupName,Description,isnull(i.username,'System') as Creator,
		cg.CreatedDate,e.CurrencyID,e.CurrencyCode as Currency,QualifiedAmount,
		Count(ai.AffID) as NoOfAffiliate
	from CommGroup cg with (nolock)
		inner join dbo.Currency e on cg.Currency = e.CurrencyID			  
		left join dbo.AffAdmin_f_AdminUserInfo_Select('', @LicenseeID) i on i.UserID=cg.Creator
		left join AffInfo ai with (nolock) on ai.GroupID = cg.GroupID
	where 			   
		cg.GroupID = @GroupID
		and (@IsITAdmin = 1 or ai.TestLevel in (0,1))
		and (cg.Currency = 0 or (cg.Currency in (select convert(int, val) from dbo.strSplit(@UserCurrencies, ','))))
	group by cg.GroupID, cg.GroupName, cg.Description,cg.CreatedDate,cg.QualifiedAmount,
		i.Username,e.CurrencyID,e.CurrencyCode
END
GO