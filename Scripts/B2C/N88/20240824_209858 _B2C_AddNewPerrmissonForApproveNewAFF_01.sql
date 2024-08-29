/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G,DBAFFYASHBET-Affiliate_YashBet"></info>*/
/*
	Created: 20240828@Sally
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G,DBAFFYASHBET-Affiliate_YashBet
	Task: B2C Affiliate - Add new permission for approve new affiliate [RedmineID: #209858]
		- Add new permission
*/

INSERT INTO dbo.AffFunctionInfo (FuncName, FuncNote, FuncDesc, FuncRender, CreateDate, ModifyDate, DisplayOrder, Creator, ParentId, FileNames)
	VALUES (N'[EditAffiliateStatus]', N'', N'Edit Affiliate Status', 3, SYSDATETIME(), SYSDATETIME(), 1, 35915769, NULL, ''),
			(N'[EditAffiliateDetails]', N'', N'Customer - Edit Affiliate Details', 3, SYSDATETIME(), SYSDATETIME(), 1, 35915769, NULL, '');
;
