ALTER PROC [dbo].[AffAdmin_DomainMemUpd]
	@DomainID int,
	@DomainName nvarchar(50), 	
	@UserID int,	
	@IP nvarchar(15)='',
	@ErrCode int = 0 OUTPUT
AS
/*
Created: 20130822@Johnny
Task : Update a MemDomain
DB: 
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
	@custid=@UserID,@funcname='[Domain]',
	@System = 'AFFILIATE',
	@ErrCode=@ErrCode output
	
If @ErrCode <> 0
	RETURN

IF Exists(Select 1 from [MemberDomain] nolock WHERE [DomainName] = @DomainName AND DomainID <> @DomainID)
BEGIN
	SELECT @ErrCode = 2004
	return
END

-----------------------------------------------
BEGIN TRANSACTION
UPDATE [MemberDomain] with (rowlock,updlock)
SET
	[ModifyDate] = getdate(),
    [DomainName] = @DomainName,              
    [Creator] = @UserID    
WHERE DomainID = @DomainID

IF @@Error <> 0 
BEGIN
	ROLLBACK TRANSACTION
	Select @Errcode=502--Error occurs.Update unsuccessfully.
	return
END 	

COMMIT TRANSACTION

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update Member Domain DomainID:' + dbo.Aff_ToString(@DomainID)                     
                    + ' DomainName:' + dbo.Aff_ToString(@DomainName)                    

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @UserID,
	@Typename = 'AffDomain', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP

GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainMemUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_DomainMemUpd] TO [vnteam]