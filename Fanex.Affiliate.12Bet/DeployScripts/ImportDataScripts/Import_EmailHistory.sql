  USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from EmailHistory with (nolock))
  begin
      truncate table EmailHistory
  end
  
-- EmailHistory
SET IDENTITY_INSERT EmailHistory ON
GO
INSERT INTO EmailHistory (
	MID,
	Content,
	Sender,
	Creator,
	AffId,
	AffName,
	Email,
	Subject,
	CreatedDate,
	IP,
	Browser,
	SessionID
)
SELECT 
	MID,
	Content,
	Sender,
	Creator,
	AffiliateId,
	AffName,
	Email,
	Subject,
	CreateDate,
	IP,
	Browser,
	SessionID
from DB03.[12BetAffiliate].dbo.Affiliate_EmailHistory with (nolock)	
GO
SET IDENTITY_INSERT EmailHistory OFF
GO	