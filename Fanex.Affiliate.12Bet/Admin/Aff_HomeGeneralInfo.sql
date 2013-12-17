ALTER PROCEDURE [dbo].[Aff_HomeGeneralInfo]		
AS
/*Created: 20090828@Bryan
Task : Gather overview statistic information of aff-admin site
DB: DB052.Affiliate_12bet

Revisions:
	- 20090829@Bryan initialize
	- 20100520@Johnny: apply StatusID in bettrans table
	- 20100729@Johnny: Apply Media affiliate statistics
Param's Explanation:

*/
BEGIN
	--Variables for Normal Affiliate
	Declare @PaymentReqNum int ,
		@AffInProAllNum int ,
		@PendingAllNum int ,
		@ApprovedAllNum int ,
		@DisapprovedAllNum int ,
		@ClosedAllNum int,
		@DepositMemAllNum int ,	
		@DepositAll MONEY ,
		@WinlostAll MONEY ,
		@BonusAll MONEY ,
		@PSPFeeAll MONEY ,
		@AdjustmentAll MONEY ,
		@NetWinlostAll MONEY ,
		@BannerNum int ,
		@ImageBannerNum int ,
		@FlashBannerNum int ,
		@AffInProMonthNum int ,
		@PendingMonthNum int ,
		@ApprovedMonthNum int ,
		@DisapprovedMonthNum int ,
		@ClosedMonthNum int,
		@DepositMemMonthNum int ,
		@DepositMonth MONEY ,
		@WinlostMonth MONEY ,
		@BonusMonth MONEY ,
		@PSPFeeMonth MONEY ,
		@AdjustmentMonth MONEY ,
		@NetWinlostMonth MONEY 
	--Variables for Media Affiliate
	Declare 
		@MediaNum int,
		@MediaActiveNum int,
		@MediaClosedNum int,
		@MediaMonthNum int,
		@MediaActiveMonthNum int,
		@MediaClosedMonthNum int,
		@MediaDepositAll money,
		@MediaDepositMonth money,
		@MediaWinlostAll money,
		@MediaWinlostMonth money,
		@MediaBonusAll money,
		@MediaBonusMonth money,
		@MediaAdjustmentAll money,
		@MediaAdjustmentMonth money,
		@MediaNetWinlostAll money,
		@MediaNetWinlostMonth money
		
	Declare @TransType int
	declare @CurrentDate smalldatetime, @PreviousDate smalldatetime
	Declare @AffNormal tinyint, @AffMedia tinyint
	--dflag=0 : for all previous months data
	-- dflag=1 : for current month data

	SET NOCOUNT ON;	
	
	select @CurrentDate=convert(varchar(10),current_timestamp,120),
		   @PreviousDate=dateadd(d, -1, @CurrentDate)
	select @AffNormal = 0, @AffMedia = 2
	
	select @TransType = 202 -- payment request
	
	SELECT @PaymentReqNum = sum(1) 
	FROM AffTrans af with(nolock)
	WHERE af.TransType = @TransType 
		AND af.Status='Pending'
		
	-- all affiliate statc		
	SELECT 
		@PendingAllNum = sum(case when status='Pending' then 1 else 0 end),
		@ApprovedAllNum	 = sum(case when status='Approved' and IsClosed = 0 then 1 else 0 end),
		@DisapprovedAllNum = sum(case when status='Disapproved' then 1 else 0 end),
		@ClosedAllNum = sum(case when status='Approved' and IsClosed = 1 then 1 else 0 end),
		@AffInProAllNum =sum(1),
		@AffInProMonthNum = sum(case when datediff(mm, RegisteredDate, @CurrentDate)=0 then 1 else 0 end),
		@PendingMonthNum = sum(case when Status='pending' and datediff(mm, RegisteredDate, @CurrentDate)=0 then 1 else 0 end),
		@ApprovedMonthNum = sum(case when Status='Approved' and IsClosed = 0 and datediff(mm, RegisteredDate, @CurrentDate)=0 then 1 else 0 end),
		@DisapprovedMonthNum= sum(case when Status='Disapproved' and datediff(mm, RegisteredDate, @CurrentDate)=0 then 1 else 0 end),
		@ClosedMonthNum= sum(case when status='Approved' and IsClosed = 1 and datediff(mm, RegisteredDate, @CurrentDate)=0 then 1 else 0 end)
	FROM AffInfo with(nolock)
	WHERE AffType = @AffNormal
	
	--Media Affiliate statistics
	SELECT 
		@MediaActiveNum = sum(case when IsClosed = 0 then 1 else 0 end),
		@MediaClosedNum = sum(case when IsClosed = 1 then 1 else 0 end),
		@MediaNum = sum(1),
		@MediaActiveMonthNum = sum(case when IsClosed = 0 and datediff(mm, RegisteredDate, @CurrentDate)=0 then 1 else 0 end),
		@MediaClosedMonthNum = sum(case when IsClosed = 1 and datediff(mm, RegisteredDate, @CurrentDate)=0 then 1 else 0 end),
		@MediaMonthNum = sum(case when datediff(mm, RegisteredDate, @CurrentDate)=0 then 1 else 0 end)
	FROM AffInfo with(nolock)
	WHERE AffType = @AffMedia
	
	
	-- //all banner statc
	SELECT 
		@BannerNum = sum(1),
		@ImageBannerNum =  sum(case when ImageType='Image'then 1 else 0 end),
		@FlashBannerNum= sum(case when ImageType='Flash'then 1 else 0 end)
	FROM Banners with(nolock)
	
	declare @MaxWinLostDateAffComm smalldatetime,@NextMaxWinlostDate smalldatetime
	
	select @MaxWinLostDateAffComm=max(winlostdate) from  AffCommission with(nolock)
	select @NextMaxWinlostDate=dateadd(d, 1, @MaxWinLostDateAffComm)
		   
	--Get statistics of normal affiliate
	Exec Aff_GetMemberStatistics
		@AffType = @AffNormal,
		@DepositAll = @DepositAll Output,
		@DepositMonth = @DepositMonth Output,
		@PSPFeeAll = @PSPFeeAll Output,
		@PSPFeeMonth = @PSPFeeMonth Output,
		@WinlostAll = @WinlostAll Output,
		@WinlostMonth= @WinlostMonth Output,
		@BonusAll = @BonusAll Output,
		@BonusMonth = @BonusMonth Output,
		@AdjustmentAll = @AdjustmentAll Output,
		@AdjustmentMonth = @AdjustmentMonth Output,
		@NetWinlostAll = @NetWinlostAll Output,
		@NetWinlostMonth = @NetWinlostMonth Output
	
	--Get statistics of media affiliate 
	Exec Aff_GetMemberStatistics
		@AffType = @AffMedia,
		@DepositAll = @MediaDepositAll Output,
		@DepositMonth = @MediaDepositMonth Output,
		@WinlostAll = @MediaWinlostAll Output,
		@WinlostMonth= @MediaWinlostMonth Output,
		@BonusAll = @MediaBonusAll Output,
		@BonusMonth = @MediaBonusMonth Output,
		@AdjustmentAll = @MediaAdjustmentAll Output,
		@AdjustmentMonth = @MediaAdjustmentMonth Output,
		@NetWinlostAll = @MediaNetWinlostAll Output,
		@NetWinlostMonth = @MediaNetWinlostMonth Output 
		
		   
	select @DepositMemAllNum = sum(1),
		   @DepositMemMonthNum = sum(case when datediff(mm, CreatedDate, @CurrentDate) = 0 then 1 else 0 end)		  	
	from MemberInfo with(nolock) where IsRemoved=0
	
  
  
  
  --final result here
  select isnull(@PaymentReqNum,0) as  PaymentReqNum ,
	isnull(@AffInProAllNum,0) as AffInProAllNum,
	isnull(@PendingAllNum,0) as PendingAllNum,
	isnull(@ApprovedAllNum,0)  as ApprovedAllNum,
	isnull(@DisapprovedAllNum,0) as DisapprovedAllNum,
	isnull(@DepositMemAllNum,0) as DepositMemAllNum,	
	isnull(@ClosedAllNum, 0) as ClosedAllNum,
	isnull(@DepositAll,0) as DepositAll,
	isnull(@WinlostAll,0) as WinlostAll,
	isnull(@BonusAll,0) as BonusAll,
	isnull(@PSPFeeAll,0) as PSPFeeAll,
	isnull(@PSPFeeAll,0) as PSPFeeAll,
	isnull(@AdjustmentAll,0) as AdjustmentAll,
	isnull(@NetWinlostAll,0) as NetWinlostAll,
	isnull(@BannerNum,0) as BannerNum,
	isnull(@ImageBannerNum,0) as ImageBannerNum,
	isnull(@FlashBannerNum,0) as FlashBannerNum,
	isnull(@AffInProMonthNum,0) as AffInProMonthNum,
	isnull(@PendingMonthNum,0) as PendingMonthNum,
	isnull(@ApprovedMonthNum,0) as ApprovedMonthNum,
	isnull(@DisapprovedMonthNum,0) as DisapprovedMonthNum,
	isnull(@ClosedMonthNum, 0) as ClosedMonthNum,
	isnull(@DepositMemMonthNum,0)as DepositMemMonthNum,
	isnull(@DepositMonth,0) as DepositMonth,
	isnull(@WinlostMonth,0) as WinlostMonth,
	isnull(@BonusMonth,0) as BonusMonth,
	isnull(@PSPFeeMonth,0) as PSPFeeMonth ,
	isnull(@AdjustmentMonth,0) as AdjustmentMonth,
	isnull(@NetWinlostMonth,0) as NetWinlostMonth,
	--Media Affiliate
	isnull(@MediaNum,0) as MediaNum,
	isnull(@MediaActiveNum,0) as MediaActiveNum,
	isnull(@MediaClosedNum,0) as MediaClosedNum,
	isnull(@MediaActiveMonthNum,0) as MediaActiveMonthNum,
	isnull(@MediaClosedMonthNum ,0) as MediaClosedMonthNum,
	isnull(@MediaMonthNum ,0) as MediaMonthNum,
	isnull(@MediaNum ,0) asMediaNum,
	isnull(@MediaActiveNum ,0) as MediaActiveNum,
	isnull(@MediaClosedNum ,0) as MediaClosedNum,
	isnull(@MediaMonthNum ,0) as MediaMonthNum,
	isnull(@MediaActiveMonthNum ,0) as MediaActiveMonthNum,
	isnull(@MediaClosedMonthNum ,0) as MediaClosedMonthNum,
	isnull(@MediaDepositAll ,0) as MediaDepositAll,
	isnull(@MediaDepositMonth ,0) as MediaDepositMonth,
	isnull(@MediaWinlostAll ,0) as MediaWinlostAll,
	isnull(@MediaWinlostMonth ,0) as MediaWinlostMonth,
	isnull(@MediaBonusAll ,0) as MediaBonusAll,
	isnull(@MediaBonusMonth ,0) as MediaBonusMonth,
	isnull(@MediaAdjustmentAll ,0) as MediaAdjustmentAll,
	isnull(@MediaAdjustmentMonth ,0) as MediaAdjustmentMonth,
	isnull(@MediaNetWinlostAll ,0) as MediaNetWinlostAll,
	isnull(@MediaNetWinlostMonth  ,0) as MediaNetWinlostMonth
END

GO
GRANT EXECUTE ON [dbo].[Aff_HomeGeneralInfo] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_HomeGeneralInfo] TO [vnteam]