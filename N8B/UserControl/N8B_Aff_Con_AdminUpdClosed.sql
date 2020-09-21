/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
Alter PROCEDURE [dbo].[Aff_Con_AdminUpdClosed]
	@CustID int,
	@Closed bit,
	@UserID int,
	@Language varchar(2) = 'E',
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT	
AS
/*
create AccAdmin from existed Admin
DB: DBAFFN8B-Affiliate_N8B	

Revisions:
	--DB03.bodb02(Move this SP from DB02.bodb02 to DB03.bodb02) --> DB052.Affiliate_12BET
	-- VinhTrinh@20100507: update closed field in table affiliate_user(instead of CustInfo)
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET	
	-- 20200220@Percy: Initialize SP for DBAFFN8B-Affiliate_N8B [RedmineID: #128775]
*/
SET NOCOUNT ON

EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

update Affiliate_User with (ROWLOCK) set Closed = @Closed
where custid = @CustID

DECLARE @SPName varchar(50), @LogData nvarchar(200)
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = 'Update AFFILIATE for CustID: ' + dbo.Aff_ToString(@custid) + ' closed: ' + case @closed when 0 then 'open' else 'closed' end

GO