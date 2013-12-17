USE [Affiliate_12BET]
GO
/****** Object:  StoredProcedure [dbo].[DBA_Aff_ExchangeUpdate]    Script Date: 05/04/2010 05:45:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 ALTER PROCEDURE [dbo].[DBA_Aff_ExchangeUpdate]
	@CustId int,
	@CurrencyName varchar(10),
	@Rate float,
	@Date smalldatetime,
	@IP varchar(20),
	@language varchar(2) = 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	This sp is used to support DBA to update exchange rate for any day
	Created: 20100504@Peter
	Task : Update exchange rate
	DB: DB052.Affiliate_12BET
	Revisions:		
		
	Param's Explanation:

*/
SET NOCOUNT ON

declare @ExchangeId int

Select @ExchangeId=ExchangeID
from Exchange_Current (nolock)
where Currency=@CurrencyName
	
if @ExchangeId = 3
begin
	select @ErrCode = 101, @ErrMsg = 'You cannot edit rate of USD'
	return
end

if Exists(select 1 from Exchange_Current with (nolock) where ExchangeId = @ExchangeId and Actualrate2 = @Rate)
	return--Do nothing if actualrate as the same as the current one

declare @ActualRateUS float


BEGIN TRANSACTION

	BEGIN TRY
		if @ExchangeId = 2--update on RM exchange
			begin				
				select @ActualRateUS = 1/@Rate--get rate usd again
				
				update Exchange_Current with (rowlock, updlock)--update RM
				set Actualrate2 = @Rate
				where ExchangeId = @ExchangeId
				
				update Exchange_Current with (rowlock, updlock)--update other currency
				set Actualrate = @ActualRateUS * Actualrate2
				where ExchangeId <> @ExchangeId
				
				--Delete current rows in exchange table
				Delete Exchange with (rowlock, updlock)
				where UpdatedTime = @Date
				
				--Insert currency from current to history
				insert into Exchange(UpdatedTime, ExchangeID, Currency, ActualRate, ActualRate2, Creator,DepositPercent,WithdrawalPercent)
				select @Date, ExchangeId, Currency, ActualRate, ActualRate2, @CustId,DepositPercent,WithdrawalPercent
				from Exchange_Current with (nolock)
			end
		else
			begin
				select @ActualRateUS = Actualrate from Exchange_Current with (nolock) where ExchangeId = 3
				
				update Exchange_Current with (rowlock, updlock) 
				set Actualrate2 = @Rate, Actualrate = @Rate * @ActualRateUS
				where ExchangeId = @ExchangeId
				
				--Delete current rows in exchange table
				Delete Exchange with (rowlock, updlock)
				where UpdatedTime = @Date and ExchangeId = @ExchangeId
				--Insert changed currency into exchange table	
				insert into Exchange(UpdatedTime, ExchangeID, Currency, ActualRate, ActualRate2, Creator,DepositPercent,WithdrawalPercent)
				select @Date, ExchangeId, Currency, ActualRate, ActualRate2, @CustId,DepositPercent,WithdrawalPercent
				from Exchange_Current with (nolock)
				where ExchangeId = @ExchangeId
			End
	ENd TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		Select @ErrMsg = 'Update exchange rate is unsuccessful.', @ErrCode = 101
		RETURN		
	END CATCH

COMMIT TRANSACTION

DECLARE @LogData nvarchar(200)
SELECT @LogData = 'Update exchange rate of affiliate. ExchangeId:' + dbo.Aff_ToString(@ExchangeId) + ', Rate: ' + dbo.Aff_ToString(@Rate) + ', Date:' + dbo.Aff_ToString(@Date)

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog]
	@Creator=@CustId,		
	@TypeName= 'ExchangeRate',	
	@SPName=@SPName,
	@IP =@IP,
	@Details=@LogData
	


GO
GRANT VIEW DEFINITION ON [dbo].[DBA_Aff_ExchangeUpdate] TO [vnteam]