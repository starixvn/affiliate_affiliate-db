ALTER PROCEDURE [dbo].[Aff_SelRefNo]  
 @RefNo bigint OUTPUT,  
 @RefName varchar(10) = 'AFF_Comm'  
AS    
/*  
 DB052.Affiliate_ZZun  
*/  
SET NOCOUNT ON  
begin tran   
    
UPDATE Ref with (rowlock,updlock)  
SET  @RefNo=RefNo=RefNo+1    
WHERE RefName=@RefName  
    
commit tran    

GO
  
GRANT EXECUTE ON [dbo].[Aff_SelRefNo] TO [bodbAdminNet]  