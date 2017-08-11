/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_ExchangeUpdate]
	@LicenseeID INT,
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
	Task: Update exchange rate
	DB: DBAFF
	
	Revisions:
		- 20091014@Johnny initialize
		- 20110223@Viet: Revise
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
		
	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	IF NOT EXISTS (SELECT 1 FROM dbo.Exchange WITH(NOLOCK) WHERE ExchangeId = @ExchangeId)
		RETURN

	IF NOT EXISTS (SELECT 1 FROM dbo.SystemSettings WITH(NOLOCK) WHERE SName = 'AFF_SupportedCurrencies' AND SValue LIKE '%' + @ToCurrency + '%')
		RETURN
	
	DECLARE @sql NVARCHAR(1000)

	SET @sql = 'UPDATE dbo.Exchange WITH(ROWLOCK, UPDLOCK)
				SET ' + @ToCurrency + ' = ' + LTRIM(STR(@Rate, 25, 5)) +
				' WHERE ExchangeID = ' + LTRIM(STR(@ExchangeId, 25))
	EXEC (@sql)

	SET @sql = 'UPDATE dbo.ExchangeDaily WITH(ROWLOCK, UPDLOCK)
				SET ' + @ToCurrency + ' = ' + LTRIM(STR(@Rate, 25, 5)) +
				' WHERE ExchangeID = ' + LTRIM(STR(@ExchangeId, 25)) + 
				' AND DATEDIFF(DAY, [Date], CURRENT_TIMESTAMP) = 0'
	EXEC (@sql)
	
	-- Update for ToCurrency convert to FromCurrency
	DECLARE @FromCurrency VARCHAR(5)

	SELECT @FromCurrency = Code FROM dbo.Exchange WITH(NOLOCK) WHERE ExchangeId = @ExchangeId

	IF EXISTS (SELECT 1 FROM dbo.SystemSettings WITH(NOLOCK) WHERE SName = 'AFF_SupportedCurrencies' AND SValue LIKE '%' + @FromCurrency + '%')
	BEGIN
		DECLARE @revertRate FLOAT
		
		IF @Rate >= 0.0000000000001	
			SELECT @revertRate = 1/@Rate
		ELSE
			SELECT @revertRate = @Rate
	
		SET @sql = 'UPDATE dbo.Exchange WITH(ROWLOCK, UPDLOCK)
					SET ' + @FromCurrency + ' = ' + LTRIM(STR(@revertRate, 25, 5)) +
					' WHERE Code = ''' + @ToCurrency + ''''
		EXEC (@sql)
	
		SET @sql = 'UPDATE dbo.ExchangeDaily WITH(ROWLOCK, UPDLOCK)
					SET ' + @FromCurrency + ' = ' + LTRIM(STR(@revertRate, 25, 5)) +
					' WHERE Code = ''' + @ToCurrency + '''' +
					' AND DATEDIFF(DAY, [Date], CURRENT_TIMESTAMP) = 0'
		EXEC (@sql)
	END
	
	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000) 
	
	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Update exchange rate of affiliate. ExchangeId:' + dbo.Aff_ToString(@ExchangeId)
					+ ', Rate: ' + dbo.Aff_ToString(@Rate)
					+ ',BasedCurrency:' + dbo.Aff_ToString(@ToCurrency)

	EXEC [dbo].[Aff_WriteLog]
		@Creator = @UserId,		
		@TypeName = 'ExchangeRate',	
		@SPName = @SPName,
		@IP = @IP,
		@Details = @Detail
END
GO