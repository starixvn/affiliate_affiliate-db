ALTER PROCEDURE [dbo].[AffAdmin_CountryDel]
    @Updatedby int ,
    @IDList NVARCHAR(max),
    @IP NVARCHAR(15)='',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130122@Joseph
Task : [description of SP]
DB: DB052.Affiliate_MYM
Original:

Revisions:
20151221@Francis: Support SSO


Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Delete unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

DECLARE @LicenseeID INT
SELECT @LicenseeID = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName LIKE 'LicenseeID'

EXEC [dbo].[Aff_Con_CheckPermission]
	 @LicenseeID = @LicenseeID,
        @custid=@Updatedby,@funcname='[SystemSettings]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
    
If @ErrCode <> 0
    RETURN
    

delete [dbo].[Country]
where CountryID in (select val from dbo.strsplit(@IDList, ',') )

declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Delete Country. IDList=' + isnull(@IDList,0)


EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'Country', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end
GO
