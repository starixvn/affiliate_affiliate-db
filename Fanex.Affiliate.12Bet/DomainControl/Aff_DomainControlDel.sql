ALTER PROCEDURE [dbo].[Aff_DomainControlDel]
	@Id int,
	@UserID int,	
	@IP nvarchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20121115@Johnny.Trinh
Task : Add a new AffDomainControl
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
declare @AffDomainID int, @12BetDomainID int, @MarketID nvarchar(10)

select @AffDomainID = AffDomainID, @12BetDomainID = [12BetDomainID], @MarketID = MarketId
from [AffDomainControl]
where Id = @Id

delete [AffDomainControl]
where Id = @Id

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Delete AffDomainID:' + dbo.Aff_ToString(@AffDomainID)                     
                    + ' 12BetDomainID:' + dbo.Aff_ToString(@12BetDomainID)                    
					+ ' MarketID:' + dbo.Aff_ToString(@MarketID)                    

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @UserID,
	@Typename = 'AffDomainControl', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP

GO
GRANT EXECUTE ON [dbo].[Aff_DomainControlDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_DomainControlDel] TO [vnteam]