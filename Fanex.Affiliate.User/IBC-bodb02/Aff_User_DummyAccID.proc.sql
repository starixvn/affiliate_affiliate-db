ALTER PROCEDURE [dbo].[Aff_User_DummyAccID] 
	@Username VARCHAR(50)
	,@CustId INT OUTPUT
AS
/*
Created: 20131120@Long Luu
Task : Get Player CustId by Player Username 
DB: DB052.bodb02
Original:     
	- 
Param's Explanation:    
.@Username: Player Username    
.@CustId : Output Player CustId    
*/
BEGIN
	SET NOCOUNT ON

	SELECT @CustId = CustId
	FROM Customer WITH (NOLOCK)
	WHERE Username2 = @Username

	RETURN
END
