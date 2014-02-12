-- =============================================
-- Author:		Joseph
-- Create date: 20-02-2013
-- Description:	
-- =============================================
ALTER PROCEDURE [dbo].[Aff_AddExchanges]
	@Currencies varchar(255), 
	@Data varchar(8000), 
	@CustId int,
	@IP varchar(20),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT	
AS
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @table1 table (RowID int not null primary key identity(1,1), val nvarchar( 4000) )			
	
	DECLARE @RowsToProcess  int
	DECLARE @CurrentRow     int
	DECLARE @val  varchar(1000)
		
	insert into @table1(val) select val from strSplit(@Data,'#')	
	
	SET @RowsToProcess=@@ROWCOUNT

	SET @CurrentRow=0
	WHILE @CurrentRow<@RowsToProcess
	BEGIN
		SET @CurrentRow=@CurrentRow+1
		SELECT 
			@val='insert into dbo.Exchange(IsAutoRefresh,CreatedDate,ExchangeID,Code,Currency,Creator,' +
			 @Currencies + ') values(0, CURRENT_TIMESTAMP,' +
			replace(val,'{creator}',@CustId) + ')'
			FROM @table1
			WHERE RowID=@CurrentRow
		--select @val	
		exec(@val)
		--do your thing here--

	END


DECLARE @LogData nvarchar(200)
SELECT @LogData = 'Add exchanges of affiliate. Currencies:' + @Currencies + ', Rates: ' + dbo.Aff_ToString(@Data) 

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog]
	@Creator=@CustId,		
	@TypeName= 'AddExchange',	
	@SPName=@SPName,
	@IP =@IP,
	@Details=@LogData

END

GO
GRANT EXECUTE ON [dbo].[Aff_AddExchanges] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AddExchanges] TO [vnteam]

