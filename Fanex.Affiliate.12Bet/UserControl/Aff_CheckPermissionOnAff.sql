USE [Affiliate_12BET]
GO
/****** Object:  StoredProcedure [dbo].[Aff_CheckPermissionOnAff]    Script Date: 12/14/2010 13:37:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
	DB: DB052.Affiliate_12BET

	Revisions:
	  .20090823@Peter : Rewrite the sp for new DB DB052.Affiliate_12BET
	                    Remove the theory of pending commission and CurrCommEarning   
	                    Get PreferredPayment to check approve 
	                    
	Param's Explanation:
	• @Username : Affiliate username
*/
SET NOCOUNT ON

Declare @AffType tinyint

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
		@custid=@CustId,
		@funcname='[MediaAffiliate]',
		@System = 'AFFILIATE',
		@ErrCode=@ErrCode output,
		@ErrMsg=@ErrMsg output
	
End
Else
Begin
	EXEC [dbo].[Aff_Con_CheckPermission]
		@custid=@CustId,@funcname='[Affiliate]',
		@System = 'AFFILIATE',
		@ErrCode=@ErrCode output,
		@ErrMsg=@ErrMsg output	
End


