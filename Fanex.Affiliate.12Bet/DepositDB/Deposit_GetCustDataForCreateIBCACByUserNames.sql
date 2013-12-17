ALTER PROCEDURE [dbo].[Deposit_GetCustDataForCreateIBCACByUserNames]  
	@deposit_usernames varchar(30)    
AS  
/*    
Created: 20120724@Thai  
Task : Get the list of customer's data by user names
DB: DBDeposit.Deposit_DB    
    
Revisions:    
 - 20120724@[Reviewer]: [Description of revision]     
 - 20120810@Johnny: Change split function
    
Param's Explanation:    
• @deposit_usernames: the list of user names
*/ 
SET NOCOUNT ON  

 Select username,
		firstname ,   
        lastname ,   
        email,   
        username ,  
        userpwd as Password,  
        currency,   
        OddsType = case when OddsType = 'de' then 'hka' end,
        AffiliateID,  
        address,  
        city,  
        birthday,  
        country,  
        phone,  
        gender,  
        state,  
        IBCAgentID as AgentID ,  
        ZipCode,    
        isnull(BonusCode,'') as BonusCode  ,
		isnull(custid,0) as DepositUserId
from Deposit_Customer with(NOLOCK)   
where username in (select Val from [dbo].[strSplit] (@deposit_usernames, ','))

go

GRANT EXECUTE ON [dbo].[Deposit_GetCustDataForCreateIBCACByUserNames] TO [bodbAffiliateNet]
