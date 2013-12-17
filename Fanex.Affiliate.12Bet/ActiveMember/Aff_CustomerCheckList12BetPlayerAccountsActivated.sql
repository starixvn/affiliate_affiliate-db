ALTER PROC  [dbo].[Aff_CustomerCheckList12BetPlayerAccountsActivated]      
 @UserNames nvarchar(200) = null    
AS      
/*      
Created: 20120724@Thai    
Task : Check the list of Affiliate's 12BetPlayer Accounts is activated   
DB: DB052.Affiliate_12BET      
Original:      
      
Revisions:      
	- 20120724@Thai: [Description of revision]       
	- 20120810@Johnny: Update SP, Correct location of SP is in DB052.Affiliate_12Bet
Param's Explanation:      
• @UserNames: the list of 12bet Player accounts for this affiliate     
*/      
SET NOCOUNT ON      
--CONTENT OF SP HERE      
    
Declare @Splitter varchar(1)

select @Splitter = ','    


select REPLACE(username2, '12bet$', '') as username,
	username as ibcusername, 
	firstname, lastname,     
    custid as ibccustid, 
    creatdate as createddate    
from bodb02.dbo.customer as c with (NOLOCK)     
	inner join dbo.[strSplit] (@UserNames, @Splitter) as list on c.Username2 = '12bet$' + list.Val

go

GRANT EXECUTE ON [dbo].[Aff_CustomerCheckList12BetPlayerAccountsActivated] TO [bodbAdminNet]
