ALTER PROCEDURE [dbo].[Aff_CheckPermissionOnAff]
	@CustId int,
    @Username varchar(50) = '',
    @AffId int = 0,
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
    Created: 20090730@Peter
    Task : Select affiliate info for left panel
    DB: DB052.Affiliate_MYM

    Revisions:
      .20090823@Peter : Rewrite the sp for new DB DB052.Affiliate_MYM
                        Remove the theory of pending commission and CurrCommEarning   
                        Get PreferredPayment to check approve 
		- 20151123@Victor: Implement SSO from Internal Admin to Affiliate Admin site
                        
    Param's Explanation:
    • @Username : Affiliate username
*/
SET NOCOUNT ON
Declare @AffType tinyint
DECLARE @LicenseeID INT
SELECT @LicenseeID = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName LIKE 'LicenseeID'

if @AffId != 0
Begin
    select @AffType = AffType
    From AffInfo with (nolock)
    where AffId = @AffId
End
else
Begin
    select @AffType = AffType
    From AffInfo with (nolock)
    where Username = @Username
End

select @AffId, @Username, @AffType

if @AffType is null
Begin
    SELECT @ErrMsg = 'You are not authorized on this function', @ErrCode = 500
    RETURN 
End

If @AffType = 2
Begin
				EXEC [dbo].[Aff_Con_CheckPermission] 
		@LicenseeID = @LicenseeID,
        @custid=@CustId,
        @funcname='[MediaAffiliate]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output
    
End
Else
Begin
				EXEC [dbo].[Aff_Con_CheckPermission]
		@LicenseeID = @LicenseeID,
        @custid=@CustId,@funcname='[Affiliate]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
End
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CheckPermissionOnAff] TO [vnteam] AS [dbo]