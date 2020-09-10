/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20200909@Percy
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G
	Task: New function: sub affiliate domain
*/

-- use Affiliate_N88

-- use Affiliate_N8B

-- use Affiliate_N8G

create table dbo.SubAffDomain
(
	DomainId	int not null identity (1, 1)
	,DomainName	nvarchar(50) not null
	,CreateDate	datetime constraint DF_SubAffDomain_CreateDate default (getdate())
	,ModifyDate	datetime constraint DF_SubAffDomain_ModifyDate default (getdate())
	,Creator	int
	,IsDeleted	bit constraint DF_SubAffDomain_IsDeleted default ((0))
	,IsSSL		bit constraint DF_SubAffDomain_IsSSL default ((0))
	,constraint PK_SubAffDomain primary key clustered
	(
		DomainId asc
	) on SettingData
) on SettingData
go