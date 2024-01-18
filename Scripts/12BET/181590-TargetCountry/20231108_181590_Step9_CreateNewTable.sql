/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20231108@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Add new table TargetProduct and insert data into TargetProduct [RedmineId : #181590]
*/

CREATE TABLE [dbo].[TargetProduct](
	[ProductID]    [INT] NOT NULL
	,[ProductName] [VARCHAR](100) NOT NULL
	,CONSTRAINT [PK_TargetProduct] PRIMARY KEY CLUSTERED 
	(
		[ProductID] ASC
	) ON [PRIMARY]
) ON [PRIMARY]
GO


INSERT INTO [dbo].[TargetProduct](ProductID, ProductName)
VALUES (1 , 'Sports')
	  ,(2 , 'Exchange')
	  ,(3 , 'E-Sports')
	  ,(4 , 'Playtech')
	  ,(5 , 'Casino')
	  ,(6 , 'Live Casino')
	  ,(7 , 'Arcade')
	  ,(8 , 'P2P')
	  ,(9 , 'Number Game')
	  ,(10, 'Keno')
	  ,(11, 'Lottery')
GO