USE [Affiliate_12BET];
GO

/** update structure of AffInfo **/
IF NOT EXISTS(SELECT 1 FROM sys.columns 
        WHERE [name] = N'ForceChangePass' AND [object_id] = OBJECT_ID(N'AffInfo'))
BEGIN
	ALTER TABLE dbo.AffInfo ADD ForceChangePass BIT DEFAULT(0);
END
IF NOT EXISTS(SELECT 1 FROM sys.columns 
        WHERE [name] = N'EUAffID' AND [object_id] = OBJECT_ID(N'AffInfo'))
BEGIN
	ALTER TABLE dbo.AffInfo ADD EUAffID INT;
END
GO

/** update structure of MemberInfo **/
IF NOT EXISTS(SELECT 1 FROM sys.columns 
        WHERE [name] = N'EUAffID' AND [object_id] = OBJECT_ID(N'MemberInfo'))
BEGIN
	ALTER TABLE dbo.MemberInfo ADD EUAffID INT;
END
IF NOT EXISTS(SELECT 1 FROM sys.columns 
        WHERE [name] = N'AffAffectedDate' AND [object_id] = OBJECT_ID(N'MemberInfo'))
BEGIN
	ALTER TABLE dbo.MemberInfo ADD AffAffectedDate DATETIME;
END
GO

/** update structure of Banner_1 **/
IF NOT EXISTS(SELECT 1 FROM sys.columns 
        WHERE [name] = N'AffType' AND [object_id] = OBJECT_ID(N'Banners_1'))
BEGIN
	ALTER TABLE dbo.Banners_1 ADD AffType INT;
END
GO
