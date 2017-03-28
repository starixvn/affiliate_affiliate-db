ALTER PROCEDURE [dbo].[Aff_AffiliateSelTrackingCode]
  @AffID int  
  as
  /*  
Created: 20090504@Peter
Task : Get List of Tracking Code for Affiliate
DB: DB052.Affiliate_12BET
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 

Param's Explanation:
.@AffID: id of affiliate in the system,
• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert unsuccessful.

• @ErrMsg: Error description.
*/
SET NOCOUNT ON  
begin
   select TrackingCode
   from TrackingCode (nolock)
   where AffID =  @AffID
end
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelTrackingCode] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelTrackingCode] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelTrackingCode] TO [bodbDownlineNetView]
GO  
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSelTrackingCode] TO [vnteam]
GO
