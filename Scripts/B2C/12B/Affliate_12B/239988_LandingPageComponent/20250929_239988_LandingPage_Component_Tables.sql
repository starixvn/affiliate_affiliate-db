/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
==============================================
Create Date: 20250929
Author: Sophia
RedmineID: #239988
Description: Create tables for Landing Page Component management
Database: Affiliate_12B
==============================================
*/

 

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[LandingPage_ComponentType]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[LandingPage_ComponentType](
        [ComponentTypeId] [int] IDENTITY(1,1) NOT NULL,
        [ComponentTypeName] [varchar](100) NOT NULL,
        CONSTRAINT [PK_LandingPage_ComponentType] PRIMARY KEY CLUSTERED 
        (
            [ComponentTypeId] ASC
        )
    );

    PRINT 'Table LandingPage_ComponentType created successfully';

    -- Insert initial component types
    INSERT INTO [dbo].[LandingPage_ComponentType] ([ComponentTypeName])
    VALUES 
        ('Event'),
        ('Media Group'),
        ('Media Channel'),
        ('Media Agency'),
        ('Media Type');

    PRINT 'Initial component types inserted successfully';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[LandingPage_Component]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[LandingPage_Component](
        [ComponentId] [int] IDENTITY(1,1) NOT NULL,
        [ComponentName] [varchar](200) NOT NULL,
        [ComponentCode] [varchar](200) NOT NULL,
        [ComponentTypeId] [int] NOT NULL,
        [Creator] [int] NOT NULL,
        [CreatedDate] [datetime] NOT NULL,
        [UpdatedBy] [int] NOT NULL,
        [UpdatedDate] [datetime] NOT NULL,
        [StatusId] [tinyint] NOT NULL CONSTRAINT [DF_LandingPage_Component_StatusId] DEFAULT ((1)),
        CONSTRAINT [PK_LandingPage_Component] PRIMARY KEY CLUSTERED 
        (
            [ComponentId] ASC
        )
    );

    PRINT 'Table LandingPage_Component created successfully';

    -- Create indexes
    CREATE NONCLUSTERED INDEX [IX_LandingPage_Component_ComponentType] ON [dbo].[LandingPage_Component]
    (
        [ComponentType] ASC
    );

    CREATE NONCLUSTERED INDEX [IX_LandingPage_Component_ComponentCode] ON [dbo].[LandingPage_Component]
    (
        [ComponentCode] ASC
    );

    PRINT 'Indexes created successfully';
END
GO