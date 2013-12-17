ALTER PROCEDURE [dbo].[Aff_DomainControlUpd]
	@ID int,
	@AffDomainID int,
	@12BetDomainID int,
	@MarketID nvarchar(10),
	@Status bit = 1,	
	@UserID int,	
	@IP nvarchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20121115@Johnny.Trinh
Task : Update Domain control info
DB: DB052.Affiliate_12BET
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
	@custid=@UserID,@funcname='[Domain]',
	@System = 'AFFILIATE',
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output
	
If @ErrCode <> 0
	RETURN
-----------------------------------------------
If Exists(select 1 from AffDomainControl nolock where ID <> @ID and AffDomainID = @AffDomainID and [12BetDomainID] = @12BetDomainID and MarketID = @MarketID)
Begin
	select @ErrCode = 1001,
			@ErrMsg = 'Your domain setting is duplicate with other setting. Please check!'
	return
End

BEGIN TRANSACTION
Update [AffDomainControl] with (rowlock, updlock)
set
    [AffDomainID]	= @AffDomainID
	,[12BetDomainID]= @12BetDomainID
    ,[MarketID]		= @MarketID
    ,[ModifyDate]	= current_timestamp
    ,[Status]		= @Status
	,[Creator]		= @UserID
where ID = @ID

IF @@ERROR <> 0
BEGIN
	ROLLBACK TRANSACTION
	Select @ErrMsg = 	N'Error occurs when update data.', @ErrCode = 1002
	return
END

COMMIT TRANSACTION

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update AffDomainID:' + dbo.Aff_ToString(@AffDomainID)                     
                    + ' 12BetDomainID:' + dbo.Aff_ToString(@12BetDomainID)                    
					+ ' MarketID:' + dbo.Aff_ToString(@MarketID)                    

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @UserID,
	@Typename = 'AffDomainControl', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP



GO
GRANT EXECUTE ON [dbo].[Aff_DomainControlUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_DomainControlUpd] TO [vnteam]