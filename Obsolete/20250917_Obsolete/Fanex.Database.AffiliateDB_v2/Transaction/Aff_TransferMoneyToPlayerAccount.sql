ALTER PROC [dbo].[Aff_TransferMoneyToPlayerAccount]	
   @PlayerUserName varchar(30),
   @BalanceUserName varchar(30),
   @PlayerCurrency varchar(5),
   @Amount money,
   @SystemName varchar(30),
   @RefID bigint,
   @IP varchar(15) = '',
   @UserID int,
   @TransID1 bigint =0 OUTPUT,
   @TransID2 bigint =0 OUTPUT,
   @Language varchar(5) = 'en-US',
   @ErrCode int = 0 OUTPUT,
   @ErrMsg nvarchar(200) = '' OUTPUT
AS
-- DB: DB02.BODB02
/*
Creator : Peter@20090910
Task : Update Payment status ('Approved','Rejected','Cancelled')
 
When AffAdmin approve payment, update payment status into completed and insert 2 transactions into bettrans table(IBC Database) 						
						
CustId	TransID	Actual_Stake	Winlost	Currency	ExchangeRate	Bettype
memHK$	111	0	750	5	2.3	107
DummyHK$	112	750	0	5	2.3	107


Input 
    1) @AffId (For Double check) 
    2) @TransID (This ID is get from "B. deposit/withdrawal for approved" Output TransID )    
    3) @AdminDesc Description for this payment from Admin
    4) @AffDesc Description visible for Affiliate
    5) @userid ID of Admin update this payment
    6) @IP IP update payment
   
Revisions:
	- 20100209@Johnny: Check the correction of IBCCustId in AffPayout with Player_Username in AffDetail table. If they donot match, Payment will not be done
	- 20100413@Peter : Update ExRate for MemberCurrency is the exchange rate of table DB02.bodb02.dbo.Exchange for the aprroved date (not from AffPayout data)
	                   to avoid the bug on balance up procedure
	- 20100413@Peter : Update StatusID (new column) in bettrans table
	                   Approved have StatusId=132  
	- 20101102@Henry: Change column transid from INT to BIGINT                   
	- 20101228@Henry: change bettype to new range                   

• @ErrCode:
	= 0: Transaction recorded successfully.
	> 0: Specific Error.
• @ErrMsg: Error description.
*/
SET NOCOUNT ON


--Check whether this is pending payment request 

Declare  @Status nvarchar(50),@BetType int,@Player_IBCCustID int,@AffPayout money
       , @Player_Currency int,@Player_ExRate float
      , @BalanceCustID int,@Player_CurrencyID int,@PlayerCurrencyName varchar(5), @bal_varname varchar(50)
      ,@Player_IBCUserName varchar(50),@Player_Recommend int, @Player_MRecommend int, @Player_SRecommend int
     ,@Balance_Recommend int, @Balance_MRecommend int, @Balance_SRecommend int,@Balance_CurrencyID int,@StatusID tinyint
     

Select @Status = 'Approved',@BetType=21006,@StatusID=132



Select @Player_IBCCustID = CustId,@Player_IBCUserName=username,@Player_Recommend=recommend, @Player_MRecommend=mrecommend, @Player_SRecommend=srecommend
	  ,@Player_CurrencyID=currency
From Customer c with(nolock) 
where c.username2 =@SystemName + '$' + @PlayerUserName


If(@Player_IBCCustID is null)
BEGIN
   Select @ErrMsg = case @language 
						when 'en-US' then N'Invalid player user name account.'
						when 'zh-TW' then N'Invalid player user name account.'	
						when 'zh-CN' then N'Invalid player user name account.'		
						when 'es-ES' then N'Invalid player user name account.'
						when 'vi-VN' then N'Invalid player user name account.'
						when 'id-ID' then N'Invalid player user name account.'
						else  N'Invalid player user name account.'		
					end, 
		@ErrCode = 4000
	return
END

select @Player_ExRate=actualrate,@PlayerCurrencyName=currency
from Exchange (nolock)
Where exchangeid=@Player_CurrencyID and code=@PlayerCurrency

--print @Player_CurrencyID
--print @PlayerCurrency
if(@PlayerCurrencyName is null)
begin
			Select @ErrMsg = case @language 
								when 'en-US' then 'Invalid Player''s Currency.'
								when 'zh-TW' then N'Invalid Player''s Currency.'
								when 'zh-CN' then N'Invalid Player''s Currency.'
								else  N'Invalid Player''s Currency.'			
							end, 
			@ErrCode = 4002
end


select @BalanceCustID=custid,@Balance_Recommend=recommend, @Balance_MRecommend=mrecommend, @Balance_SRecommend=srecommend,
		@Balance_CurrencyID=currency
from CustInfo (nolock)
where username=@BalanceUserName


IF (@BalanceCustID is null or @Balance_CurrencyID<>@Player_CurrencyID)
BEGIN
           Select @ErrMsg = case @language 
								when 'en-US' then 'Invalid Balance Account.'
								when 'zh-TW' then N'Invalid Balance Account.'
								when 'zh-CN' then N'Invalid Balance Account.'
								else  N'Invalid Balance Account.'			
							end, 
			@ErrCode = 4001
	return
END

declare @TransDate datetime

BEGIN TRY
    
    Select @TransDate=current_timestamp
    --Add money to player
    INSERT INTO bettrans 
	(custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, winlostdate, 
	 creator,recommend,mrecommend,srecommend,currency, actualrate, currencyName, ruben, status,ip,StatusID)
    VALUES 
    (@Player_IBCCustID, @Player_IBCUserName, @RefID,@TransDate, 0, @BetType, 'Approve payout Request', abs(@Amount), 0, convert(nvarchar(10), @TransDate, 120), 
     @UserID, @Player_Recommend, @Player_MRecommend, @Player_SRecommend, @Player_CurrencyID, @Player_ExRate, @PlayerCurrencyName, 1, @Status,@ip,@StatusID)
     
    Select @TransID1=SCOPE_IDENTITY()
     --Deduct balance account
     INSERT INTO bettrans 
	(custid, username, refno, transdate, matchid, bettype, transdesc, winlost, actual_stake, winlostdate, 
	 creator,recommend,mrecommend,srecommend,currency, actualrate, currencyName, ruben, status,ip,StatusID)
    VALUES 
    (@BalanceCustID, @BalanceUserName, @RefID,@TransDate, 0, @BetType, 'Approve payout Request', 0, abs(@Amount), convert(nvarchar(10), @TransDate, 120), 
     @UserID, @Balance_Recommend, @Balance_MRecommend, @Balance_SRecommend, @Player_CurrencyID, @Player_ExRate, @PlayerCurrencyName, 1, @Status,@ip,@StatusID)
    Select @TransID2=SCOPE_IDENTITY()     
   
END TRY

BEGIN CATCH
	delete bettrans
    where transid in (@TransID1,@TransID2)
    Select @ErrMsg = case @language 
							when 'en-US' then 'Update transaction failed.'
							when 'zh-TW' then N'Update transaction failed.'
							when 'zh-CN' then N'Update transaction failed.'
							when 'TH' then N'Update transaction failed.'
							when 'ES' then N'Update transaction failed.'
							else  N'Update transaction failed.'		
						end,
		@ErrCode = 4003
	return
    RETURN
END CATCH
GO
GRANT EXECUTE ON [dbo].[Aff_TransferMoneyToPlayerAccount] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_TransferMoneyToPlayerAccount] TO [vnteam]
GO