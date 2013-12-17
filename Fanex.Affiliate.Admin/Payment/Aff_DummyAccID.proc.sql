CREATE PROCEDURE [dbo].[Aff_DummyAccID]
	@Username varchar(50),
	@CustId int output
AS

/*
Created: 20130315@Peter    
Task : Get Player CustId by Player Username 
DB: DB052.bodb02
Original:     
	- Johnny@2013Mar26: For Testing in UUS Account
Param's Explanation:    
.@Username: Player Username    
.@CustId : Output Player CustId    
*/

Select @CustId = CustId
From CustInfo with (nolock)
where Username = @Username