/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/

USE [Affiliate_12BET]
GO
ALTER PROCEDURE [dbo].[Aff_AffiliateUser_ExtraUserInfoSel]
	@AffId INT
AS
/*
 Creator: 20180605@Walter
 Task:  Description - [Redmine: #87923]
 Database: DBAFF12BET.Affiliate_12BET

 Revisions:
 -20180605@Walter : Get more info of aff user

 Parameter's Explaination:

 Developer's Notes:
  - Notes
*/
BEGIN
	SET NOCOUNT ON

    DECLARE @extraInfo TABLE
    (
        GroupName NVARCHAR(100),
        HasDailyDetail BIT
    )

    DECLARE @GroupId INT
    DECLARE @GroupName NVARCHAR(100)
    DECLARE @HasDailyDetail BIT

    SELECT TOP 1 @GroupName = g.GroupName, @GroupId = g.GroupId
    FROM CommGroup g WITH(NOLOCK)
    INNER JOIN AffInfo ai WITH(NOLOCK) ON g.GroupId = ai.GroupId
    WHERE ai.AffId = @AffId

    IF EXISTS (
			SELECT TOP 1 CValue
			FROM CommonSettings(NOLOCK)
			WHERE [Type] = 'PlayerDetail'
				AND CValue = @GroupId
			)
    BEGIN
        SET @HasDailyDetail = 1
    END

    INSERT INTO @extraInfo(GroupName, HasDailyDetail)
    VALUES (@GroupName, ISNULL(@HasDailyDetail, 0))

    SELECT GroupName, HasDailyDetail
    FROM @extraInfo
END

GO