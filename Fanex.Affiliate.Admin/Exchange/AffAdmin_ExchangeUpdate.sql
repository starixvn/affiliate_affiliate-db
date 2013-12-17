-- =============================================
-- Script Template
-- =============================================
ALTER PROCEDURE [dbo].[AffAdmin_ExchangeUpdate]
	@UserId int,
	@ExchangeId int,
	@Rate float,
	@ToCurrency varchar(5),
	@IP varchar(20),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: 20091010@Johnny
	Task : Update exchange rate
	DB: DB052.Affiliate_ZZun
	Revisions:
		- 20091014@Johnny initialize
		- 20110223@Viet: Revise
		
	Param's Explanation:

*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
	@custid=@UserId,@funcname='[AffEx.Rate]',
	@System = 'AFFILIATE',
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output
	
If @ErrCode <> 0
	RETURN	

if not Exists(select 1 from Exchange with (nolock) where ExchangeId = @ExchangeId)
	return--Do nothing if actualrate as the same as the current one			

IF not Exists(select 1 from systemsettings s where SName = 'AFF_SupportedCurrencies'
			and SValue like '%'+@ToCurrency+'%') 
	return -- currency is not supported
	
DECLARE @sql nvarchar(1000)
	
set @sql = 'update Exchange with (rowlock, updlock) set ' +
	 @ToCurrency + ' = ' + LTRIM(Str(@Rate,25,5)) +
	' where ExchangeId = ' + LTRIM(Str(@ExchangeId,25))

exec (@sql)

set @sql = ' update ExchangeDaily with (rowlock, updlock) set ' +
	 @ToCurrency + ' = ' +LTRIM(Str(@Rate,25,5)) +
	' where ExchangeId = ' + LTRIM(Str(@ExchangeId,25)) +
	' and datediff(day,[Date],CURRENT_TIMESTAMP)=0'

exec (@sql)


---------Update for ToCurrency convert to FromCurrency
Declare @FromCurrency varchar(5)

Select @FromCurrency = Code From Exchange nolock where ExchangeId = @ExchangeId
IF Exists(select 1 from systemsettings s where SName = 'AFF_SupportedCurrencies'
			and SValue like '%'+@FromCurrency+'%') 
Begin
	--select LTRIM(Str(1/@Rate,25,5))	

	declare @revertRate float
	if @Rate >= 0.0000000000001	
	   select @revertRate=1/@Rate 	
	else
	   select @revertRate=@Rate 	
	
	Set @Sql  = 'update Exchange with (rowlock, updlock) set ' +
	 @FromCurrency + ' = ' + LTRIM(Str(@revertRate,25,5)) +
	' where Code = ''' + @ToCurrency + ''''
	select @Sql

	exec (@sql)
	
	Set @Sql  = 'update ExchangeDaily with (rowlock, updlock) set ' +
	 @FromCurrency + ' = ' + LTRIM(Str(@revertRate,25,5)) +
	' where Code = ''' + @ToCurrency + '''' +
	' and datediff(day,[Date],CURRENT_TIMESTAMP)=0'
	exec (@sql)
End


--------Write Log
DECLARE @LogData nvarchar(200)
SELECT @LogData = 'Update exchange rate of affiliate. ExchangeId:' + dbo.Aff_ToString(@ExchangeId) + ', Rate: ' + dbo.Aff_ToString(@Rate) + ',BasedCurrency:' + dbo.Aff_ToString(@ToCurrency)

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog]
	@Creator=@UserId,		
	@TypeName= 'ExchangeRate',	
	@SPName=@SPName,
	@IP =@IP,
	@Details=@LogData

GO
GRANT EXECUTE ON [dbo].[AffAdmin_ExchangeUpdate] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_ExchangeUpdate] TO [vnteam]	

