/*<info serverAlias="DBYASHBET-bodb_YashBet"></info>*/
/*
	Created: 20240115@Sally
	DB: DBYASHBET-bodb_YashBet
	Task: Support new Aff Yashbet
		1. Create database bodb_YashBet(filegroup, permmission, account, partition)
*/

USE [master]
GO
/****** Object:  Database [bodb_YashBet]    Script Date: 1/8/2024 12:02:29 AM ******/
CREATE DATABASE [bodb_YashBet]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'bodb_YashBet', FILENAME = N'F:\USER_DB\bodb_YashBet\bodb_YashBet.mdf' , SIZE = 4096KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_24M01] 
( NAME = N'YashBet_SumWinloss_24M01', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_24M01.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_24M02] 
( NAME = N'YashBet_SumWinloss_24M02', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_24M02.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_24M03] 
( NAME = N'YashBet_SumWinloss_24M03', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_24M03.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_24M04] 
( NAME = N'YashBet_SumWinloss_24M04', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_24M04.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_24M05] 
( NAME = N'YashBet_SumWinloss_24M05', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_24M05.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_24M06] 
( NAME = N'YashBet_SumWinloss_24M06', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_24M06.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_24M07] 
( NAME = N'YashBet_SumWinloss_24M07', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_24M07.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_24M08] 
( NAME = N'YashBet_SumWinloss_24M08', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_24M08.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_24M09] 
( NAME = N'YashBet_SumWinloss_24M09', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_24M09.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_24M10] 
( NAME = N'YashBet_SumWinloss_24M10', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_24M10.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_24M11] 
( NAME = N'YashBet_SumWinloss_24M11', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_24M11.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_24M12] 
( NAME = N'YashBet_SumWinloss_24M12', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_24M12.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_25M01] 
( NAME = N'YashBet_SumWinloss_25M01', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_25M01.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_25M02] 
( NAME = N'YashBet_SumWinloss_25M02', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_25M02.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_25M03] 
( NAME = N'YashBet_SumWinloss_25M03', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_25M03.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_25M04] 
( NAME = N'YashBet_SumWinloss_25M04', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_25M04.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_25M05] 
( NAME = N'YashBet_SumWinloss_25M05', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_25M05.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_25M06] 
( NAME = N'YashBet_SumWinloss_25M06', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_25M06.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_25M07] 
( NAME = N'YashBet_SumWinloss_25M07', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_25M07.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_25M08] 
( NAME = N'YashBet_SumWinloss_25M08', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_25M08.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_25M09] 
( NAME = N'YashBet_SumWinloss_25M09', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_25M09.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_25M10] 
( NAME = N'YashBet_SumWinloss_25M10', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_25M10.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_25M11] 
( NAME = N'YashBet_SumWinloss_25M11', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_25M11.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_25M12] 
( NAME = N'YashBet_SumWinloss_25M12', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_25M12.ndf' , SIZE = 512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 32768KB ), 
 FILEGROUP [YashBet_SumWinloss_MAX] 
( NAME = N'YashBet_SumWinloss_MAX', FILENAME = N'F:\USER_DB\bodb_YashBet\YashBet_SumWinloss\YashBet_SumWinloss_MAX.ndf' , SIZE = 3072KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [ReportData] 
( NAME = N'ReportData', FILENAME = N'F:\USER_DB\bodb_YashBet\ReportData.ndf' , SIZE = 1024KB , MAXSIZE = UNLIMITED, FILEGROWTH = 16384KB ), 
 FILEGROUP [SettingData] 
( NAME = N'SettingData', FILENAME = N'F:\USER_DB\bodb_YashBet\SettingData.ndf' , SIZE = 4096KB , MAXSIZE = UNLIMITED, FILEGROWTH = 16384KB )
 LOG ON 
( NAME = N'bodb_YashBet_log', FILENAME = N'F:\USER_DB\bodb_YashBet\bodb_YashBet_Log.ldf' , SIZE = 1024KB , MAXSIZE = 2048GB , FILEGROWTH = 32768KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
GO
ALTER DATABASE [bodb_YashBet] SET COMPATIBILITY_LEVEL = 150
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [bodb_YashBet].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [bodb_YashBet] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [bodb_YashBet] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [bodb_YashBet] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [bodb_YashBet] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [bodb_YashBet] SET ARITHABORT OFF 
GO
ALTER DATABASE [bodb_YashBet] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [bodb_YashBet] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [bodb_YashBet] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [bodb_YashBet] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [bodb_YashBet] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [bodb_YashBet] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [bodb_YashBet] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [bodb_YashBet] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [bodb_YashBet] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [bodb_YashBet] SET  ENABLE_BROKER 
GO
ALTER DATABASE [bodb_YashBet] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [bodb_YashBet] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [bodb_YashBet] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [bodb_YashBet] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [bodb_YashBet] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [bodb_YashBet] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [bodb_YashBet] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [bodb_YashBet] SET RECOVERY FULL 
GO
ALTER DATABASE [bodb_YashBet] SET  MULTI_USER 
GO
ALTER DATABASE [bodb_YashBet] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [bodb_YashBet] SET DB_CHAINING OFF 
GO
ALTER DATABASE [bodb_YashBet] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [bodb_YashBet] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
ALTER DATABASE [bodb_YashBet] SET DELAYED_DURABILITY = DISABLED 
GO
EXEC sys.sp_db_vardecimal_storage_format N'bodb_YashBet', N'ON'
GO
ALTER DATABASE [bodb_YashBet] SET QUERY_STORE = OFF
GO
USE [bodb_YashBet]
GO
/****** Object:  User [vnteam]    Script Date: 1/8/2024 12:02:30 AM ******/
CREATE USER [vnteam] FOR LOGIN [vnteam] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [vnSol]    Script Date: 1/8/2024 12:02:30 AM ******/
CREATE USER [vnSol] FOR LOGIN [vnSol] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [vnDBA]    Script Date: 1/8/2024 12:02:30 AM ******/
CREATE USER [vnDBA] FOR LOGIN [vnDBA] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [vnBrice]    Script Date: 1/8/2024 12:02:30 AM ******/
CREATE USER [vnBrice] FOR LOGIN [vnBrice] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [vnBilly]    Script Date: 1/8/2024 12:02:30 AM ******/
CREATE USER [vnBilly] FOR LOGIN [vnBilly] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [SqlLink]    Script Date: 1/8/2024 12:02:30 AM ******/
CREATE USER [SqlLink] FOR LOGIN [SqlLink] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [rdsvntrack]    Script Date: 1/8/2024 12:02:30 AM ******/
CREATE USER [rdsvntrack] FOR LOGIN [rdsvntrack] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [wsv_lap]    Script Date: 1/8/2024 12:02:30 AM ******/
CREATE USER [wsv_lap] FOR LOGIN [wsv_lap] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [wsv_alpv]    Script Date: 1/8/2024 12:02:30 AM ******/
CREATE USER [wsv_alpv] FOR LOGIN [wsv_alpv] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [wsv_alp]    Script Date: 1/8/2024 12:02:30 AM ******/
CREATE USER [wsv_alp] FOR LOGIN [wsv_alp] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [wsv_nap]    Script Date: 1/8/2024 12:02:30 AM ******/
CREATE USER [wsv_nap] FOR LOGIN [wsv_nap] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [aff_b2c]    Script Date: 1/8/2024 12:02:30 AM ******/
CREATE USER [aff_b2c] FOR LOGIN [aff_b2c] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_datareader] ADD MEMBER [vnteam]
GO
ALTER ROLE [db_datareader] ADD MEMBER [vnSol]
GO
ALTER ROLE [db_datareader] ADD MEMBER [vnDBA]
GO
ALTER ROLE [db_owner] ADD MEMBER [vnBrice]
GO
ALTER ROLE [db_datareader] ADD MEMBER [vnBilly]
GO
ALTER ROLE [db_owner] ADD MEMBER [SqlLink]
GO
ALTER ROLE [db_denydatawriter] ADD MEMBER [SqlLink]
GO
ALTER ROLE [db_datareader] ADD MEMBER [aff_b2c]
GO

/****** Object:  PartitionFunction [PF_YashBet_SumWinloss_Monthly]    Script Date: 1/8/2024 12:02:30 AM ******/
CREATE PARTITION FUNCTION [PF_YashBet_SumWinloss_Monthly](datetime) AS RANGE LEFT FOR VALUES ( N'2024-01-31T00:00:00.000', N'2024-02-29T00:00:00.000', N'2024-03-31T00:00:00.000', N'2024-04-30T00:00:00.000', N'2024-05-31T00:00:00.000', N'2024-06-30T00:00:00.000', N'2024-07-31T00:00:00.000', N'2024-08-31T00:00:00.000', N'2024-09-30T00:00:00.000', N'2024-10-31T00:00:00.000', N'2024-11-30T00:00:00.000', N'2024-12-31T00:00:00.000', N'2025-01-31T00:00:00.000', N'2025-02-28T00:00:00.000', N'2025-03-31T00:00:00.000', N'2025-04-30T00:00:00.000', N'2025-05-31T00:00:00.000', N'2025-06-30T00:00:00.000', N'2025-07-31T00:00:00.000', N'2025-08-31T00:00:00.000', N'2025-09-30T00:00:00.000', N'2025-10-31T00:00:00.000', N'2025-11-30T00:00:00.000', N'2025-12-31T00:00:00.000')
GO
/****** Object:  PartitionScheme [PS_YashBet_SumWinloss_Monthly]    Script Date: 1/8/2024 12:02:30 AM ******/
CREATE PARTITION SCHEME [PS_YashBet_SumWinloss_Monthly] AS PARTITION [PF_YashBet_SumWinloss_Monthly] TO ([YashBet_SumWinloss_24M01], [YashBet_SumWinloss_24M02], [YashBet_SumWinloss_24M03], [YashBet_SumWinloss_24M04], [YashBet_SumWinloss_24M05], [YashBet_SumWinloss_24M06], [YashBet_SumWinloss_24M07], [YashBet_SumWinloss_24M08], [YashBet_SumWinloss_24M09], [YashBet_SumWinloss_24M10], [YashBet_SumWinloss_24M11], [YashBet_SumWinloss_24M12], [YashBet_SumWinloss_25M01], [YashBet_SumWinloss_25M02], [YashBet_SumWinloss_25M03], [YashBet_SumWinloss_25M04], [YashBet_SumWinloss_25M05], [YashBet_SumWinloss_25M06], [YashBet_SumWinloss_25M07], [YashBet_SumWinloss_25M08], [YashBet_SumWinloss_25M09], [YashBet_SumWinloss_25M10], [YashBet_SumWinloss_25M11], [YashBet_SumWinloss_25M12], [YashBet_SumWinloss_MAX])
GO

USE [master]
GO
ALTER DATABASE [bodb_YashBet] SET  READ_WRITE 
GO
