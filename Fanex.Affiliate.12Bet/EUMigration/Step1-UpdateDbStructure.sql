USE [Affiliate_12BET];
GO

/** update structure of AffInfo **/
ALTER TABLE dbo.AffInfo ADD ForceChangePass BIT DEFAULT(1);
ALTER TABLE dbo.AffInfo ADD EUAffID INT;

/** update structure of MemberInfo **/
ALTER TABLE dbo.MemberInfo ADD EUAffID INT;

GO
