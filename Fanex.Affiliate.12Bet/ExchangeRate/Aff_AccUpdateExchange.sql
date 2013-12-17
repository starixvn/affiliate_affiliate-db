ALTER PROCEDURE [dbo].[Aff_AccUpdateExchange]
	@UserID int,
	@ExchangeId int,
	@Rate float,
	@IP varchar(20),
	@language varchar(2) = 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: 20091010@Johnny
	Task : Update exchange rate when updating in Accouting site
	DB: DB052.Affiliate_12BET
	Revisions:
		- 20091014@Johnny initialize
		
	Param's Explanation:

*/
SET NOCOUNT ON
	
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
	@custid=@UserID,
	@funcname='[ExchangeRate]',
	@System = 'Accounting',
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN

declare @CurrDate smalldatetime

select @CurrDate = convert(varchar(10),current_timestamp,120)

if Exists(select 1 from Exchange_Current with (nolock) where ExchangeId = @ExchangeId and Actualrate = @Rate)
	return--Do nothing if actualrate as the same as the current one

if @ExchangeId = 2--Cannot update base currecy(RM).ActualRate of RM is always equal 1
	return
	
BEGIN TRANSACTION	
	BEGIN TRY
		If @ExchangeId = 3--When updating USD, process will update all actualrate2 of other currency
		Begin
			Update Exchange_Current with (rowlock, updlock) set ActualRate = @Rate where ExchangeID = @ExchangeId
			
			Update Exchange_Current with (rowlock, updlock) set ActualRate2 = ActualRate/@Rate--Reset Actualrate2 for others currecy
			
			--Delete current rows in exchange table
			Delete Exchange with (rowlock, updlock)
			where UpdatedTime = @CurrDate
			--Insert currency from current to history
			insert into Exchange(UpdatedTime, ExchangeID, Currency, ActualRate, ActualRate2, Creator,DepositPercent,WithdrawalPercent)
			select @CurrDate, ExchangeId, Currency, ActualRate, ActualRate2, @UserID,DepositPercent,WithdrawalPercent
			from Exchange_Current with (nolock)
		End
		Else
		Begin
			Declare @ActualRate2 float--Rate base on USD	
			select @ActualRate2 = @Rate/Actualrate from Exchange_Current with (nolock) where ExchangeId = 3
			
			Update Exchange_Current with (rowlock, updlock) 
			set ActualRate = @Rate, ActualRate2 = @ActualRate2--Reset Actualrate2
			where ExchangeID = @ExchangeId
			
			--Delete current rows in exchange table
			Delete Exchange with (rowlock, updlock)
			where UpdatedTime = @CurrDate and ExchangeId = @ExchangeId
			--Insert changed currency into exchange table	
			insert into Exchange(UpdatedTime, ExchangeID, Currency, ActualRate, ActualRate2, Creator,DepositPercent,WithdrawalPercent)
			select @CurrDate, ExchangeID, Currency, ActualRate, ActualRate2, @UserID,DepositPercent,WithdrawalPercent
			From Exchange_Current with (nolock)
			where ExchangeID = @ExchangeID		
			
		End
	ENd TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		Select @ErrMsg = 'Update exchange rate is unsuccessful.', @ErrCode = 101
		RETURN		
	END CATCH
COMMIT TRANSACTION

DECLARE @LogData nvarchar(200)
SELECT @LogData = 'Accounting site: Update exchange rate of affiliate . ExchangeId:' + dbo.Aff_ToString(@ExchangeId) + ', Rate: ' + dbo.Aff_ToString(@Rate)

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog]
	@Creator=@UserID,		
	@TypeName= 'ExchangeRate',	
	@SPName=@SPName,
	@IP =@IP,
	@Details=@LogData

GO
GRANT EXEC ON [dbo].[Aff_AccUpdateExchange] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AccUpdateExchange] TO [VNTeam]