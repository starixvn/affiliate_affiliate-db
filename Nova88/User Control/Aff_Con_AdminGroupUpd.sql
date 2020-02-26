/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE  [dbo].[Aff_Con_AdminGroupUpd]
	@CustID int,
	@UserID int,
	@GroupID int,
	@IP varchar(15) = '',
	@Language varchar(2)= 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

/*
	DB: DBAFFN8G-Affiliate_N8G
	Revisions:

	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
	-- 20121220@Dan: Change linked server from DB052.Affiliate_12BET-->DBAFF12BET.Affiliate_12BET
	-- 20200220@Percy: Initialize SP for DBAFFN8G-Affiliate_N8G [RedmineID: #128775]	
*/

SET NOCOUNT ON
Begin
IF EXISTS(SELECT 1 FROM AffGroupInfo with(nolock) where groupid=@groupid)
	BEGIN 
		IF EXISTS(SELECT 1 FROM affiliate_user ac with(nolock) WHERE custid=@custid and groupid <> @groupID) 
		BEGIN
			
			UPDATE affiliate_user with (ROWLOCK, UPDLOCK) SET groupid=@groupid WHERE custid = @custid							
			
			
			DECLARE @SPName varchar(50), @LogData nvarchar(200)
			select @SPName = OBJECT_NAME(@@ProcID)

			SELECT @LogData = 'Update Group for Admin custid:' + dbo.Aff_ToString(@custid) + ' GroupID:' + dbo.Aff_ToString(@GroupID)
		END
	END
	ELSE
	BEGIN
		SELECT @ErrMsg =  case @Language
							when 'E' then N'This groupid '+convert(varchar(20),@groupid) +' is invalid.'
							when 'CS' then N'This groupid '+convert(varchar(20),@groupid) +' is invalid.'
							when 'J' then N'This groupid '+convert(varchar(20),@groupid) +' is invalid.'
							else N'This groupid '+convert(varchar(20),@groupid) +' is invalid.'
						end, @ErrCode = 103
		return 
	END
END
GO