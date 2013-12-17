set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER PROC [dbo].[Aff_DomainAffUpd]
	@DomainID int,
	@DomainName nvarchar(50), 	
	@UserID int,		
	@IP nvarchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20121115@ThaiTran
Task : Update a AffDomain
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
BEGIN TRANSACTION
UPDATE [AffDomain] with (rowlock,updlock)
SET
	[ModifyDate] = getdate(),
    [DomainName] = @DomainName,              
    [Creator] = @UserID
WHERE DomainID = @DomainID

IF @@Error <> 0 
BEGIN
	ROLLBACK TRANSACTION
	Select @ErrMsg = N'Error occurs.Update unsuccessfully.', @Errcode=1001
	return
END 	

COMMIT TRANSACTION

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update DomainID:' + dbo.Aff_ToString(@DomainID)                     
                    + ' DomainName:' + dbo.Aff_ToString(@DomainName)                    

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @UserID,
	@Typename = 'AffDomain', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP


GO
GRANT EXECUTE ON [dbo].[Aff_DomainAffUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_DomainAffUpd] TO [vnteam]