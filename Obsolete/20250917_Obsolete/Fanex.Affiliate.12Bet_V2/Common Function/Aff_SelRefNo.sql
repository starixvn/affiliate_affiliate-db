ALTER PROCEDURE [Aff_SelRefNo]
	@RefNo bigint OUTPUT,
	@RefName varchar(10) = 'AFF_Comm'
AS  
/*
	DB052.AFFILIATE_12BET
*/
SET NOCOUNT ON
begin tran 
  
UPDATE Ref with (rowlock,updlock)
SET  @RefNo=RefNo=RefNo+1  
WHERE RefName=@RefName
  
commit tran  

GRANT EXECUTE ON [dbo].[Aff_SelRefNo] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_SelRefNo] TO [vnteam]