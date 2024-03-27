/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet"></info>*/
/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Support new Aff Yashbet
		1. Create database bodb_YashBet(filegroup, permmission, account, partition)
*/

USE [master]
GO
/****** Object:  Database [Affiliate_YashBet]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE DATABASE [Affiliate_YashBet]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Affiliate_YashBet', FILENAME = N'I:\USER_DB\Affiliate_YashBet\Affiliate_YashBet.mdf' , SIZE = 1024KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [AffData] 
( NAME = N'AffData', FILENAME = N'I:\USER_DB\Affiliate_YashBet\Affiliate_YashBet_1.ndf' , SIZE = 1024KB , MAXSIZE = UNLIMITED, FILEGROWTH = 16384KB ), 
 FILEGROUP [LogData] 
( NAME = N'LogData', FILENAME = N'I:\USER_DB\Affiliate_YashBet\Affiliate_YashBet_4.ndf' , SIZE = 1024KB , MAXSIZE = UNLIMITED, FILEGROWTH = 16384KB ), 
 FILEGROUP [ReportData] 
( NAME = N'ReportData', FILENAME = N'I:\USER_DB\Affiliate_YashBet\Affiliate_YashBet_2.ndf' , SIZE = 1024KB , MAXSIZE = UNLIMITED, FILEGROWTH = 16384KB ), 
 FILEGROUP [SettingData] 
( NAME = N'SettingData', FILENAME = N'I:\USER_DB\Affiliate_YashBet\Affiliate_YashBet_3.ndf' , SIZE = 1024KB , MAXSIZE = UNLIMITED, FILEGROWTH = 16384KB )
 LOG ON 
( NAME = N'Affiliate_YashBet_log', FILENAME = N'I:\USER_DB\Affiliate_YashBet\Affiliate_YashBet.ldf' , SIZE = 1024KB , MAXSIZE = 2048GB , FILEGROWTH = 32768KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
GO
ALTER DATABASE [Affiliate_YashBet] SET COMPATIBILITY_LEVEL = 150
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Affiliate_YashBet].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [Affiliate_YashBet] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [Affiliate_YashBet] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [Affiliate_YashBet] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [Affiliate_YashBet] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [Affiliate_YashBet] SET ARITHABORT OFF 
GO
ALTER DATABASE [Affiliate_YashBet] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [Affiliate_YashBet] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [Affiliate_YashBet] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [Affiliate_YashBet] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [Affiliate_YashBet] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [Affiliate_YashBet] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [Affiliate_YashBet] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [Affiliate_YashBet] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [Affiliate_YashBet] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [Affiliate_YashBet] SET  ENABLE_BROKER 
GO
ALTER DATABASE [Affiliate_YashBet] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [Affiliate_YashBet] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [Affiliate_YashBet] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [Affiliate_YashBet] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [Affiliate_YashBet] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [Affiliate_YashBet] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [Affiliate_YashBet] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [Affiliate_YashBet] SET RECOVERY FULL 
GO
ALTER DATABASE [Affiliate_YashBet] SET  MULTI_USER 
GO
ALTER DATABASE [Affiliate_YashBet] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [Affiliate_YashBet] SET DB_CHAINING OFF 
GO
ALTER DATABASE [Affiliate_YashBet] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [Affiliate_YashBet] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
ALTER DATABASE [Affiliate_YashBet] SET DELAYED_DURABILITY = DISABLED 
GO
EXEC sys.sp_db_vardecimal_storage_format N'Affiliate_YashBet', N'ON'
GO
ALTER DATABASE [Affiliate_YashBet] SET QUERY_STORE = OFF
GO
USE [Affiliate_YashBet]
GO
/****** Object:  User [vnteam]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE USER [vnteam] FOR LOGIN [vnteam] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [vnSol]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE USER [vnSol] FOR LOGIN [vnSol] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [vnSAS]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE USER [vnSAS] FOR LOGIN [vnSAS] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [vnBrice]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE USER [vnBrice] FOR LOGIN [vnBrice] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [vnBilly]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE USER [vnBilly] FOR LOGIN [vnBilly] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [SqlLink]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE USER [SqlLink] FOR LOGIN [SqlLink] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [rdsvntrack]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE USER [rdsvntrack] FOR LOGIN [rdsvntrack] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [wsv_lap]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE USER [wsv_lap] FOR LOGIN [wsv_lap] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [wsv_afinet]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE USER [wsv_afinet] FOR LOGIN [wsv_afinet] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [wsv_afinetv]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE USER [wsv_afinetv] FOR LOGIN [wsv_afinetv] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [aff_b2c]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE USER [aff_b2c] FOR LOGIN [aff_b2c] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_datareader] ADD MEMBER [vnteam]
GO
ALTER ROLE [db_owner] ADD MEMBER [vnSol]
GO
ALTER ROLE [db_datareader] ADD MEMBER [vnSAS]
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