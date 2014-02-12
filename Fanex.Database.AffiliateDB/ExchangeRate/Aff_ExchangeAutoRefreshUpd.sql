ALTER PROCEDURE [dbo].[Aff_ExchangeAutoRefreshUpd]
	@CustId int,
	@ExchangeId int,	
	@IP varchar(20),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: 20110223@Viet
	Task : Enable/disable auto refresh rate (daily)
	DB: DB052.Affiliate_ZZun
	Revisions:
		- 20110223@Viet: initialize SP
		
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
	@custid=@CustId,@funcname='[AffEx.Rate]',
	@System = 'AFFILIATE',
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output
	
If @ErrCode <> 0	RETURN	

UPDATE exchange with(rowlock, updlock)
SET isautorefresh = ~isnull(isautorefresh,0)
WHERE ExchangeId = @ExchangeId
		
DECLARE @LogData nvarchar(200), @SPName varchar(50)
SELECT @LogData = 'Enable/disable auto refresh rate (daily). ExchangeId:' + dbo.Aff_ToString(@ExchangeId)
	   ,@SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog]
	@Creator=@CustId,		
	@TypeName= 'ExchangeRate',	
	@SPName=@SPName,
	@IP =@IP,
	@Details=@LogData
	
GO
GRANT EXEC ON [dbo].[Aff_ExchangeAutoRefreshUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ExchangeAutoRefreshUpd] TO [VNTeam]