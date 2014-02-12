-- =============================================
-- Author:		Joseph
-- Create date: 20-02-2013
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[Aff_AddAffCurrencies]	
	@Data varchar(1000), 
	@CustId int,
	@IP varchar(20),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT	
AS
BEGIN
	
	SET NOCOUNT ON;
	
	update dbo.SystemSettings
	set SValue = SValue + ',' + @Data
	where Type='Meta' AND SName = 'AffiliateCurrencies'

DECLARE @LogData nvarchar(200)
SELECT @LogData = 'Add Aff currencies . Currencies:' + @Data

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog]
	@Creator=@CustId,		
	@TypeName= 'AddAffCurrencies',	
	@SPName=@SPName,
	@IP =@IP,
	@Details=@LogData

END

GO
GRANT EXECUTE ON [dbo].[Aff_AddAffCurrencies] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AddAffCurrencies] TO [vnteam]

