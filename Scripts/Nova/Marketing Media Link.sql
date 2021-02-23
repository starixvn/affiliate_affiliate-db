/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20201215@Percy
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G
	Task: New Media Channel

	use Affiliate_N88
	go
	use Affiliate_N8B
	go
	use Affiliate_N8G
	go
*/

create table dbo.AffMediaChannel
(
	AffId			int not null
	,ChannelCode	varchar(50) not null
	,ChannelName	nvarchar(200) not null
	,CreatedDate	datetime constraint DF_AffMediaChanel_CreatedDate default (getdate())
	,constraint PK_AffMediaChanel primary key clustered
	(
		AffId asc
		,ChannelCode asc
	)
) on SettingData
go

create table dbo.AffMediaLink
(
	AffId			int not null
	,ChannelCode	varchar(50) not null
	,LanguageCode	varchar(10) not null
	,AffMediaLink	varchar(500) not null
	,IsShow			bit constraint DF_AffMediaLink_IsShow default (1)
	,constraint PK_AffMediaLink primary key clustered
	(
		AffId asc
		,ChannelCode asc
		,LanguageCode asc
		,AffMediaLink asc
	)
) on SettingData
go

declare @CommChannel table (ChannelCode varchar(50), ChannelName nvarchar(200))
insert into @CommChannel (ChannelCode, ChannelName)
values ('youtube', 'Youtube')
	,('facebook', 'Facebook')
	,('twitter', 'Twitter')
	,('tiktok', 'Tiktok')
	,('whatsapp', 'Whatsapp')
	,('telegram', 'Telegram')

insert into dbo.AffMediaChannel (AffId, ChannelCode, ChannelName)
select a.AffId, c.ChannelCode, c.ChannelName
from dbo.AffInfo a with (nolock)
	cross join @CommChannel c
where a.Status = 'Approved'
go