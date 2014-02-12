/****** Object:  Stored Procedure dbo.Aff_Con_AdminGroupUpd    Script Date: 7/11/2009 1:17:56 PM ******/
ALTER PROCEDURE  [dbo].[Aff_Con_AdminGroupUpd]
	@CustID int,
	@UserID int,
	@GroupID int,
	@IP varchar(15) = '',
	@Language varchar(5)= 'en-US',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*called by sp Aff_Con_AdminUpd */
/*DB03.bodb02*/--->/*DB052.Affiliate_ZZun*/

/*
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
*/

SET NOCOUNT ON
Begin
IF EXISTS(SELECT 1 FROM AffGroupInfo with(nolock) where groupid=@groupid)
	BEGIN 
		IF EXISTS(SELECT 1 FROM AdminUser ac with(nolock) WHERE custid=@custid and groupid <> @groupID) 
		BEGIN
			BEGIN TRANSACTION
				UPDATE AdminUser with (ROWLOCK, UPDLOCK) SET groupid=@groupid WHERE custid = @custid							
			COMMIT TRANSACTION
			
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
							when 'en-US' then N'This groupid '+convert(varchar(20),@groupid) +' is invalid.'
							when 'zh-CN' then N'This groupid '+convert(varchar(20),@groupid) +' is invalid.'
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