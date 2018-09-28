/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/

USE [Affiliate_12BET]
GO
ALTER PROCEDURE [dbo].[Aff_AffiliateUser_UserHasCasinoSel]
	@UserName VARCHAR(30)
AS
/*
 Creator: 20180525@Walter
 Task:  Description - [Redmine: #87923]
 Database: DBAFF12BET.Affiliate_12BET

 Revisions:
 -20180525@Walter : Check user has casino or not

 Parameter's Explaination:

 Developer's Notes:
  - Notes
*/
BEGIN
	SET NOCOUNT ON
    DECLARE @HasCasino BIT
    SET @HasCasino = 0

    IF EXISTS (
			SELECT TOP 1 CValue
			FROM CommonSettings(NOLOCK)
			WHERE [Type] = '12betcasino'
				AND CName = @UserName
			)
    BEGIN
		SET @HasCasino = 1
    END

    SELECT @HasCasino
END

GO