--DB052.Affiliate_12BET
truncate table [dbo].[Affiliate_User]
--DB03.bodb02
SET IDENTITY_INSERT [dbo].[Affiliate_User] ON 
INSERT INTO DB052.[Affiliate_12BET].[dbo].[Affiliate_User]
           ([custid]
           ,[PageAccess]
           ,[createdate]
           ,[creator]
           ,[GroupID]
           ,[Closed]
           ,[logincount]
           ,[iplogin]
           ,[lastlogged]
           ,[on_sessionid]
           ,[Username]
           ,[UserPwd]
           ,[RoleId]
           ,[PwdExpiry]
           ,[FirstName]
           ,[LastName])
SELECT au.[custid]
      ,au.[PageAccess]
      ,au.[createdate]
      ,au.[creator]
      ,au.[GroupID]
      ,au.[Closed]
      ,au.[logincount]
      ,au.[iplogin]
      ,au.[lastlogged]
      ,au.[on_sessionid]
      ,c.username
      ,c.[UserPwd]
      ,c.[RoleId]
      ,c.[PwdExpiry]
      ,c.[FirstName]
      ,c.[LastName]
  FROM [dbo].[Affiliate_User]  au (nolock)
		inner join [dbo].[Customer] c (nolock) on au.custid=c.custid
SET IDENTITY_INSERT [dbo].[Affiliate_User] OFF 		
		select * from DB052.[Affiliate_12BET].[dbo].[Affiliate_User]

truncate table [dbo].[AffGroupInfo]
SET IDENTITY_INSERT [dbo].[AffGroupInfo] ON 
INSERT INTO [DB052].[Affiliate_12BET].[dbo].[AffGroupInfo]
           ([GroupID]
           ,[GroupName]
           ,[GroupDesc]
           ,[CreateDate]
           ,[ModifyDate]
           ,[DisplayOrder]
           ,[Creator]
           ,[System])
SELECT [GroupID]
      ,[GroupName]
      ,[GroupDesc]
      ,[CreateDate]
      ,[ModifyDate]
      ,[DisplayOrder]
      ,[Creator]
      ,[System]
  FROM [dbo].[Acc_GroupInfo_1] with (nolock)
  where [System]='AFFILIATE'
  SET IDENTITY_INSERT [dbo].[AffGroupInfo] OFF 
  
  
  
TRUNCATE TABLE AffFunctionInfo

SET IDENTITY_INSERT AffFunctionInfo ON
INSERT INTO AffFunctionInfo([FuncID]
      ,[FuncName]
      ,[FuncNote]
      ,[FuncDesc]
      ,[FuncRender]
      ,[CreateDate]
      ,[ModifyDate]
      ,[DisplayOrder]
      ,[Creator]
      ,[ParentID]
      ,[Filenames]
      ,[System])
SELECT [FuncID]
      ,[FuncName]
      ,[FuncNote]
      ,[FuncDesc]
      ,[FuncRender]
      ,[CreateDate]
      ,[ModifyDate]
      ,[DisplayOrder]
      ,[Creator]
      ,[ParentID]
      ,[Filenames]
      ,[System]
FROM bodb02.dbo.acc_functioninfo_1 with (nolock)
WHERE system='Affiliate'

SET IDENTITY_INSERT AffFunctionInfo OFF  



TRUNCATE TABLE AffGroupPolicy

INSERT INTO AffGroupPolicy([GroupID]
      ,[FuncID]
      ,[Policy]
      ,[CreateDate]
      ,[ModifyDate]
      ,[Creator])
SELECT [GroupID]
      ,[FuncID]
      ,[Policy]
      ,[CreateDate]
      ,[ModifyDate]
      ,[Creator]
FROM bodb02.dbo.Acc_GroupPolicy_1 with (nolock)
WHERE GroupId in(SELECT groupid FROM AffGroupInfo (nolock) WHERE System='Affiliate')


TRUNCATE TABLE AffMemberPolicy

INSERT INTO AffMemberPolicy([CustID]
      ,[FuncID]
      ,[Policy]
      ,[CreateDate]
      ,[ModifyDate]
      ,[Creator])
SELECT [CustID]
      ,[FuncID]
      ,[Policy]
      ,[CreateDate]
      ,[ModifyDate]
      ,[Creator]
FROM bodb02.dbo.Acc_MemberPolicy_1 with (nolock)
WHERE FuncID in(SELECT FuncID FROM dbo.AffFunctionInfo(nolock) WHERE System='Affiliate')

Go
