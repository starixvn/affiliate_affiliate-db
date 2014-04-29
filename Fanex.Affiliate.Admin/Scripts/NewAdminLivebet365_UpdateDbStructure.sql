USE [Affiliate_LB365]
GO

/****** Object:  Index [PK_MemberRemoval]    Script Date: 3/13/2014 9:56:14 AM ******/
ALTER TABLE [dbo].[MemberRemoval]

DROP CONSTRAINT [PK_MemberRemoval]
GO

/****** Object:  Index [PK_MemberRemoval]    Script Date: 3/13/2014 9:56:14 AM ******/
ALTER TABLE [dbo].[MemberRemoval] ADD CONSTRAINT [PK_MemberRemoval] PRIMARY KEY CLUSTERED (
	[UserName] ASC
	,[AffID] ASC
	) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [AccInfoData]
GO

--grant currencies permisstion
DECLARE @AllCurrencies VARCHAR(255)
DECLARE @tblGroupAdmin TABLE (groupid INT)

INSERT INTO @tblGroupAdmin (groupid)
SELECT [GroupID]
FROM [dbo].[AffGroupInfo]
WHERE [GroupName] IN ('Aff_IT_Dept', 'Administrator')

SELECT @AllCurrencies = [SValue]
FROM [Affiliate_Athena000].[dbo].[SystemSettings]
WHERE [SName] = 'AffiliateCurrencies'

--delete old permission
DELETE d
FROM [dbo].[AffGroupPermissionDetail] d
	INNER JOIN @tblGroupAdmin g
	ON d.GroupID = g.GroupID;

WITH TblCurrency
AS (
	SELECT c.CurrencyID
		,c.CurrencyCode
	FROM dbo.strSplit(@AllCurrencies, ',') t
		INNER JOIN dbo.Currency c
		ON t.val = c.CurrencyCode
	)
	,TblAdmin
AS (
	SELECT [custid]
		,au.GroupID
		,ag.GroupName
		,[Username]
		,[RoleId]
	FROM [dbo].[AdminUser] au
		INNER JOIN dbo.AffGroupInfo ag
		ON au.GroupID = ag.GroupID
		INNER JOIN @tblGroupAdmin g
		ON au.GroupID = g.GroupID
	)
	,TblPermission
AS (
	SELECT a.GroupID
		,1 AS TypeID
		,c.CurrencyID AS AttributeID
		,a.custid AS ObjectID
	FROM TblAdmin a
		CROSS JOIN TblCurrency c
	)
INSERT INTO [dbo].[AffGroupPermissionDetail] (
	[GroupID]
	,[TypeID]
	,[AttributeID]
	,[ObjectID]
	)
SELECT GroupID
	,[TypeID]
	,[AttributeID]
	,[ObjectID]
FROM TblPermission;
GO

--insert new MonthlyTransfer function
DECLARE @FuncId INT = 0
	,@ErrCode INT = 0
	,@ErrMsg NVARCHAR(200);

EXEC [dbo].[Aff_Con_FuncInfoIns] @FuncName = '[MonthlyTransfer]'
	,@FuncNote = 'Monthly Transfer'
	,@FuncDesc = 'Monthly Transfer'
	,@DisplayOrder = 1
	,
	--@ParentId  = 13,
	@IP = '127.0.0.1'
	,@Language = 'en-US'
	,@UserID = 4
	,@FileNames = '/Payment/ProcessingCommission'
	,@FuncId = @FuncId OUTPUT
	,@ErrCode = @ErrCode OUTPUT
	,@ErrMsg = @ErrMsg OUTPUT

PRINT 'insert new function []' + cast(@FuncId AS VARCHAR(5))
GO

INSERT INTO [dbo].[DeductionType] (
	[DTypeID]
	,[TransTypeID]
	,[ProductID]
	,[DTypeName]
	,[DTypeDesc]
	,[DeductedPercentage]
	)
VALUES (
	5
	,NULL
	,0
	,'Cashback'
	,'Bonus Deduction overall'
	,1
	)

PRINT 'insert new DeductionType - Cashback'
GO

--update system sestting
INSERT INTO [Affiliate_LB365_test].[dbo].[SystemSettings]
           ([Type]
           ,[SName]
           ,[SValue]
           ,[Description]
           ,[Environment])
   SELECT [Type]
      ,[SName]
      ,[SValue]
      ,[Description]
      ,[Environment]
  FROM [Affiliate_Athena000].[dbo].[SystemSettings]
  where Type = 'Environment'
GO

--update Affiliate TotalMembers/BF Info
UPDATE ai
SET TotalMembers = ISNULL(tmp.Total, ai.TotalMembers)
FROM dbo.AffInfo ai WITH (ROWLOCK, UPDLOCK)
LEFT JOIN (
	SELECT AffID, COUNT(1) Total
	FROM dbo.MemberInfo WITH (NOLOCK)
	WHERE IsRemoved = 0
	GROUP BY AffID
) tmp ON ai.AffID = tmp.AffID

-- Update BF for AffInfo  
UPDATE ai
SET ai.BF = ISNULL(tmp.Amount, ai.BF)
FROM AffInfo ai WITH (ROWLOCK, UPDLOCK)
LEFT JOIN (
	SELECT at.AffID, SUM(at.Amount) Amount
	FROM dbo.AffTrans at WITH (NOLOCK)
	WHERE at.[status] IN ('approved','completed')  
	GROUP BY at.AffID
) tmp ON ai.AffID = tmp.AffID


-- Update TestLevel Info
UPDATE ai
SET TestLevel = 0
FROM AffInfo ai WITH (ROWLOCK, UPDLOCK)
WHERE TestLevel IS NULL

/****** Script for reseting languaue setting  ******/
declare @AFF_AffiliateSupportedLanguages varchar(255)
	,@defaultLan varchar(10)

SELECT TOP 1 @AFF_AffiliateSupportedLanguages = [SValue] 
FROM [dbo].[SystemSettings] with(nolock)
where [SName]='AFF_AffiliateSupportedLanguages'

select top 1 @defaultLan = val 
from dbo.strSplit(@AFF_AffiliateSupportedLanguages, ',')

select @AFF_AffiliateSupportedLanguages AffiliateSupportedLanguages, @defaultLan DefaultLanguaue

update upd
	set PreferredLanguage = @defaultLan
from dbo.AffDetail upd with (rowlock,updlock)
where [PreferredLanguage] not in (select val from dbo.strSplit(@AFF_AffiliateSupportedLanguages, ','))

delete del
from dbo.[Language] del
where LanguageID not in (select val from dbo.strSplit(@AFF_AffiliateSupportedLanguages, ','))


