USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Acc_ExchangeUpd]    Script Date: 05/04/2010 04:47:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Acc_ExchangeUpd]
	@exchangeid int,
	@actualrate float,
	@minbet float,
	@UserID int,
	@IP nvarchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

/*
Created: ?
Task : Update ex rate

DB: DB02.bodb02
Original: 

Revisions: 
	- 20091025@Peter: Call SP update Aff's ex.Rate
	- 20091027@Daniel: Change to writelog to table userlog_exchange instead
	- 20100504@Peter :  Remove the calling to SP [DB052].[Affiliate_12BET].[dbo].[Aff_AccUpdateExchange]
	                    coz it will be updated on Affiliate Admin    

Param's Explanation:
• @actualrate: new rate to update
• @minbet: update new minbet 


*/

SET NOCOUNT ON

--Check permission for account site: @phuc20080213
EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[ExchangeRate]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end


declare @LogData nvarchar(200)
declare @oldactualrate float, @oldminbet float

select @oldactualrate =  actualrate, @oldminbet = minbet 
from exchange with (nolock) where exchangeid=@exchangeid

UPDATE exchange SET 
		actualrate=@actualrate, 
		minbet=@minbet,
		minbetlive=@minbet
WHERE exchangeid=@exchangeid

/*EXEC [DB052].[Affiliate_12BET].[dbo].[Aff_AccUpdateExchange]
	@UserID=@UserID,
	@ExchangeId=@exchangeid,
	@Rate=@actualrate,
	@IP ='127.0.0.1',
	@ErrCode = @ErrCode OUTPUT,
	@ErrMsg= @ErrMsg OUTPUT*/

Select @LogData = 'update exchange ' + convert(varchar(20), @ExchangeID) + ', with new rate = '
		+ convert(varchar(20), @actualrate) + ', minbet = ' + convert(varchar(20), @minbet) 
		+ ' (old rate = ' + convert(varchar(20), @oldactualrate) + ', old minbet = ' + convert(varchar(20), @oldminbet) + ')'

EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_ExchangeRate
	@UserID = @UserID, 
	@ExchangeID = @exchangeid, 
	@actualrate = @actualrate, 
	@IP = @IP, 
	@Doing = @LogData

GO

GRANT EXECUTE ON [dbo].[Acc_ExchangeUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeUpd] TO [ITTim]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeUpd] TO [ITVivi]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeUpd] TO [vnteam]