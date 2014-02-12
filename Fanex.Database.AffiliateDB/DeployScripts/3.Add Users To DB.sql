USE [Affiliate_Licensee]
GO

/****** Object:  User [vnteam]    Script Date: 05/16/2013 05:24:44 ******/
GO

CREATE USER [vnteam] FOR LOGIN [vnTeam] WITH DEFAULT_SCHEMA=[dbo]
GO

CREATE USER [vnAffiliate] FOR LOGIN [vnAffiliate] WITH DEFAULT_SCHEMA=[dbo]
GO

CREATE USER [bodbDownlineNetView] FOR LOGIN [bodbDownlineNetView] WITH DEFAULT_SCHEMA=[dbo]
GO

CREATE USER [bodbDownlineNet] FOR LOGIN [bodbDownlineNet] WITH DEFAULT_SCHEMA=[dbo]
GO

CREATE USER [bodbAdminNet] FOR LOGIN [bodbAdminNet] WITH DEFAULT_SCHEMA=[dbo]
GO


go

exec sp_addrolemember db_datareader, vnteam 

go

exec sp_addrolemember db_datareader, vnAffiliate 
go

exec sp_addrolemember db_datareader, bodbDownlineNetView 

go

exec sp_addrolemember db_datareader, bodbDownlineNet 
go

exec sp_addrolemember db_datareader, bodbAdminNet 


go
exec sp_addrolemember db_datawriter, vnAffiliate 
go
exec sp_addrolemember db_datawriter, bodbDownlineNetView 
go
exec sp_addrolemember db_datawriter, bodbDownlineNet 
go
exec sp_addrolemember db_datawriter, bodbAdminNet 
go
