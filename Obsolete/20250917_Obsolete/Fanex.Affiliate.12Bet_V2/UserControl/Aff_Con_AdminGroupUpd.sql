
ALTER PROCEDURE  [dbo].[Aff_Con_AdminGroupUpd]
	@CustID int,
	@UserID int,
	@GroupID int,
	@IP varchar(15) = '',
	@Language varchar(2)= 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*called by sp Aff_Con_AdminUpd */
/*DB03.bodb02*/--->/*DB052.Affiliate_12BET*/

/*
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
	-- 20121220@Dan: Change linked server from DB052.Affiliate_12BET-->DBAFF12BET.Affiliate_12BET	
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
			
			EXEC [dbo].[Aff_WriteLog]
					@Creator=@UserID,	
					@AffID=@CustID,
					@Typename= 'UserControl',	
					@SPName=@SPName ,		
					@IP =@IP,
					@Details=@LogData	
		
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


End


GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_AdminGroupUpd] TO [vnteam]
go
GRANT EXECUTE ON [dbo].[Aff_Con_AdminGroupUpd] TO [bodbAdminNet]