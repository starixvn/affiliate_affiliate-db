USE [Deposit_DB]
GO
/****** Object:  StoredProcedure [dbo].[DEP_SignUpMembersReport]    Script Date: 01/15/2011 05:01:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER Procedure [dbo].[DEP_SignUpMembersReport]
	@AffId int=-1,
	@Fromdate datetime=null,
	@Todate datetime=null,
	@IsGetAll bit=0
AS
/*
Created: @Peter
Task : Report to get Signup and member statistics
DB: [B04-05].Deposit_DB
Original: 
Revisions:
	
Param's Explanation:
	• @AffId Affiliate Id
	• @Fromdate Time search From
	• @Todate Time search To,
	• @IsGetAll if getall = 1 => get data in all date of Affiliate,
*/
Set Nocount On	
if (@IsGetAll =0 and @FromDate is not null and @ToDate is not null and @FromDate<=@ToDate)
begin
	select @Fromdate=convert (varchar(10),@Fromdate,120)
	select @Todate=convert (varchar(10),@Todate,120)

	select @Todate=dateadd(s,-1,dateadd(d,1,@Todate))
	
	SELECT AffiliateID,sum(1) as TotalSignUp
	FROM Deposit_Customer WITH(NOLOCK)
	WHERE (@AffId=-1 or AffiliateID = @AffId) 
	AND creatdate between @Fromdate and  @Todate
	Group by AffiliateID
end
else if (@IsGetAll =1)
begin 
	SELECT AffiliateID, sum(1) as TotalSignUp
	FROM Deposit_Customer WITH(NOLOCK)	
	Group by AffiliateID

end


GO
GRANT EXECUTE ON [dbo].[DEP_SignUpMembersReport] TO [bodbAffiliateNet]
GO
GRANT VIEW DEFINITION ON [dbo].[DEP_SignUpMembersReport] TO [vnTeam]