USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_AdjustmentIns]  
	@LicenseeID	INT,
	@Amount	MONEY,
	@AffID	INT,
	@AdminID INT,
	@Description NVARCHAR(300) = '',
	@ip	NVARCHAR(15) = '',
	@Language VARCHAR(5) = 'en-US',
	@ErrCode INT = 0 OUTPUT
AS

/*  
	Creator: Vinh  
	Date: 2009-07-30  
	Task: Approve a payment request.
	DB: DBAFF.Affiliate_Athena000

	Revisions: 
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
*/

BEGIN
	SET NOCOUNT ON  
  
	EXEC [dbo].[Aff_Con_CheckPermission]  
		@LicenseeID = @LicenseeID,
		@custid=@AdminID,  
		@funcname='[Payment]',--User the same with payment  
		@System = 'AFFILIATE',  
		@ErrCode=@ErrCode OUTPUT
  
	If @ErrCode <> 0  
		RETURN  
  
	IF @Amount = 0  
	BEGIN  
		Select @ErrCode = 1011
		return  
	END 
  
	if(not exists(select 1 from AffInfo(nolock) where AffID=@AffID ))  
	begin  
		SELECT @ErrCode = 1006  
		RETURN  
	end  
  

	Declare @AffCurrency varchar(5), @AffCurrencyCode varchar(5), @SysCurrency varchar(5), @SysExRate float, @Status varchar(30), @IsClosed bit, @MaxAmount money
  
	select @AffCurrency = b.Currency,  @Status = Status, @IsClosed = IsClosed, @AffCurrencyCode = e.Code
	from AffInfo b with (nolock)   
		inner join Exchange e (nolock) on e.ExchangeId=b.currency  
	where AffID = @AffID  

	SET @MaxAmount = (Select SValue From SystemSettings (nolock) where SName = 'AFF_MaximumAdjustment' + @AffCurrencyCode)

	--Check Data 
	if (@AffCurrency is null or ABS(@Amount) > @MaxAmount)
	Begin  
		Select @ErrCode = 1011 
		return  
	End 
 
	if @Status <> 'Approved'  
	Begin  
		Select @ErrCode = 1013
		return  
	End  
  
	if @IsClosed = 1  
	Begin  
		Select @ErrCode = 1014
		return  
	End  
  
	declare @CurrentDate datetime  
	Set @CurrentDate=current_timestamp  
  
	select @SysCurrency=dbo.Aff_GetSystemCurrencyID()  
	select @SysExRate=dbo.Aff_GetExchangeRate(@AffCurrency,@SysCurrency, default)  
  
	insert into AffTrans
	(
		[AffID]  
		,[TransDate]  
		,[CompletedDate]  
		,[Amount]  
		,[Status]  
		,[Description]  
		,[Creator]  
		,[AffCurrency]  
		,[SysCurrency]  
		,[SysExRate]   
		,[TransType]   
		,[RefID]
	)  
	values
	(  
		@AffID,  
		@CurrentDate,  
		@CurrentDate,  
		@Amount,  
		'Completed',  
		@Description,  
		@AdminID,  
		@AffCurrency,  
		@SysCurrency,  
		@SysExRate,  
		203,--Adjustment TransType  
		0
	)
	
	if @@ERROR <> 0  
	begin  
		Select @ErrCode = 1005   
		return  
	end      

	 -- Recalculate BF in AffInfo table  
	update AffInfo with (rowlock, updlock)
	Set BF=dbo.Aff_GetAffBalance (AffID)  
	where AffID=@AffID 
 
	--Write log  
	declare @SPName varchar(50), @Detail nvarchar(4000)   
	select @SPName = OBJECT_NAME(@@PROCID)  
	select @Detail = 'Modify Balance Brought Forward. Amount = ' + dbo.Aff_ToString(@Amount)   
  
	EXEC [dbo].[Aff_WriteLog]   
		@Creator = @AdminID,  
		@AffID = @AffID,  
		@Typename = 'Adjustment', -- refer to table LogType  
		@SPName = @SPName,  
		@Details = @Detail,  
		@IP = @IP
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_AffiliateSel] TO [vnteam]