USE [Affiliate_12BET];
GO

IF (NOT EXISTS (
		SELECT TOP 1 1
		FROM sys.sysObjects o
		WHERE o.NAME = 'SeqClickStats')
	OR NOT EXISTS (
		SELECT TOP 1 1
		FROM sys.sysObjects o
		WHERE o.NAME = 'EUAffPlayers') 
	) 
BEGIN
	PRINT 'Not found dependencies'
	RETURN;
END

--Insert into [AffInfo]
--INSERT INTO [dbo].[MemberInfo]
--    ([IBCCustID]
--    ,[AffID]
--    ,[UserName]
--    ,[IBCUserName]
--    ,[CreatedDate]
--    ,[RegisteredDate]
--    ,[IsRemoved]
--    ,[DepositCustID]
--    ,[FirstName]
--    ,[LastName]
--    ,[Currency]
--    ,[Email]
--    ,[Recommend]
--    ,[ClickId]
--    ,[AffAffectedDate]
--    ,[EUAffID])
SELECT mem.IBCCustID			--<IBCCustID, int,>
    ,aff.AffID					--<AffID, int,> new AFFID
    ,mem.UserName				--<UserName, varchar(30),>
    ,mem.IBCUserName			--<IBCUserName, varchar(30),>
    ,mem.FirstDepositDate		--<CreatedDate, datetime,>
    ,mem.RegisteredDate			--<RegisteredDate, datetime,>
    ,0 AS IsRemoved				--<IsRemoved, bit,>
    ,mem.DepositCustID			--<DepositCustID, int,>
    ,mem.FirstName				--<FirstName, nvarchar(50),>
    ,mem.LastName				--<LastName, nvarchar(50),>
    ,mem.Currency				--<Currency, int,>
    ,mem.Email					--<Email, nvarchar(50),>
    ,mem.Recommend				--<Recommend, int,>
    ,seq.SeqID				--<ClickId, bigint,>
    ,GETDATE() AS AffAffectedDate		--<AffAffectedDate, datetime,>
    ,mem.EUAffID						--<EUAffID, int,>
FROM dbo.SeqClickStats seq
INNER JOIN dbo.EUAffPlayers mem
	ON seq.[DepositCustID] = mem.[DepositCustID]
INNER JOIN dbo.AffInfo aff 
	ON mem.EUAffID = aff.EUAffID
--VALUES
--    (<IBCCustID, int,>
--    ,<AffID, int,>
--    ,<UserName, varchar(30),>
--    ,<IBCUserName, varchar(30),>
--    ,<CreatedDate, datetime,>
--    ,<RegisteredDate, datetime,>
--    ,<IsRemoved, bit,>
--    ,<DepositCustID, int,>
--    ,<FirstName, nvarchar(50),>
--    ,<LastName, nvarchar(50),>
--    ,<Currency, int,>
--    ,<Email, nvarchar(50),>
--    ,<Recommend, int,>
--    ,<ClickId, bigint,>
--    ,<AffAffectedDate, datetime,>
--    ,<EUAffID, int,>)

GO
