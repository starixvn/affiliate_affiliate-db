ALTER PROCEDURE [dbo].[Aff_AffiliateInsClickStatistics]
	@AffiliateID int,
	@TrackingCode varchar(20)='[None]',
	@IP varchar(20),
	@Browser nvarchar(50),
	@URLReferrer nvarchar(300),		
	@AffType tinyint=0 OUTPUT, 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20090427@Peter
Task : record clicking Banner action with a specific tracking code
DB: DB052.Affiliate_12BET
Original:

Revisions:
- 20090505@Ken: 
-20100831@Peter: Add AffType to decide the currency Agent when passing into dbo.Dot_Dep_CustomerInsMember_Ag sp

Param's Explanation:
.@AffiliateID: id of affiliate in the system,
.@TrackingCode: Tracking Code of this banner, if this null or empty will get 'Dafault' value.
.@ip: ip of User clicked on this banner
.@browser: name of browser,
.@URLReferrer: URL of affiliate site that user click on this banner
.@AffType:    
	 =0: Normal Affiliate , the currency Agent should be 12BET[Currency]02
	 =2: Media Affiliate, the currency Agent should be 12BET[Currency]03
• @ErrCode:
	= 0: Transaction recorded successfully.
	> 0: Insert unsuccessful.
	• @ErrMsg: Error description.
*/
SET NOCOUNT ON
--check Affiliate ID
if not exists (select 1 from AffInfo with(nolock) where AffID=@AffiliateID and status='Approved')
begin
	select @ErrCode=101,@ErrMsg='This affiliate does not exists. Please contact administrator!'                                          
	return                          
end   
select @AffType=AffType
from  AffInfo with(nolock) where AffID=@AffiliateID

 --Checking Input member IP                  
IF COALESCE(@IP, '') = ''
begin
	select @ErrCode=102,@ErrMsg='The IP is required. Please check!' 
	return             
end
--Put the Default value for TrackingCode if it is null
if COALESCE(@TrackingCode, '') = '' select @TrackingCode='[None]'

Declare @TrackingID int
select @TrackingID=TrackingID
from TrackingCode (nolock)
where AffID=@AffiliateID and TrackingCode=@TrackingCode  

--Add new Tracking Code for this Affiliate
if(@TrackingID is null)
begin 
	--Count number of tracking codes inserted today, if it is greater than 100 then we raise an error to prevent insert more rows   
	declare @TrackingCodeCountPerDay int
	select @TrackingCodeCountPerDay=sum(1)
	from TrackingCode (nolock)
	where AffID=@AffiliateID and datediff(day,CreatedDate,current_timestamp)=0
	
	if(isnull(@TrackingCodeCountPerDay,0)>100)
	begin
		 select @ErrCode=103,@ErrMsg='We do not allow to insert more than 100 Tracking Codes per day. Please check!' 
		 return
	end
	
	Insert Into TrackingCode(AffID,TrackingCode,CreatedDate,IP)
	Values (@AffiliateID,@TrackingCode,current_timestamp,@IP)
	Select @TrackingID=SCOPE_IDENTITY()	
end

INSERT INTO ClickStatistics(TrackingID, UpdatedTime, IP, Date, Browser, URLReferrer)
VALUES(@TrackingID,CURRENT_TIMESTAMP,@IP,CONVERT(varchar(10), CURRENT_TIMESTAMP, 120),@Browser,@URLReferrer)
   
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateInsClickStatistics] TO [Dot_Member]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateInsClickStatistics] TO [vnteam]
GO

