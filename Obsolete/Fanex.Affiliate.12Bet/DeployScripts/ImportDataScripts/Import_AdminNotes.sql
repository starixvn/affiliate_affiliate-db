 USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from AdminNotes with (nolock))
  begin
      truncate table AdminNotes
  end
  
-- AdminNotes
SET IDENTITY_INSERT AdminNotes ON
GO
INSERT INTO AdminNotes (
	NoteID,
	Note,
	UpdatedDate,
	AffID,
	UpdatedBy
)
SELECT 
	NoteID,
	Note,
	UpdateDate,
	CustID,
	UpdatedBy
from DB03.[12BetAffiliate].dbo.Affiliate_Note with (nolock)	
GO
SET IDENTITY_INSERT AdminNotes OFF
GO	  