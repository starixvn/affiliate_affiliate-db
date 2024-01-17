/*<info serverAlias="DBYASHBET-bodb_YashBet_Archive"></info>*/
/*
	Created: 20240115@Sally
	DB: DBYASHBET-bodb_YashBet_Archive
	Task: Support new Aff Yashbet
		1. Create Database bodb_YashBet_Archive
*/
USE [master]
GO
/****** Object:  Database [bodb_YashBet_Archive]    Script Date: 1/11/2024 10:40:30 PM ******/
CREATE DATABASE [bodb_YashBet_Archive]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'bodb_YashBet_Archive', FILENAME = N'F:\USER_DB\bodb_YashBet_Archive\bodb_YashBet_Archive.mdf' , SIZE = 4096KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [ReportData] 
( NAME = N'ReportData', FILENAME = N'F:\USER_DB\bodb_YashBet_Archive\ReportData.ndf' , SIZE = 4096KB , MAXSIZE = UNLIMITED, FILEGROWTH = 524288KB )
 LOG ON 
( NAME = N'bodb_YashBet_Archive_log', FILENAME = N'F:\USER_DB\bodb_YashBet_Archive\bodb_YashBet_Archive_Log.ldf' , SIZE = 1024KB , MAXSIZE = 2048GB , FILEGROWTH = 524288KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
GO
ALTER DATABASE [bodb_YashBet_Archive] SET COMPATIBILITY_LEVEL = 150
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [bodb_YashBet_Archive].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [bodb_YashBet_Archive] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET ARITHABORT OFF 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET  ENABLE_BROKER 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET RECOVERY FULL 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET  MULTI_USER 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [bodb_YashBet_Archive] SET DB_CHAINING OFF 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
ALTER DATABASE [bodb_YashBet_Archive] SET DELAYED_DURABILITY = DISABLED 
GO
EXEC sys.sp_db_vardecimal_storage_format N'bodb_YashBet_Archive', N'ON'
GO
ALTER DATABASE [bodb_YashBet_Archive] SET QUERY_STORE = OFF
GO
USE [bodb_YashBet_Archive]
GO
/****** Object:  User [vnteam]    Script Date: 1/11/2024 10:40:30 PM ******/
CREATE USER [vnteam] FOR LOGIN [vnteam] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [vnDBA]    Script Date: 1/11/2024 10:40:30 PM ******/
CREATE USER [vnDBA] FOR LOGIN [vnDBA] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [SqlLink]    Script Date: 1/11/2024 10:40:30 PM ******/
CREATE USER [SqlLink] FOR LOGIN [SqlLink] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [rdsvntrack]    Script Date: 1/11/2024 10:40:30 PM ******/
CREATE USER [rdsvntrack] FOR LOGIN [rdsvntrack] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [bodbLicenseeNet]    Script Date: 1/11/2024 10:40:30 PM ******/
CREATE USER [bodbLicenseeNet] FOR LOGIN [bodbLicenseeNet] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_datareader] ADD MEMBER [vnteam]
GO
ALTER ROLE [db_datareader] ADD MEMBER [vnDBA]
GO
ALTER ROLE [db_owner] ADD MEMBER [SqlLink]
GO
ALTER ROLE [db_denydatawriter] ADD MEMBER [SqlLink]
GO

/****** Object:  Table [dbo].[TpBetRecord_bk]    Script Date: 1/11/2024 10:40:30 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TpBetRecord_bk](
	[TpId] [int] NOT NULL,
	[TransId] [varchar](100) NOT NULL,
	[GameType] [int] NOT NULL,
	[CustId] [varchar](45) NOT NULL,
	[UserName] [varchar](30) NOT NULL,
	[CurrencyId] [int] NOT NULL,
	[SiteId] [int] NOT NULL,
	[TpUserName] [varchar](50) NOT NULL,
	[TransTime] [datetime] NOT NULL,
	[SettledTime] [datetime] NOT NULL,
	[Stake] [decimal](20, 6) NOT NULL,
	[WinlostAmount] [decimal](20, 6) NOT NULL,
	[SettlementType] [tinyint] NOT NULL,
	[TicketStatus] [tinyint] NOT NULL,
	[OriginalState] [varchar](10) NULL,
	[TicketKey] [bigint] NOT NULL,
	[CreateTime] [datetime] NOT NULL,
	[WinlostDate] [smalldatetime] NULL,
	[ValidBet] [decimal](20, 6) NULL,
	[BonusId] [int] NULL,
	[Revenue] [decimal](20, 6) NULL,
	[ProgressiveBet] [decimal](20, 6) NULL,
	[ProgressiveWin] [decimal](20, 6) NULL,
 CONSTRAINT [PK_TpBetRecord_bk_2] PRIMARY KEY NONCLUSTERED 
(
	[TpId] ASC,
	[TransId] ASC,
	[GameType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData]
GO
/****** Object:  Index [CIX_WinlostDate_bk_2]    Script Date: 1/11/2024 10:40:30 PM ******/
CREATE CLUSTERED INDEX [CIX_WinlostDate_bk_2] ON [dbo].[TpBetRecord_bk]
(
	[WinlostDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_CustId_2]    Script Date: 1/11/2024 10:40:30 PM ******/
CREATE NONCLUSTERED INDEX [IX_CustId_2] ON [dbo].[TpBetRecord_bk]
(
	[CustId] ASC,
	[GameType] ASC,
	[TicketStatus] ASC,
	[SettledTime] ASC
)
INCLUDE([TransTime],[TransId],[CurrencyId],[Stake],[ValidBet],[WinlostAmount],[Revenue],[ProgressiveWin],[ProgressiveBet]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO
USE [master]
GO
ALTER DATABASE [bodb_YashBet_Archive] SET  READ_WRITE 
GO
