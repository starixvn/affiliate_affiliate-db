/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Aff_MemberInfoGetMissingCreatedDate]    
/*
	Created: 20130729@Unknown
	DB: DBAFF - Affiliate_Athena000,Affiliate_Aoncash,Affiliate_ItcBet,Affiliate_MacauBet,Affiliate_Spondemo,Affiliate_9Bet
	Revisions
		- 20240516@Eddie: Enhance SP to restrict the member list to call TW service to update memberinfo [RedmineID: #205233]
*/
AS    
BEGIN
	SET NOCOUNT ON

	DECLARE @dbname VARCHAR(50) = DB_NAME()
	
	SELECT @dbname = SUBSTRING(@dbname, 11, LEN(@dbname) - 10)

	SELECT m.username
    FROM MemberInfo m WITH (NOLOCK)
        INNER JOIN bodb02.dbo.customer c WITH (NOLOCK) ON c.username2 = @dbname + '$' + m.username
    WHERE m.CreatedDate IS NULL and c.site = @dbname
END