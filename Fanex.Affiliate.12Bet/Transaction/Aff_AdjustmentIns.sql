Alter PROCEDURE [dbo].[Aff_AdjustmentIns]
	@Amount		money,	
	@AffID		int,
	@AdminID	int,	
	@transdesc	nvarchar(300)='',
	@transid	bigint OUTPUT,
	@ip			nvarchar(15)='',
	@language	varchar(2) = 'E',			
	@ErrCode	int = 0 OUTPUT,
	@ErrMsg		nvarchar(200) = '' OUTPUT
AS
SET NOCOUNT ON
-- DB: DB052.Affiliate_12Bet
/*
Creator : Vinh
Date : 2009-07-30
Task : Approve a payment request.

Input 
	0) @Amount Adjusment amount
	1) @AffId (For Double check) 
	2) @AdminID User insert transaction
	3) @transdesc Description of transaction
	4) @transid transid for this Adjustment
	5) @userid ID of Admin update this Adjustment
	6) @IP IP update Adjustment
   Output
	1) @ErrCode:
		= 0: Transaction recorded successfully.
		> 0: Specific Error.
	2) @ErrMsg: Error description.
Revisions:

*/
SET NOCOUNT ON
--SELECT @ErrCode = 101, @ErrMsg = 'do it later..'
EXEC [dbo].[Aff_Con_CheckPermission]
	@custid=@AdminID,@funcname='[Payment]',--User the same with payment
	@System = 'AFFILIATE',
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output

If @ErrCode <> 0
	RETURN

IF @Amount = 0
BEGIN
	Select @ErrMsg = 'Sorry, amount is invalid.', 
			@ErrCode = 30001
	return
END

if(not exists(select 1 from AffInfo(nolock) where AffID=@AffID ))
begin
	SELECT @ErrMsg ='Invalid Affiliate!', @ErrCode = 1001
	RETURN
end


Declare @Currency int, @AffRate float, @Status varchar(30), @IsClosed bit

select @Currency = b.Currency, @AffRate = e.ActualRate, @Status = Status, @IsClosed = IsClosed
from AffInfo b with (nolock)
	inner join Exchange_Current e with (nolock) on b.Currency = e.ExchangeID
where b.AffID = @AffID

--Check Data
if @Currency is null--cannot find Affiliate 
Begin
	Select @ErrMsg = 'Invalid Affiliate', 
		@ErrCode = 30002
	return
End

if @Status <> 'Approved'
Begin
	Select @ErrMsg = 'Sorry, You cannot do adjustment because this Affiliate is not approved yet.', 
		@ErrCode = 30003
	return
End

if @IsClosed = 1
Begin
	Select @ErrMsg = 'Sorry, You cannot do adjustment because this Affiliate is closed.', 
		@ErrCode = 30004
	return
End


--EXEC [dbo].Aff_SelRefNo @RefNo = @RefNo OUTPUT, @RefName = 'AFF_Adj'

insert into AffTrans([AffID]
	,[TransDate]
	,[CompletedDate]
	,[Amount]
	,[Status]
	,[Description]
	,[Creator]
	,[Currency]
	--This section no need to update ActualRate(Only apply for Payment Request)
	,[TransType]
	--,[RefID]
	,[AffExRate])
values(
	@AffID,
	Getdate(),
	Getdate(),
	@Amount,
	'Completed',
	@transdesc,
	@AdminID,
	@Currency, --Default for USD currency
	203,--Adjustment TransType
	--@RefNo,
	@AffRate
)


if @@ERROR <> 0
begin
	Select @ErrMsg = 'This transaction is unsuccessful.', 
		@ErrCode = 4005	
	return
end

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Adjustment Insert. Amount = ' + dbo.Aff_ToString(@Amount)

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @AdminID,
	@AffID = @AffID,
	@Typename = 'Adjustment', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP

GO
GRANT EXECUTE ON [dbo].[Aff_AdjustmentIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AdjustmentIns] TO [VNTeam]