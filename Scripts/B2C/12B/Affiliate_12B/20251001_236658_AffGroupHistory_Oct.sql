/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20251001@Lewis
    DB: DBAFF12B-Affiliate_12B
    Task: AffGroupHistory October
    RedmineID: #236658
    
*/		
USE Affiliate_12B

			DECLARE @NextMonthDate DATETIME = '2025-10-31'
			INSERT INTO dbo.AffGroupHistory (AffId,MonthDate,GroupId,ParentAffId,AllParentAffId,FromDate,ToDate)
			SELECT AffId,@NextMonthDate,GroupId,ParentAffId,AllParentAffId,DATEADD(MONTH, DATEDIFF(MONTH, 0, @NextMonthDate), 0),'9999-12-31'
			FROM dbo.AffInfo WITH (NOLOCK)
			WHERE ISNULL(GroupId, 0) > 0 and affid not in (92044139,92044140,92044141)
