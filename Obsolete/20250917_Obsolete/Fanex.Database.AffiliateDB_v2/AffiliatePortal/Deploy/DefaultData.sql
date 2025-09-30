 ---Truncate all table
use AffPortal_SPON
GO 
truncate table ThemeLanguages
truncate table LayoutBuckets
truncate table Themes
truncate table Buckets
truncate table AliasURLs
truncate table SiteHistories
truncate table Layouts
truncate table EmbeddableMeta
truncate table SiteTemps
truncate table MenuTemps
truncate table MenuHistories
truncate table PageTemps
truncate table Taxonomy
truncate table SiteVersions
truncate table PageHistories
truncate table SiteOption
truncate table SiteMetaTemps
truncate table SiteMetaHistories
truncate table SiteMeta
truncate table SEOMetaData
truncate table [Messages]
truncate table Pages
truncate table EmbeddableSamples
truncate table Embeddables
truncate table PageEmbeddableMetaTemps
truncate table PageEmbeddableTemps
truncate table PageEmbeddableMetaHistories
truncate table PageEmbeddableHistories
truncate table PageEmbeddableMeta
truncate table PageEmbeddables
truncate table Comments
truncate table Posts
truncate table Terms
truncate table ELMAH_Error
truncate table EmbeddableInRoles
truncate table EmbeddbleRoles
truncate table Menu
truncate table EmbeddableLanguages
truncate table TermLanguages
truncate table Languages
truncate table TermRelationships

truncate table Sites
truncate table ThemesMeta
GO

INSERT INTO [AffPortal_SPON].[dbo].[Buckets]
           ([code]
           ,[name]
           ,[inBody]
           ,[controlOnDisk])
           
select 'CONTENT','Content',1,NULL UNION ALL
select 'FOOTER','Footer',0,NULL UNION ALL
select 'FOOTERL','Footer left',0,NULL UNION ALL
select 'FOOTERM','Footer middle',0,NULL UNION ALL
select 'FOOTERR','Footer right',0,NULL UNION ALL
select 'LEFT','Left panel',1,NULL UNION ALL
select 'LEFTL','Left left',1,NULL UNION ALL
select 'LEFTR','Left right',1,NULL UNION ALL
select 'LEFTT','Left top',1,NULL UNION ALL
select 'RIGHT','Right panel',1,NULL UNION ALL
select 'RIGHTL','Right left',1,NULL UNION ALL
select 'RIGHTR','Right right',1,NULL UNION ALL
select 'RIGHTT','Right top',1,NULL 



INSERT INTO [AffPortal_SPON].[dbo].[Layouts]
           ([layoutFile]
           ,[isBody]
           ,[description])
           
select 'l1',1,'One column layout' UNION ALL
select 'l2r',1,'Two columns with right panel' UNION ALL
select 'l2l',1,'Two columns with left panel' UNION ALL
select 'f1',0,'One column footer' UNION ALL
select 'f2',0,'Two columns footer' UNION ALL
select 'f3',0,'Three columns footer' UNION ALL
select 'l2r2',1,'Two columns layout, right panel have two columns and one top bucket above' UNION ALL
select 'l2l2',1,'Two columns layout, left panel have two colums and one top bucket above' UNION ALL
select 'l3r2',1,'Three columns layout, left panel and right panel with two columns and one top bucket above' UNION ALL
select 'l3l2',1,'Three columns layout, right panel and left panel with two columns and one top bucket above' UNION ALL
select 'l3lr',1,'Three columns layout with left panel and right panel' 


INSERT INTO [AffPortal_SPON].[dbo].[LayoutBuckets]
           ([layoutId]
           ,[bucketCode])
           

select 2,'RIGHT' UNION ALL 

select 3,'LEFT' UNION ALL 

select 4,'FOOTER' UNION ALL 
select 5,'FOOTERL' UNION ALL 
select 5,'FOOTERR' UNION ALL 

select 6,'FOOTERL' UNION ALL 
select 6,'FOOTERM' UNION ALL 
select 6,'FOOTERR' UNION ALL 


select 7,'RIGHTLEFT' UNION ALL 
select 7,'RIGHTRIGHT' UNION ALL 
select 7,'RIGHTTOP' UNION ALL 


select 8,'LEFTLEFT' UNION ALL 
select 8,'LEFTRIGHT' UNION ALL 
select 8,'LEFTTOP' UNION ALL 


select 9,'LEFT' UNION ALL 
select 9,'RIGHTLEFT' UNION ALL 
select 9,'RIGHTRIGHT' UNION ALL 
select 9,'RIGHTTOP' UNION ALL 


select 10,'LEFTLEFT' UNION ALL 
select 10,'LEFTRIGHT' UNION ALL 
select 10,'LEFTTOP' UNION ALL 
select 10,'RIGHT' UNION ALL 

select 11,'LEFT' UNION ALL 
select 11,'RIGHT' 


INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (1, N'en-US', N'Default')
INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (2, N'en-US', N'Football')
INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (3, N'en-US', N'Casino')
INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (4, N'en-US', N'Soccer')

INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (1, N'vi-VN', N'Default')
INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (2, N'vi-VN', N'Football')
INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (3, N'vi-VN', N'Casino')
INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (4, N'vi-VN', N'Soccer')

INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (1, N'id-ID', N'Default')
INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (2, N'id-ID', N'Football')
INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (3, N'id-ID', N'Casino')
INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (4, N'id-ID', N'Soccer')

INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (1, N'th-TH', N'Default')
INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (2, N'th-TH', N'Football')
INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (3, N'th-TH', N'Casino')
INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (4, N'th-TH', N'Soccer')

INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (1, N'es-ES', N'Default')
INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (2, N'es-ES', N'Football')
INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (3, N'es-ES', N'Casino')
INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (4, N'es-ES', N'Soccer')

INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (1, N'zh-CN', N'Default')
INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (2, N'zh-CN', N'Football')
INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (3, N'zh-CN', N'Casino')
INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (4, N'zh-CN', N'Soccer')

INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (1, N'zh-TW', N'Default')
INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (2, N'zh-TW', N'Football')
INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (3, N'zh-TW', N'Casino')
INSERT [dbo].[ThemeLanguages] ([themeId], [languageCode], [name]) VALUES (4, N'zh-TW', N'Soccer')




SET IDENTITY_INSERT [dbo].[Themes] ON
INSERT [dbo].[Themes] ([themeId], [name], [folder], [enable], [level]) VALUES (1, N'Default', N'default', 1, 0)
INSERT [dbo].[Themes] ([themeId], [name], [folder], [enable], [level]) VALUES (2, N'Football', N'football', 1, 0)
INSERT [dbo].[Themes] ([themeId], [name], [folder], [enable], [level]) VALUES (3, N'Casino', N'casino', 1, 0)
INSERT [dbo].[Themes] ([themeId], [name], [folder], [enable], [level]) VALUES (4, N'Soccer', N'soccer', 1, 0)
SET IDENTITY_INSERT [dbo].[Themes] OFF

INSERT [dbo].[Embeddables] ([embeddableId], [name], [description], [editable], [enable], [isSystem], [createdBy], [createdDate]) VALUES (N'912a402b-4e2a-40e2-8bb2-1516c533d1bb', N'Twitter profile', N'Twitter profile', 1, 1, 0, 927841, CAST(0x00009DFF00000000 AS DateTime))
INSERT [dbo].[Embeddables] ([embeddableId], [name], [description], [editable], [enable], [isSystem], [createdBy], [createdDate]) VALUES (N'833e7301-8422-4d72-af69-1f73332e79eb', N'Post categories', N'Post categories', 0, 1, 0, 927841, CAST(0x00009E0A00000000 AS DateTime))
INSERT [dbo].[Embeddables] ([embeddableId], [name], [description], [editable], [enable], [isSystem], [createdBy], [createdDate]) VALUES (N'87d085fe-a625-4cdb-9a68-2030d4ba7eb4', N'RSS', N'RSS', 1, 1, 0, 927841, CAST(0x00009DF80127577F AS DateTime))
INSERT [dbo].[Embeddables] ([embeddableId], [name], [description], [editable], [enable], [isSystem], [createdBy], [createdDate]) VALUES (N'45f6fb19-17c9-4fca-95dc-2723563e0031', N'Twitter search', N'Twitter search', 1, 1, 0, 927841, CAST(0x00009DF800000000 AS DateTime))
INSERT [dbo].[Embeddables] ([embeddableId], [name], [description], [editable], [enable], [isSystem], [createdBy], [createdDate]) VALUES (N'e3222107-b5f5-498b-bc8a-3c8660d63ad4', N'HTML and Javascript', N'HTML and Javascript', 0, 0, 0, 927841, CAST(0x00009E1A00000000 AS DateTime))
INSERT [dbo].[Embeddables] ([embeddableId], [name], [description], [editable], [enable], [isSystem], [createdBy], [createdDate]) VALUES (N'7a9ea974-dfde-414f-a997-9d9aca280e62', N'Affiliate advertising', N'Add affiliate ad (image banner and flash banner) to your site', 1, 1, 0, 927841, CAST(0x00009E3300000000 AS DateTime))
INSERT [dbo].[Embeddables] ([embeddableId], [name], [description], [editable], [enable], [isSystem], [createdBy], [createdDate]) VALUES (N'638ed2be-2c16-4395-8698-b817d87b9540', N'Home posts', N'Home posts', 0, 1, 1, 927841, CAST(0x00009E0A00000000 AS DateTime))
INSERT [dbo].[Embeddables] ([embeddableId], [name], [description], [editable], [enable], [isSystem], [createdBy], [createdDate]) VALUES (N'975b0852-8862-466e-88dc-ba89d80d37ae', N'Google search', N'Google search', 0, 1, 0, 927841, CAST(0x00009E1A00000000 AS DateTime))
INSERT [dbo].[Embeddables] ([embeddableId], [name], [description], [editable], [enable], [isSystem], [createdBy], [createdDate]) VALUES (N'2bc9d28a-c4eb-4751-ab0c-cd23f693c006', N'Post detail', N'Post detail', 0, 1, 1, 927841, CAST(0x00009E0A00000000 AS DateTime))
INSERT [dbo].[Embeddables] ([embeddableId], [name], [description], [editable], [enable], [isSystem], [createdBy], [createdDate]) VALUES (N'1261572f-7314-45f5-b820-cdfb4f370ee7', N'Text', N'Add some words to your blog - like a welcome message - with our rich text editor', 1, 1, 0, 927841, CAST(0x00009E1C00000000 AS DateTime))
INSERT [dbo].[Embeddables] ([embeddableId], [name], [description], [editable], [enable], [isSystem], [createdBy], [createdDate]) VALUES (N'68b80dea-222d-4ab1-af86-dc18ca9962bb', N'Posts by categories', N'Posts by categories', 0, 1, 1, 927841, CAST(0x00009E0A00000000 AS DateTime))
INSERT [dbo].[Embeddables] ([embeddableId], [name], [description], [editable], [enable], [isSystem], [createdBy], [createdDate]) VALUES (N'3360cd08-e10f-49fa-8977-de7b998c8366', N'Contact', N'Contact form', 1, 1, 0, 927841, CAST(0x00009E2600000000 AS DateTime))

INSERT [dbo].[EmbeddableSamples] ([embeddableId], [fromEmbeddableId], [name], [description], [editable], [deletable], [enable], [createdBy], [createdDate]) VALUES (N'7658c720-a6dd-4c3e-8046-32fac9302830', N'1261572f-7314-45f5-b820-cdfb4f370ee7', N'12bet logo!', N'12bet logo!', 0, 0, 1, 1155577, CAST(0x00009E3200700062 AS DateTime))
INSERT [dbo].[EmbeddableSamples] ([embeddableId], [fromEmbeddableId], [name], [description], [editable], [deletable], [enable], [createdBy], [createdDate]) VALUES (N'e1f2addf-27b9-4a25-acdd-e062d58cbc96', N'87d085fe-a625-4cdb-9a68-2030d4ba7eb4', N'VnExpress', N'VnExpress home page', 0, 1, 1, 1155577, CAST(0x00009E320076202C AS DateTime))


INSERT [dbo].[EmbeddableMeta] ([embeddableId], [key], [value]) VALUES (N'7658c720-a6dd-4c3e-8046-32fac9302830', N'content', N'<p>www.12bet.com</p>')
INSERT [dbo].[EmbeddableMeta] ([embeddableId], [key], [value]) VALUES (N'7658c720-a6dd-4c3e-8046-32fac9302830', N'showtitle', N'off')
INSERT [dbo].[EmbeddableMeta] ([embeddableId], [key], [value]) VALUES (N'e1f2addf-27b9-4a25-acdd-e062d58cbc96', N'rss_rownumber', N'5')
INSERT [dbo].[EmbeddableMeta] ([embeddableId], [key], [value]) VALUES (N'e1f2addf-27b9-4a25-acdd-e062d58cbc96', N'rss_source', N'http://vnexpress.net/rss/gl/trang-chu.rss')

SET IDENTITY_INSERT [dbo].[Languages] ON
INSERT [dbo].[Languages] ([languageId], [code], [name], [enable]) VALUES (2, N'vi-VN', N'Vietnamese', 1)
INSERT [dbo].[Languages] ([languageId], [code], [name], [enable]) VALUES (54, N'en-US', N'English', 1)
INSERT [dbo].[Languages] ([languageId], [code], [name], [enable]) VALUES (66, N'es-ES', N'Spanish', 1)
INSERT [dbo].[Languages] ([languageId], [code], [name], [enable]) VALUES (67, N'th-TH', N'Thai', 1)
INSERT [dbo].[Languages] ([languageId], [code], [name], [enable]) VALUES (68, N'id-ID', N'Indonesia', 1)
INSERT [dbo].[Languages] ([languageId], [code], [name], [enable]) VALUES (69, N'zh-CN', N'Chinese Simplified', 1)
INSERT [dbo].[Languages] ([languageId], [code], [name], [enable]) VALUES (70, N'zh-TW', N'Chinese Traditional', 1)
SET IDENTITY_INSERT [dbo].[Languages] OFF
