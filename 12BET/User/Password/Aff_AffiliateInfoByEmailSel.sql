/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO
CREATE PROCEDURE [dbo].[Aff_AffiliateInfoByEmailSel]
    @Email NVARCHAR(50)=NULL,
    @ValidCode NVARCHAR(10),
    @IP VARCHAR(20) = '',
    @ErrCode INT = 0 OUTPUT
AS
/*
 Creator: 20180531@Walter
 Task:  Description - [Redmine: #87923]
 Database: DBAFF12BET.Affiliate_12BET

 Revisions:
 -20180531@Walter : Get affiliate information by email

 Parameter's Explaination:

 Developer's Notes:
  - Notes
*/
BEGIN
    SET NOCOUNT ON

    DECLARE @AffId INT
  
    SELECT @AffId=AffId
    FROM AffInfo c WITH(NOLOCK)
    WHERE Email=@Email

    IF @AffId IS NULL
    BEGIN
        SELECT @ErrCode = 1001
    END
    ELSE IF EXISTS (
        SELECT TOP 1 1
        FROM AffInfo WITH(NOLOCK)
        WHERE status <> 'Approved' AND AffId = @AffId
    )
    BEGIN
        SELECT @ErrCode = 1009
    END
    ELSE IF EXISTS(SELECT 1 FROM AffInfo WITH(NOLOCK) WHERE IsClosed = 1 AND AffId=@AffID)
    BEGIN
        SELECT @ErrCode = 1008
    END
    ELSE
    BEGIN
        --Update customer store validcode in answer field,expiry in question field 
        UPDATE AffDetail WITH(ROWLOCK,UPDLOCK)   
        SET ValidCode=@ValidCode, CodeExpiry=DATEADD(hh, 24, current_timestamp)  
        WHERE AffId=@AffId

        SELECT ai.AffId, ai.Username, ai.Firstname, ad.PreferredLanguage, ad.MailOption
        FROM AffInfo ai WITH(NOLOCK)
        INNER JOIN AffDetail ad ON ai.AffId = ad.AffId 
        WHERE ai.AffId=@AffId

        DECLARE @SPName VARCHAR(50), @LogData NVARCHAR(300)  
        SELECT @LogData = 'Fogot password for affiliateID:' + dbo.Aff_ToString(@AffID) + ' ValidCode:' + @ValidCode  
        SELECT @SPName = OBJECT_NAME(@@ProcID)  
        
        EXEC [dbo].[Aff_WriteLog]
            @Creator = @AffID,
            @AffID = @AffID,
            @Typename = 'Password', -- refer to table LogType  
            @SPName = @SPName,
            @Details = @LogData,
            @IP = @IP
    END
END

GO