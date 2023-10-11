/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Aff_WriteLog]
	@Creator 	INT
	,@AffID   	INT = 0
	,@Typename 	VARCHAR(50)
	,@RefNo 	BIGINT = NULL OUTPUT
	,@SPName 	VARCHAR(50)
	,@IP 		VARCHAR(45) = NULL
	,@Details 	NVARCHAR(4000)
AS
/*
	Created: 20090714@VietHoang
	Task : Write Log for affiliate
	DB: DBAFF-Affiliate_Athena000, DBAFF-Affiliate_Aoncash, DBAFF-Affiliate_ItcBet, DBAFF-Affiliate_MacauBet, DBAFF-Affiliate_Spondemo, DBAFF-Affiliate_9Bet
	Original:

	Revisions:
		- 20230929@Eddie: Add metadata and write log with rollback transaction case [RedmineID: #194605]
*/
SET NOCOUNT ON

IF @SPName LIKE '%_xtest'
	SELECT @SPName = LEFT(@SPName, LEN(@SPName) - 6)
ELSE IF @SPName LIKE '%_xpre'
	 OR @SPName LIKE '%_UAT1'
	 OR @SPName LIKE '%_UAT2'
	 OR @SPName LIKE '%_UAT3'
	 OR @SPName LIKE '%_UAT4'
	SELECT @SPName = LEFT(@SPName, LEN(@SPName) - 5)
	
BEGIN TRANSACTION
	BEGIN TRY
		IF( @RefNo IS NULL OR @RefNo = 0 )
		BEGIN
			UPDATE Ref WITH (ROWLOCK, UPDLOCK)
			SET  @RefNo = refno = refno + 1
			WHERE RefName = 'Log'
		END

		INSERT INTO dbo.UserLog(RefNo, TypeID, Creator, AffID, LoggedDate, SPName, IP, Details)
		VALUES (@RefNo, dbo.Aff_GetLogType(@Typename), @Creator, @AffID, CURRENT_TIMESTAMP, @SPName, @IP, @Details)

	END TRY
	BEGIN CATCH
			ROLLBACK TRANSACTION

			IF( @RefNo IS NULL OR @RefNo = 0 )
			BEGIN
				SELECT  @RefNo = refno + 1
				FROM Ref WITH (NOLOCK)
				WHERE RefName = 'Log'
				
				INSERT INTO dbo.UserLogIsRollbacked(RefNo, TypeID, Typename, Creator, AffID, LoggedDate, SPName, IP, Details)
				VALUES (@RefNo, dbo.Aff_GetLogType(@Typename), @Typename, @Creator, @AffID, CURRENT_TIMESTAMP, @SPName, @IP, @Details)
			END
			ELSE
			BEGIN
				INSERT INTO dbo.UserLogIsRollbacked(RefNo, TypeID, Typename, Creator, AffID, LoggedDate, SPName, IP, Details)
				VALUES (@RefNo, dbo.Aff_GetLogType(@Typename), @Typename, @Creator, @AffID, CURRENT_TIMESTAMP, @SPName, @IP, @Details)
			END

			RETURN
	END CATCH
COMMIT TRANSACTION