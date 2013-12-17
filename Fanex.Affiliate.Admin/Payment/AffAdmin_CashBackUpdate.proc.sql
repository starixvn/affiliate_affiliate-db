ALTER PROCEDURE [dbo].[AffAdmin_CashBackUpdate]
	@UserId int=0, 
	@AffId int,
	@MonthDate datetime,
	@Amount money,
	@ErrCode int = 0 OUTPUT
AS
/*    
Task : Insert or update Cashback infor   
DB:    
Original: [AffAdmin_CommissionReport]
Revisions:           
                
Param's Explanation: 
• @UserId: Admin user id
• @AffId: Affiliate ID
• @Month: Cashback month
• @Amount: Cashback amount
• @ErrCode: Return error code
*/    

SET NOCOUNT ON 

EXEC dbo.Aff_CheckPermissionOnAff   
	@custid=@UserID,  
	@AffId=@AffId,  
	@ErrCode=@ErrCode output
   
If @ErrCode <> 0  
	RETURN  

Declare @DTypeID int, @ProductId int, @AffCurrencyID int, @SysExRate float

select @ProductId = 0 --Cashback for all sport

Select @AffCurrencyID = Currency
From AffInfo nolock
where AffID = @AffID

Select @SysExRate = [dbo].[Aff_GetExchangeRate](@AffCurrencyID, [dbo].Aff_GetSystemCurrencyID(), null)

Select @DTypeID = DTypeID 
From DeductionType nolock 
where ProductID = @ProductId 
	and DTypeName = 'Cashback'

IF ((DateDiff(m, CURRENT_TIMESTAMP, @MonthDate) > 1))
BEGIN
	SELECT @ErrCode = 701--Just allow update data for previous and current month
	Return
END

IF (Exists(SELECT 1 FROM AffCommission nolock WHERE nolock.AffID = @AffId AND DATEDIFF(M, WinlostDate, @MonthDate) = 0))
BEGIN
	SELECT @ErrCode = 702--This month has been transfered already
	Return
END

IF(Exists(SELECT 1 from AffDeductionTransaction where AffId = @AffId AND MonthDate = @MonthDate AND DTypeID = @DTypeID AND ProductId = @ProductId))
BEGIN
	UPDATE AffDeductionTransaction
	SET Amount = @Amount
		, TransDate = CURRENT_TIMESTAMP
		, Creator = @UserId
		, SysExRate = @SysExRate
	WHERE AffId = @AffId AND MonthDate = @MonthDate AND DTypeID = @DTypeID AND ProductId = @ProductId
END
ELSE
BEGIN
	insert into AffDeductionTransaction(DTypeID, MonthDate, AffID, ProductID, Amount, SysExRate, TransDate, Creator)
	VALUES (@DTypeID, @MonthDate, @AffId, @ProductId, @Amount, @SysExRate, CURRENT_TIMESTAMP, @UserId)
END


GO
GRANT EXECUTE ON [dbo].[AffAdmin_CashBackUpdate] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CashBackUpdate] TO [vnteam] AS [dbo]