CREATE PROCEDURE [dbo].[AffAdmin_IsMonthlyTransfer]
	@MonthDate datetime,
	@IsMonthly bit = 0 OUTPUT
AS


IF (Exists(SELECT TOP 1 * FROM AffCommission nolock WHERE DATEDIFF(M, WinlostDate, @MonthDate) = 0))
BEGIN
	SELECT @IsMonthly = 1--This month has been transfered already
	Return
END

GO
GRANT EXECUTE ON [dbo].[AffAdmin_IsMonthlyTransfer] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_IsMonthlyTransfer] TO [vnteam] AS [dbo]
