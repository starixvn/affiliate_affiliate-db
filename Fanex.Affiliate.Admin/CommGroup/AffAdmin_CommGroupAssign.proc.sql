USE [Affiliate_Athena000]
GO
/****** Object:  StoredProcedure [dbo].[AffAdmin_CommGroupAssign]    Script Date: 04/28/2014 06:01:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[AffAdmin_CommGroupAssign] 
	@UserId INT
	,@GroupId INT
	,@AffIDList NVARCHAR(4000)
	,@IP VARCHAR(20)
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT
	,@RefNo BIGINT = NULL OUTPUT
AS
/*  
Created: 20090719@DungTong  
Task : Assign a commission group (GroupID<1000) for multiple Affilites   
DB: DB052.Affiliate_AoncashUAT
Original:  
  
Revisions:  
Parameters:  
.@UserID : Administrator user id  
.@GroupID : <1000  
.@AfIDList: list of AffID separated by comma.Maximum of 200 AffIDs are assiged each time                  
.@IP : IP of admin user               
.@ErrCode:    
              0 : no error raised  
              >0 : there was an error  
.@ErrMsg :     
              empty: no error raised  
              others : the error message detail                            
                            
*/
BEGIN
	SET NOCOUNT ON

	--Check permission  
	/*EXEC [dbo].[Aff_Con_CheckPermission]  
     @custid=@UserID,@funcname='Affiliate',  
     @System = 'AFFILIATE',  
     @ErrCode=@ErrCode output,  
     @ErrMsg=@ErrMsg output  

If @ErrCode <> 0
    RETURN 
*/
	DECLARE @AffId INT
	DECLARE @AffCurrency TABLE (
		AffID INT
		,Currency INT
		);

	--currency checking
	INSERT INTO @AffCurrency (
		AffID
		,Currency
		)
	SELECT DISTINCT AffID
		,Currency
	FROM dbo.AffInfo WITH (NOLOCK)
	WHERE AffID IN (
			SELECT cast(val AS INT) AS AffID
			FROM dbo.strsplit(@AffIDList, ',')
			)

	SELECT @AffId = AffID
	FROM @AffCurrency

	EXEC dbo.Aff_CheckPermissionOnAff @custid = @UserID
		,@AffId = @AffId
		,@ErrCode = @ErrCode OUTPUT
		,@ErrMsg = @ErrMsg OUTPUT

	IF (@ErrMsg <> '') RETURN

	IF (
			NOT EXISTS (
				SELECT 1
				FROM dbo.CommGroup WITH (NOLOCK)
				WHERE GroupID = @GroupID
					AND IsDeleted = 0
					AND (
						@GroupId = 102
						OR Currency = ISNULL((
								SELECT TOP 1 Currency
								FROM @AffCurrency
								), Currency)
						)
				)
			)
	BEGIN
		SELECT @ErrCode = 601

		RETURN
	END

	--Check AffIDList  
	/*    
    Input params is valid with the correct format. Use Try..Catch to eval the input value  
*/
	DECLARE @NoAff INT
		,@CountCurrency INT

	BEGIN TRY
		SELECT @NoAff = sum(1)
		FROM AffInfo WITH (NOLOCK)
		WHERE AffID IN (
				SELECT cast(val AS INT) AS AffID
				FROM dbo.strsplit(@AffIDList, ',')
				)
			AND STATUS = 'approved' -- and IsClosed=0  

		IF (
				@NoAff <> (
					SELECT sum(1)
					FROM dbo.strsplit(@AffIDList, ',')
					)
				)
		BEGIN
			SELECT @ErrCode = 602

			RETURN
		END

		--Check Currency of Group and Currency of Match   
		SET @CountCurrency = 0

		SELECT @CountCurrency = count(DISTINCT currency)
		FROM AffInfo(NOLOCK)
		WHERE AffID IN (
				SELECT cast(val AS INT) AS AffID
				FROM dbo.strsplit(@AffIDList, ',')
				)

		IF (isnull(@CountCurrency, 0) > 1)
		BEGIN
			SELECT @ErrCode = 604

			RETURN
		END
	END TRY

	BEGIN CATCH
		SELECT @ErrCode = 603

		RETURN
	END CATCH

	--BEGIN TRANSACTION AFTER CHECKING VALID INPUT DATA  
	BEGIN TRANSACTION

	--Delete GroupID>1000 where GroupID in AffiliateID list and already assigned before  
	DELETE DeductionSetting
	WHERE GroupID IN (
			SELECT GroupID
			FROM AffInfo(NOLOCK)
			WHERE AffID IN (
					SELECT cast(val AS INT)
					FROM dbo.strsplit(@AffIDList, ',')
					)
				AND AffID = GroupID
			)

	IF (@@ERROR <> 0)
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = 605

		RETURN
	END

	DELETE GroupSetting
	WHERE GroupID IN (
			SELECT GroupID
			FROM AffInfo(NOLOCK)
			WHERE AffID IN (
					SELECT cast(val AS INT)
					FROM dbo.strsplit(@AffIDList, ',')
					)
				AND AffID = GroupID
			)

	IF (@@ERROR <> 0)
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = 606

		RETURN
	END

	DELETE CommGroup
	WHERE GroupID IN (
			SELECT GroupID
			FROM AffInfo(NOLOCK)
			WHERE AffID IN (
					SELECT cast(val AS INT)
					FROM dbo.strsplit(@AffIDList, ',')
					)
				AND AffID = GroupID
			)

	IF (@@ERROR <> 0)
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = 607

		RETURN
	END

	UPDATE AffInfo WITH (ROWLOCK, UPDLOCK)
	SET GroupID = @GroupID
	WHERE AffID IN (
			SELECT cast(val AS INT) AS AffID
			FROM dbo.strsplit(@AffIDList, ',')
			)

	-- Update MemberDaily, AffDaily, AffDailySummary
	DECLARE @SportsBookID TINYINT

	SELECT @SportsBookID = dbo.Aff_GetSportID('SportsBook')

	--Update MemberDaily PSP, Marketting fee,...
	UPDATE m
	SET PSP = abs(Deposit) * e.DepositPercent + abs(Withdrawal) * e.WithdrawalPercent
		,Marketing = abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(m.AffID, ProductId, 'Marketing', NULL), 0)
		,MemOddsFee = abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(m.AffID, ProductId, 'Odds Fee', NULL), 0)
		,MemPLayTechFee = abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(m.AffID, ProductId, 'PlayTech Royalties', NULL), 0)
		,MemWinlostFake = - (- Winlost - ((abs(Deposit) * e.DepositPercent + abs(Withdrawal) * e.WithdrawalPercent)) * isnull(dbo.Aff_GetDeductionPercent(m.AffID, @SportsBookID, 'PSP', NULL), 0) - abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(m.AffID, ProductId, 'Marketing', NULL), 0) - abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(m.AffID, ProductId, 'Odds Fee', NULL), 0) - abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(m.AffID, ProductId, 'PlayTech Royalties', NULL), 0))
	FROM MemberDaily AS m WITH (ROWLOCK, UPDLOCK)
		INNER JOIN Exchange AS e(NOLOCK)
		ON m.Currency = e.ExchangeId
	WHERE datediff(m, m.WinlostDate, CURRENT_TIMESTAMP) = 0
		AND m.AffID IN (
			SELECT cast(val AS INT) AS AffID
			FROM dbo.strsplit(@AffIDList, ',')
			)

	/*
CREATE TABLE #MemberDailySum (AffID int, MemCurrency int,Winlostdate smalldatetine, ProductID tinyint,SysExRate float, AffExRate float, MemMarketing money, MemPSP money,
                               MemWinlostFake money, MemOddsFee money, MemPlayTechFee money)*/
	SELECT m.[AffID]
		,m.[Currency] AS [MemCurrency]
		,m.[WinlostDate]
		,m.[ProductID]
		,m.[SysExRate]
		,m.AffExRate
		,Sum(Marketing) AS MemMarketing
		,Sum(PSP) AS MemPSP
		,Sum(MemWinlostFake) AS MemWinlostFake
		,Sum(MemOddsFee) AS MemOddsFee
		,Sum(MemPLayTechFee) AS MemPLayTechFee
	INTO #MemberDailySum
	FROM MemberDaily(NOLOCK) AS m
	WHERE datediff(m, m.WinlostDate, CURRENT_TIMESTAMP) = 0
		AND m.AffID IN (
			SELECT cast(val AS INT) AS AffID
			FROM dbo.strsplit(@AffIDList, ',')
			)
	GROUP BY m.AffID
		,m.Currency
		,m.Winlostdate
		,m.ProductID
		,m.[SysExRate]
		,m.[AffExRate]

	--Update AffDaily
	UPDATE ad
	SET ad.MemMarketing = md.MemMarketing
		,ad.MemPSP = md.MemPSP
		,ad.MemOddsFee = md.MemOddsFee
		,ad.MemPLayTechFee = md.MemPlayTechFee
	FROM AffDaily ad WITH (ROWLOCK, UPDLOCK)
		INNER JOIN #MemberDailySum md(NOLOCK)
		ON ad.AffID = md.AffId
			AND ad.MemCurrency = md.MemCurrency
			AND ad.Winlostdate = md.Winlostdate
			AND ad.ProductID = md.ProductID

	UPDATE ad
	SET HouseNetWinLost = HouseWinLost - isnull(MemPSP, 0) * (1 - isnull(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'PSP', Winlostdate), 0)) - isnull(MemBonus, 0) * (1 - isnull(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Bonus', Winlostdate), 0)) - isnull(MemAdjustment, 0) * (1 - isnull(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Adjustment', Winlostdate), 0)) - abs(isnull(MemWinlost, 0)) * (1 - isnull(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Marketing', Winlostdate), 0)) - abs(isnull(MemWinlost, 0)) * (1 - isnull(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Odds Fee', Winlostdate), 0)) - abs(isnull(MemWinlost, 0)) * (1 - isnull(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'PlayTech Royalties', Winlostdate), 0))
	FROM AffDaily ad WITH (ROWLOCK, UPDLOCK)
	WHERE datediff(m, ad.WinlostDate, CURRENT_TIMESTAMP) = 0
		AND ad.AffID IN (
			SELECT cast(val AS INT) AS AffID
			FROM dbo.strsplit(@AffIDList, ',')
			)

	--AffDailySummary
	UPDATE ad
	SET ad.MemMarketing = tmp.MemMarketing
		,ad.MemPSP = tmp.MemPSP
		,ad.MemOddsFee = tmp.MemOddsFee
		,ad.MemPLayTechFee = tmp.MemPlayTechFee
	FROM AffDaily ad WITH (ROWLOCK, UPDLOCK)
		INNER JOIN (
		SELECT md.AffID
			,md.Winlostdate
			,md.ProductID
			,Sum(MemMarketing) * SysExRate AS MemMarketing
			,Sum(MemMarketing) * AffExRate AS MemMarketing_aff
			,Sum(MemPSP) * SysExRate AS MemPSP
			,Sum(MemPSP) * AffExRate AS MemPSP_aff
			,Sum(MemOddsFee) * SysExRate AS MemOddsFee
			,Sum(MemOddsFee) * AffExRate AS MemOddsFee_aff
			,Sum(MemPlayTechFee) * SysExRate AS MemPlayTechFee
			,Sum(MemPlayTechFee) * AffExRate AS MemPlayTechFee_aff
		FROM #MemberDailySum md(NOLOCK)
		GROUP BY md.AffID
			,md.Winlostdate
			,md.SysExRate
			,md.AffExRate
			,md.ProductID
		) tmp
		ON tmp.AffID = ad.AffID
			AND tmp.Winlostdate = ad.Winlostdate
			AND tmp.ProductID = ad.ProductID

	UPDATE ad
	SET HouseNetWinLost = HouseWinLost - isnull(MemPSP, 0) * (1 - isnull(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'PSP', Winlostdate), 0)) - isnull(MemBonus, 0) * (1 - isnull(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Bonus', Winlostdate), 0)) - isnull(MemAdjustment, 0) * (1 - isnull(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Adjustment', Winlostdate), 0)) - abs(isnull(MemWinlost, 0)) * (1 - isnull(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Marketing', Winlostdate), 0)) - abs(isnull(MemWinlost, 0)) * (1 - isnull(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Odds Fee', Winlostdate), 0)) - abs(isnull(MemWinlost, 0)) * (1 - isnull(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'PlayTech Royalties', Winlostdate), 0))
		,HouseNetWinLost_aff = HouseWinLost_aff - isnull(MemPSP_aff, 0) * (1 - isnull(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'PSP', Winlostdate), 0)) - isnull(MemBonus_aff, 0) * (1 - isnull(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Bonus', Winlostdate), 0)) - isnull(MemAdjustment_aff, 0) * (1 - isnull(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Adjustment', Winlostdate), 0)) - abs(isnull(MemWinlost_aff, 0)) * (1 - isnull(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Marketing', Winlostdate), 0)) - abs(isnull(MemWinlost_aff, 0)) * (1 - isnull(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Odds Fee', Winlostdate), 0)) - abs(isnull(MemWinlost_aff, 0)) * (1 - isnull(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'PlayTech Royalties', Winlostdate), 0))
	FROM AffDailySummary ad WITH (ROWLOCK, UPDLOCK)
	WHERE datediff(m, ad.WinlostDate, CURRENT_TIMESTAMP) = 0
		AND ad.AffID IN (
			SELECT cast(val AS INT) AS AffID
			FROM dbo.strsplit(@AffIDList, ',')
			)

	DROP TABLE #MemberDailySum;

	IF (@@ERROR <> 0)
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = 608

		RETURN
	END

	COMMIT TRANSACTION

	--Write the log   
	DECLARE @LogData NVARCHAR(4000)
		,@SPName VARCHAR(100)

	IF (
			(
				SELECT count(1)
				FROM dbo.strsplit(@AffIDList, ',')
				) = 1
			)
		SELECT @AffID = cast(@AffIDList AS INT)
	ELSE
		SELECT @AffID = 0

	SELECT @LogData = N'Assign a common commission group.GroupID=' + dbo.Aff_ToString(@GroupID) + '\n AffIDList=' + dbo.Aff_ToString(@AffIDList)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	EXEC [dbo].[Aff_WriteLog] @Creator = @UserId
		,@AffID = @AffID
		,@Typename = 'CommissionGroup'
		,@SPName = @SPName
		,@IP = @IP
		,@RefNo = @RefNo OUTPUT
		,@Details = @LogData
END

GO
GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupAssign] TO [bodbAdminNet] AS [dbo]