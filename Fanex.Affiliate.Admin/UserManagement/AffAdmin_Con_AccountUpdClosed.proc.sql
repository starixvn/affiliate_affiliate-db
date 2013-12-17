ALTER PROCEDURE [dbo].[AffAdmin_Con_AccountUpdClosed]
	@CustID int,
	@Closed bit,
	@UserID int,
	@Language varchar(5) = 'en-US',
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT
AS
/*
create AccAdmin from existed Admin
DB03.bodb02(Move this SP from DB02.bodb02 to DB03.bodb02) --> DB052.Affiliate_ZZun
Revisions:
	- VinhTrinh@20100507: update closed field in table AdminUser(instead of CustInfo)
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun	
*/
SET NOCOUNT ON

EXEC [dbo].[AffAdmin_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@System='AFFILIATE',@ErrCode=@ErrCode output
If @ErrCode <> 0
	RETURN
--end

update AdminUser with (ROWLOCK) 
set Closed = @Closed,
	LoginCount = (case when @Closed = 0 then 0 else LoginCount end)
where custid = @CustID

DECLARE @SPName varchar(50), @LogData nvarchar(200)
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = 'Update AFFILIATE for CustID: ' + dbo.Aff_ToString(@custid) + ' closed: ' + case @closed when 0 then 'open' else 'closed' end


EXEC [dbo].[Aff_WriteLog]
		@Creator=@UserID,	
		@AffID=@CustID,
		@Typename= 'UserControl',	
		@SPName=@SPName ,		
		@IP =@IP,
		@Details=@LogData	
		



