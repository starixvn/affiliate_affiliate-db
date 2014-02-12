
ALTER PROCEDURE [dbo].[Aff_IBCMemberExistingCheck]
	@DepUserName varchar(30), 
	@SystemName varchar(50)	
AS
/*
	Task : Get all information of existing member
	DB : DB05.bodb02
*/

Select @DepUserName as username,firstname,lastname,creatdate as CreatedDate,c.username as IBCUserName,c.custID as IBCCustID,e.exchangeid,e.currency,e.code,c.recommend,refcode2 as DepositCustID, closed, e.ActualRate
from Customer c with (nolock)
	inner join CustInfo ci with (nolock) on c.CustId = Ci.CustId
	inner join Exchange e with (nolock) on c.currency = e.ExchangeId
where username2=@SystemName + '$' + @DepUserName
	
GO
GRANT EXECUTE ON [dbo].[Aff_IBCMemberExistingCheck] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_IBCMemberExistingCheck] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_IBCMemberExistingCheck] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_IBCMemberExistingCheck] TO [vnTeam]
GO