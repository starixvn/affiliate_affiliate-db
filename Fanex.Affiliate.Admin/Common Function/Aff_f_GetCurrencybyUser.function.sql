ALTER FUNCTION [dbo].[Aff_f_GetCurrencybyUser]  
(  
@userID INT ,  
@TypeID INT  
)  
RETURNS @tmp TABLE ( UsrID INT,AttributeID INT )  
AS  
  
 /*  
 Created: 20130807@Jim  
 Task : Restrict permission of Aff Users by currency  
 DB:   
 Revisions:   
   
*/  
BEGIN   
	INSERT INTO @tmp  
	SELECT DISTINCT ObjectID,  
			AttributeID  
	FROM  dbo.AffGroupPermissionDetail WITH (NOLOCK)  
	WHERE  ObjectID=@userID   
		AND TypeID=@TypeID  
	ORDER BY AttributeID  
	RETURN   
END 