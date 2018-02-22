/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_HomeGeneralInfo]
AS

/*
	Created: 20090828@Bryan
	Task: Gather overview statistic information of aff-admin site
	DB: DBAFF12BET.Affiliate_12BET

	Revisions:
		- 20090829@Bryan initialize
		- 20100520@Johnny: apply StatusID in bettrans table
		- 20100729@Johnny: Apply Media affiliate statistics
		- 20140228@Bobby: Apply AffType
		- 20140521@Bobby: Update @BannerNum = @FlashBannerNum + @ImageBannerNum

	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	--Variables for Normal Affiliate
	DECLARE
		@PaymentReqNum INT
		,@AffInProAllNum INT
		,@PendingAllNum INT
		,@ApprovedAllNum INT
		,@DisapprovedAllNum INT
		,@ClosedAllNum INT
		,@DepositMemAllNum INT
		,@DepositAll MONEY
		,@WinlostAll MONEY
		,@BonusAll MONEY
		,@PSPFeeAll MONEY
		,@AdjustmentAll MONEY
		,@NetWinlostAll MONEY
		,@BannerNum INT
		,@ImageBannerNum INT
		,@FlashBannerNum INT
		,@TextBannerNum INT
		,@AffInProMonthNum INT
		,@PendingMonthNum INT
		,@ApprovedMonthNum INT
		,@DisapprovedMonthNum INT
		,@ClosedMonthNum INT
		,@DepositMemMonthNum INT
		,@DepositMonth MONEY
		,@WinlostMonth MONEY
		,@BonusMonth MONEY
		,@PSPFeeMonth MONEY
		,@AdjustmentMonth MONEY
		,@NetWinlostMonth MONEY

	DECLARE @CurrentDate SMALLDATETIME
	SELECT	@CurrentDate = CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)

	SELECT  @PaymentReqNum = SUM(1)
	FROM dbo.AffTrans af WITH (NOLOCK)
	WHERE af.TransType = 202 AND af.Status = 'Pending'

	-- all affiliate statistics
	SELECT
		@PendingAllNum = SUM(CASE WHEN STATUS = 'Pending' THEN 1 ELSE 0 END)
		,@ApprovedAllNum = SUM(CASE WHEN STATUS = 'Approved' AND IsClosed = 0 THEN 1 ELSE 0 END)
		,@DisapprovedAllNum = SUM(CASE WHEN STATUS = 'Disapproved' THEN 1 ELSE 0 END)
		,@ClosedAllNum = SUM(CASE WHEN STATUS = 'Approved' AND IsClosed = 1 THEN 1 ELSE 0 END)
		,@AffInProAllNum = SUM(1)
		,@AffInProMonthNum = SUM(CASE WHEN datediff(mm, RegisteredDate, @CurrentDate) = 0 THEN 1 ELSE 0 END)
		,@PendingMonthNum = SUM(CASE WHEN STATUS = 'pending' AND datediff(mm, RegisteredDate, @CurrentDate) = 0 THEN 1 ELSE 0 END)
		,@ApprovedMonthNum = SUM(CASE WHEN STATUS = 'Approved' AND IsClosed = 0 AND datediff(mm, RegisteredDate, @CurrentDate) = 0 THEN 1 ELSE 0 END)
		,@DisapprovedMonthNum = SUM(CASE WHEN STATUS = 'Disapproved' AND datediff(mm, RegisteredDate, @CurrentDate) = 0 THEN 1 ELSE 0 END)
		,@ClosedMonthNum = SUM(CASE WHEN STATUS = 'Approved' AND IsClosed = 1 AND datediff(mm, RegisteredDate, @CurrentDate) = 0 THEN 1 ELSE 0 END)
	FROM dbo.AffInfo WITH (NOLOCK)
	WHERE AffType IN (SELECT TypeId	FROM dbo.AffType WITH (NOLOCK))

	-- all banner statistics
	SELECT
		@BannerNum = SUM(CASE WHEN ImageType = 'Image' OR ImageType = 'Flash' THEN 1 ELSE 0 END)
		,@ImageBannerNum = SUM(CASE WHEN ImageType = 'Image' THEN 1 ELSE 0 END)
		,@FlashBannerNum = SUM(CASE WHEN ImageType = 'Flash' THEN 1 ELSE 0 END)
		,@TextBannerNum = SUM(CASE WHEN ImageType = 'Text' THEN 1 ELSE 0 END)
	FROM dbo.Banners_1 WITH (NOLOCK)

	--Get statistics of normal affiliate
	EXEC dbo.Aff_GetMemberStatistics
		@AffType = 2 -- normal
		,@DepositAll = @DepositAll OUTPUT
		,@DepositMonth = @DepositMonth OUTPUT
		,@PSPFeeAll = @PSPFeeAll OUTPUT
		,@PSPFeeMonth = @PSPFeeMonth OUTPUT
		,@WinlostAll = @WinlostAll OUTPUT
		,@WinlostMonth = @WinlostMonth OUTPUT
		,@BonusAll = @BonusAll OUTPUT
		,@BonusMonth = @BonusMonth OUTPUT
		,@AdjustmentAll = @AdjustmentAll OUTPUT
		,@AdjustmentMonth = @AdjustmentMonth OUTPUT
		,@NetWinlostAll = @NetWinlostAll OUTPUT
		,@NetWinlostMonth = @NetWinlostMonth OUTPUT

	SELECT
		@DepositMemAllNum = SUM(1)
		,@DepositMemMonthNum = SUM(CASE WHEN datediff(mm, CreatedDate, @CurrentDate) = 0 THEN 1 ELSE 0 END)
	FROM MemberInfo m WITH (NOLOCK)
	WHERE m.IsRemoved = 0

	--final result here
	SELECT
		isnull(@PaymentReqNum, 0) AS PaymentReqNum
		,isnull(@AffInProAllNum, 0) AS AffInProAllNum
		,isnull(@PendingAllNum, 0) AS PendingAllNum
		,isnull(@ApprovedAllNum, 0) AS ApprovedAllNum
		,isnull(@DisapprovedAllNum, 0) AS DisapprovedAllNum
		,isnull(@DepositMemAllNum, 0) AS DepositMemAllNum
		,isnull(@ClosedAllNum, 0) AS ClosedAllNum
		,isnull(@DepositAll, 0) AS DepositAll
		,isnull(@WinlostAll, 0) AS WinlostAll
		,isnull(@BonusAll, 0) AS BonusAll
		,isnull(@PSPFeeAll, 0) AS PSPFeeAll
		,isnull(@PSPFeeAll, 0) AS PSPFeeAll
		,isnull(@AdjustmentAll, 0) AS AdjustmentAll
		,isnull(@NetWinlostAll, 0) AS NetWinlostAll
		,isnull(@BannerNum, 0) AS BannerNum
		,isnull(@ImageBannerNum, 0) AS ImageBannerNum
		,isnull(@FlashBannerNum, 0) AS FlashBannerNum
		,isnull(@TextBannerNum, 0) AS TextBannerNum
		,isnull(@AffInProMonthNum, 0) AS AffInProMonthNum
		,isnull(@PendingMonthNum, 0) AS PendingMonthNum
		,isnull(@ApprovedMonthNum, 0) AS ApprovedMonthNum
		,isnull(@DisapprovedMonthNum, 0) AS DisapprovedMonthNum
		,isnull(@ClosedMonthNum, 0) AS ClosedMonthNum
		,isnull(@DepositMemMonthNum, 0) AS DepositMemMonthNum
		,isnull(@DepositMonth, 0) AS DepositMonth
		,isnull(@WinlostMonth, 0) AS WinlostMonth
		,isnull(@BonusMonth, 0) AS BonusMonth
		,isnull(@PSPFeeMonth, 0) AS PSPFeeMonth
		,isnull(@AdjustmentMonth, 0) AS AdjustmentMonth
		,isnull(@NetWinlostMonth, 0) AS NetWinlostMonth
END
GO