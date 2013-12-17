ALTER PROCEDURE [dbo].[AffAdmin_DomainMemDel]
	@DomainID int OUTPUT,
	@UserID int,	
	@IP nvarchar(15)='',
	@ErrCode int = 0 OUTPUT
AS
/*
Created: 20121115@ThaiTran
Task : Del a AffDomain
DB: DB052.Affiliate_12BET
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
	@custid=@UserID,@funcname='[Domain]',
	@System = 'AFFILIATE',
	@ErrCode=@ErrCode output
	
If @ErrCode <> 0
	RETURN
-----------------------------------------------
If Exists(select 1 from AffDomainControl nolock where MemberDomainID = @DomainID)
Begin
	select @ErrCode = 2003--This member domain has been used!
	return
End

Declare @DomainName nvarchar(50)
Select @DomainName = DomainName from [MemberDomain] nolock where DomainID = @DomainID

delete [MemberDomain]
where DomainID = @DomainID
print 'test'

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Delete Member Domain DomainID:' + dbo.Aff_ToString(@DomainID)                     
                    + ' DomainName:' + dbo.Aff_ToString(@DomainName)                    					

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @UserID,
	@Typename = 'AffDomain', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP

GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainMemDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_DomainMemDel] TO [vnteam]