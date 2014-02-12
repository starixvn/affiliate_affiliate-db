   
set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go



ALTER PROCEDURE [dbo].[Aff_HomeGeneralInfo]		
AS
/*Created: 20090828@Bryan
Task : Gather overview statistic information of aff-admin site
DB: DB052.Affiliate_ZZun

Revisions:
	- 20090829@Bryan initialize
	- 20100520@Johnny: apply StatusID in bettrans table
	- 20100729@Johnny: Apply Media affiliate statistics
Param's Explanation:

*/
BEGIN
	Declare 
		@MemInProAllNum int,
		@MemInProMonthNum int
		
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
	
	    @NonDepositMemMonthNum int ,	
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
		@NetWinlostMonth MONEY ,
		@LockedAllNum int ,
		@LockedMonthNum int

		
	Declare @TransType int
	declare @CurrentDate smalldatetime

	SET NOCOUNT ON;	
	
	select @CurrentDate=convert(varchar(10),current_timestamp,120)
	
	
	select @TransType = 202 -- payment request
	
	SELECT @PaymentReqNum = sum(1) 
	FROM AffTrans af with(nolock)
	WHERE af.TransType = @TransType 
		AND af.Status='Pending'
		
	-- all affiliate statc		
	SELECT 
		@PendingAllNum = sum(case when status='Pending' then 1 else 0 end),
		@ApprovedAllNum	 = sum(case when status='Approved' and IsClosed = 0 and IsLocked=0 then 1 else 0 end),
		@DisapprovedAllNum = sum(case when status='Disapproved' then 1 else 0 end),
		@ClosedAllNum = sum(case when status='Approved' and IsClosed = 1 then 1 else 0 end),
		@LockedAllNum = sum(case when status='Approved' and IsLocked = 1 then 1 else 0 end),
		@AffInProAllNum =sum(1),
		@AffInProMonthNum = sum(case when datediff(mm, RegisteredDate, @CurrentDate)=0 then 1 else 0 end),
		@PendingMonthNum = sum(case when Status='pending' and datediff(mm, RegisteredDate, @CurrentDate)=0 then 1 else 0 end),
		@ApprovedMonthNum = sum(case when Status='Approved' and IsClosed = 0 and IsLocked=0 and datediff(mm, RegisteredDate, @CurrentDate)=0 then 1 else 0 end),
		@DisapprovedMonthNum= sum(case when Status='Disapproved' and datediff(mm, RegisteredDate, @CurrentDate)=0 then 1 else 0 end),
		@ClosedMonthNum= sum(case when status='Approved' and IsClosed = 1 and datediff(mm, RegisteredDate, @CurrentDate)=0 then 1 else 0 end),
		@LockedMonthNum= sum(case when status='Approved' and IsLocked = 1 and datediff(mm, RegisteredDate, @CurrentDate)=0 then 1 else 0 end)
	FROM AffInfo ai with(nolock)
	   
	--Get statistics of all affiliate types
	Exec Aff_GetMemberStatistics
		@AffType = 0,
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
	
	
		   
	select @DepositMemAllNum = sum(case when CreatedDate is not null then 1 else 0 end),
		   @DepositMemMonthNum = sum(case when datediff(m, CreatedDate, @CurrentDate) = 0 then 1 else 0 end),
		   @MemInProAllNum = count(1),
		   @MemInProMonthNum =sum(case when datediff(m, RegisteredDate, @CurrentDate) = 0 then 1 else 0 end),
		   @NonDepositMemMonthNum= sum(case when datediff(m, RegisteredDate, @CurrentDate) = 0 and CreatedDate is null then 1 else 0 end)
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
	
	isnull(@AffInProMonthNum,0) as AffInProMonthNum,
	isnull(@PendingMonthNum,0) as PendingMonthNum,
	isnull(@ApprovedMonthNum,0) as ApprovedMonthNum,
	isnull(@DisapprovedMonthNum,0) as DisapprovedMonthNum,
	
	isnull(@ClosedMonthNum, 0) as ClosedMonthNum,
	isnull(@DepositMemMonthNum,0)as DepositMemMonthNum,
	isnull(@NonDepositMemMonthNum,0) as NonDepositMemMonthNum,

	isnull(@DepositMonth,0) as DepositMonth,
	isnull(@WinlostMonth,0) as WinlostMonth,
	isnull(@BonusMonth,0) as BonusMonth,
	isnull(@PSPFeeMonth,0) as PSPFeeMonth ,
	isnull(@AdjustmentMonth,0) as AdjustmentMonth,
	isnull(@NetWinlostMonth,0) as NetWinlostMonth,
	
	isnull(@MemInProAllNum,0) as MemInProAllNum,
	isnull(@MemInProMonthNum,0) as MemInProMonthNum,
	isnull(@LockedAllNum,0) as  LockedAllNum,
	isnull(@LockedMonthNum,0) as LockedMonthNum

		
	-- //all banner statc
	SELECT 
	    at.TypeID as TypeID, 
	    at.Name as TypeName,
		sum(case when bt.Value in ('Image','Flash') then 1 else 0 end) as BannerNum,
		sum(case when bt.Value='Image'  then 1 else 0 end) as ImageBannerNum,
		sum(case when bt.Value='Flash' then 1 else 0 end) as FlashBannerNum		
	FROM Banners b with(nolock)
	inner join BannerTypes bt with (nolock) on b.ImageType=bt.TypeID
	inner join AffType at (nolock) on at.TypeID=b.Type
	where bt.Type='ImageType'
	group by at.TypeID,at.Name
		
END


  
GO
GRANT EXECUTE ON [dbo].[Aff_HomeGeneralInfo] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_HomeGeneralInfo] TO [vnteam]