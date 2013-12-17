ALTER PROC [dbo].[Aff_ExchangeUpdate]
	@CustId int,
	@ExchangeId int,
	@Rate float,
	@RateType bit = 0,
	@IP varchar(20),
	@language varchar(2) = 'E',	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: 20091010@Johnny
	Task : Update exchange rate
	DB: DB052.Affiliate_12BET
	Revisions:
		- 20091014@Johnny initialize
		- Peter@20120116 : Add Buying Rate for Aff Payout
		http://ccs.nexcel.vn/viewtopic.php?f=6&t=8194
	Param's Explanation:
		@RateType = 0: ActualRate
		@RateType = 1: BuyingRate
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
	@custid=@CustId,@funcname='[AffEx.Rate]',
	@System = 'AFFILIATE',
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output
	
If @ErrCode <> 0
	RETURN	
	
if @ExchangeId = 3
begin
	select @ErrCode = 101, @ErrMsg = 'You cannot edit rate of USD'
	return
end

if Exists(select 1 from Exchange_Current with (nolock) where ExchangeId = @ExchangeId AND 
	( (Actualrate2 = @Rate AND @RateType = 0) OR  (BuyingRate2 = @Rate AND @RateType = 1)))
	
	return --Do nothing if actualrate as the same as the current one

declare @RateUS float
declare @CurrDate smalldatetime
select @CurrDate = convert(varchar(10),current_timestamp,120)

BEGIN TRANSACTION

	BEGIN TRY
		if @ExchangeId = 2--update on RM exchange
			begin	
				if @RateType = 0
					begin		
						select @RateUS = 1/@Rate--get rate usd again
						
						update Exchange_Current with (rowlock, updlock)--update RM
						set Actualrate2 = @Rate
						where ExchangeId = @ExchangeId
						
						update Exchange_Current with (rowlock, updlock)--update other currency
						set Actualrate = @RateUS * Actualrate2
						where ExchangeId <> @ExchangeId
						
					end
				else
					begin
						select @RateUS = 1/@Rate--get rate usd again
				
						update Exchange_Current with (rowlock, updlock)--update RM
						set BuyingRate2 = @Rate
						where ExchangeId = @ExchangeId
						
						update Exchange_Current with (rowlock, updlock)--update other currency
						set BuyingRate = @RateUS * BuyingRate2
						where ExchangeId <> @ExchangeId
						
					end
				
				--Delete current rows in exchange table
				Delete Exchange with (rowlock, updlock)
				where UpdatedTime = @CurrDate
				
				--Insert currency from current to history
				insert into Exchange(UpdatedTime, ExchangeID, Currency, ActualRate,ActualRate2,BuyingRate, BuyingRate2, Creator,DepositPercent,WithdrawalPercent)
				select @CurrDate, ExchangeId, Currency,ActualRate,ActualRate2, BuyingRate, BuyingRate2, @CustId,DepositPercent,WithdrawalPercent
				from Exchange_Current with (nolock)
			end
		else
			begin
			if @RateType = 0
				begin	
					select @RateUS = Actualrate from Exchange_Current with (nolock) where ExchangeId = 3
					
					update Exchange_Current with (rowlock, updlock) 
					set Actualrate2 = @Rate, Actualrate = @Rate * @RateUS
					where ExchangeId = @ExchangeId
				
				end
			else
				begin
					select @RateUS = BuyingRate from Exchange_Current with (nolock) where ExchangeId = 3
					
					update Exchange_Current with (rowlock, updlock) 
					set BuyingRate2 = @Rate, BuyingRate = @Rate * @RateUS
					where ExchangeId = @ExchangeId										
				end	
				
				--Delete current rows in exchange table
				Delete Exchange with (rowlock, updlock)
				where UpdatedTime = @CurrDate and ExchangeId = @ExchangeId
				--Insert changed currency into exchange table	
				insert into Exchange(UpdatedTime, ExchangeID, Currency, ActualRate,ActualRate2,BuyingRate, BuyingRate2, Creator,DepositPercent,WithdrawalPercent)
				select @CurrDate, ExchangeId, Currency, ActualRate,ActualRate2,BuyingRate, BuyingRate2, @CustId,DepositPercent,WithdrawalPercent
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
SELECT @LogData = 'Update exchange rate of affiliate. ExchangeId:' + dbo.Aff_ToString(@ExchangeId) + ', Rate: ' + dbo.Aff_ToString(@Rate)

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog]
	@Creator=@CustId,		
	@TypeName= 'ExchangeRate',	
	@SPName=@SPName,
	@IP =@IP,
	@Details=@LogData
GO
GRANT EXEC ON [dbo].[Aff_ExchangeUpdate] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ExchangeUpdate] TO [VNTeam]