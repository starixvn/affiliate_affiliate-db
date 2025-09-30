/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0" isNested="0"></info>*/

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
