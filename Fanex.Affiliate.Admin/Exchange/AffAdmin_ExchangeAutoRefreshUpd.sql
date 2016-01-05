USE [Affiliate_Athena000]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[AffAdmin_ExchangeAutoRefreshUpd]
    @UserId int,
    @ExchangeId int,    
    @IP varchar(20),
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
    Created: 20110223@Viet
    Task : Enable/disable auto refresh rate (daily)
    DB: DB052.Affiliate_MYM
    Revisions:
        - 20110223@Viet: initialize SP
        - 20151031@Victor: Implement SSO for Internal Admin
        
*/
SET NOCOUNT ON
--Check permission-----------------------------
DECLARE @LicenseeID INT
SELECT @LicenseeID = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName LIKE 'LicenseeID'

EXEC [dbo].[Aff_Con_CheckPermission]
	@LicenseeID = @LicenseeID,
    @CustId=@UserId,
    @FuncName='[AffEx.Rate]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0    RETURN    

UPDATE exchange with(rowlock, updlock)
SET isautorefresh = ~isnull(isautorefresh,0)
WHERE ExchangeId = @ExchangeId
        
DECLARE @LogData nvarchar(200), @SPName varchar(50)
SELECT @LogData = 'Enable/disable auto refresh rate (daily). ExchangeId:' + dbo.Aff_ToString(@ExchangeId)
       ,@SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog]
    @Creator=@UserId,        
    @TypeName= 'ExchangeRate',    
    @SPName=@SPName,
    @IP =@IP,
    @Details=@LogData