  USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from News with (nolock))
  begin
      truncate table News
  end
  
-- News
SET IDENTITY_INSERT News ON
GO
INSERT INTO News (
	MsgID,
	Message_en,
	Message_cn,
	Message_tw,
	Message_th,
	Message_es,
	Message_id,
	Message_vi,
	Creator,
	PostedDate,
	Important,
	UpdatedBy,
	UpdatedDate
)
SELECT 
	MsgID,
	Message_en,
	Message_cn,
	Message_tw,
	Message_th,
	Message_es,
	Message_id,
	Message_vi,
	Creator,
	PostDate,
	Important,
	UpdatedBy,
	UpdateDate
from DB03.[12BetAffiliate].dbo.Affiliate_News with(nolock)	
GO
SET IDENTITY_INSERT News OFF
GO	