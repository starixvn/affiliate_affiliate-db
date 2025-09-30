ALTER PROCEDURE [dbo].[Aff_DummyAccID]
	@Username varchar(50),
	@CustId int output
AS

/*
Created: 20130315@Peter    
Task : Get Player CustId by Player Username 
DB: DB054.bodb02
Original:     
	- Johnny@2013Mar26: For Testing in UUS Account
Param's Explanation:    
.@Username: Player Username    
.@CustId : Output Player CustId    
*/

---For Testing in UUS Account
Select @CustId = 10545127
return 

Select @CustId = CustId
From CustInfo nolock
where Username = @Username

GO
GRANT EXECUTE ON [dbo].[Aff_DummyAccID] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_DummyAccID] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_DummyAccID] TO [vnTeam]
GO