ALTER PROCEDURE [dbo].[Aff_WriteLog]
	@Creator int,
	@AffID int =0,
	@Typename varchar(50),	
	@RefNo bigint = null OUTPUT,
	@SPName varchar(50),
	@IP varchar(20) =NULL,
	@Details nvarchar(4000)
AS
/*
Created: 20090714@VietHoang
Task : Write Log for affiliate
DB: DB052.Affiliate_ZZun
Original:

Revisions:
*/
SET NOCOUNT ON
begin transaction
 begin try
	if(@RefNo is null or @RefNo=0) 
	begin    
		UPDATE Ref with (Rowlock, Updlock)
		SET  @RefNo=refno=refno+1  
		WHERE RefName = 'Log'   
	end

	INSERT INTO dbo.UserLog (RefNo, TypeID, Creator, AffID, LoggedDate, SPName, IP, Details)
	VALUES (@RefNo,dbo.Aff_GetLogType(@Typename) , @Creator, @AffID, CURRENT_TIMESTAMP, @SPName, @IP, @Details)	
	 end try
	 begin catch
			rollback transaction
			return
	  end catch 
commit transaction

GO
GRANT EXECUTE ON [dbo].[Aff_WriteLog] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Aff_WriteLog] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_WriteLog] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_WriteLog] TO [VnTeam]