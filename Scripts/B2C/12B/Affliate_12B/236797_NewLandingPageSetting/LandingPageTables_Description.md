# Landing Page Tables Documentation

## Overview
This document describes the database tables for the Landing Page feature, including their purpose and column descriptions.

## Tables

### LandingPage_Module
**Purpose**: Stores configuration and metadata for different types of modules that can be used in landing pages.

| Column | Type | Nullable | Description |
|--------|------|---------|-------------|
| ModuleId | INT | No | Primary key - Unique identifier for each module |
| ModuleName | NVARCHAR(200) | No | Display name of the module |
| ModuleType | SMALLINT | No | Type/category identifier for the module |
| Remark | VARCHAR(200) | Yes | Additional notes or comments about the module |
| NavigateTo | INT | Yes | Reference ID for navigation target |
| IsMultipleUpload | BIT | No | Flag indicating if module supports multiple file uploads |
| IsRequired | BIT | No | Flag indicating if module is mandatory |
| IsUnique | BIT | No | Flag indicating if module should be unique per page |

### LandingPage_MediaGallery
**Purpose**: Manages media files (images, videos, etc.) associated with landing page modules.

| Column | Type | Nullable | Description |
|--------|------|---------|-------------|
| MediaId | INT (IDENTITY) | No | Primary key - Unique identifier for each media item |
| MediaName | VARCHAR(200) | No | Display name for the media item |
| FileName | VARCHAR(200) | No | Original filename of the uploaded media |
| ModuleId | INT | No | Reference to the associated module |
| Dimention | VARCHAR(20) | Yes | Dimension info (e.g. 100x200) |
| StatusId | TINYINT | Yes | Status of the media (0: Active, 1: Inactive) |
| TargetCountryCode | VARCHAR(50) | Yes | Country code for geographic targeting |
| MarketId | VARCHAR(50) | Yes | Market segment identifier |
| Creator | INT | No | User ID who uploaded the media |
| CreatedDate | DATETIME | No | Timestamp when media was uploaded |
| UpdatedBy | INT | Yes | User ID who last modified the media |
| UpdatedDate | DATETIME | Yes | Timestamp of last modification |
| IsDisable | BIT | No | Soft delete flag |

### LandingPage_Builder
**Purpose**: Stores complete landing page configurations including layout, targeting, and associated deals.

| Column | Type | Nullable | Description |
|--------|------|---------|-------------|
| PageId | INT (IDENTITY) | No | Primary key - Unique identifier for each landing page |
| PageName | VARCHAR(200) | No | Display name of the landing page |
| PageCode | VARCHAR(100) | No | Unique code identifier for the page |
| CampaignId | INT | Yes | Campaign reference ID |
| TargetCountryCode | VARCHAR(50) | No | Country code for geographic targeting |
| MarketId | VARCHAR(50) | No | Market segment identifier |
| DealIds | VARCHAR(2000) | Yes | Comma-separated list of associated deal IDs |
| ComponentStructure | VARCHAR(MAX) | Yes | JSON/XML structure defining page layout and components |
| StatusId | TINYINT | No | Current status of the landing page (draft, active, inactive, etc.) |
| Creator | INT | No | User ID who created the page |
| CreatedDate | DATETIME | No | Timestamp when page was created |
| UpdatedBy | INT | Yes | User ID who last modified the page |
| UpdatedDate | DATETIME | Yes | Timestamp of last modification |


### LandingPage_Builder_Preview
**Purpose**: Stores temporary landing page preview configurations for review before publishing. Data is deleted after 2 days.

| Column | Type | Nullable | Description |
|--------|------|---------|-------------|
| PageId | INT (IDENTITY) | No | Primary key - Unique identifier for each preview page |
| PageName | VARCHAR(200) | No | Display name of the preview landing page |
| PageCode | VARCHAR(100) | No | Unique code identifier for the preview page |
| CampaignId | INT | Yes | Campaign reference ID |
| TargetCountryCode | VARCHAR(50) | No | Country code for geographic targeting |
| MarketId | VARCHAR(50) | No | Market segment identifier |
| DealIds | VARCHAR(2000) | Yes | Comma-separated list of associated deal IDs |
| ComponentStructure | VARCHAR(MAX) | Yes | JSON/XML structure defining page layout and components |
| StatusId | TINYINT | No | Current status of the preview page (draft, published, archived, etc.) |
| Creator | INT | No | User ID who created the preview page |
| CreatedDate | DATETIME | No | Timestamp when preview page was created |

**Note:** Data in this table is deleted after 2 days.

### LandingPage_Deal
**Purpose**: Links deals/offers to landing pages for promotional campaigns.

| Column | Type | Nullable | Description |
|--------|------|---------|-------------|
| Id | SMALLINT (IDENTITY) | No | Primary key - Unique identifier for the relationship |
| DealId | INT | No | Reference to the deal/offer |
| Creator | INT | No | User ID who created the relationship |
| CreatedDate | DATETIME | No | Timestamp when relationship was created |
| UpdatedBy | INT | Yes | User ID who last modified the relationship |
| UpdatedDate | DATETIME | Yes | Timestamp of last modification |
| IsDeleted | BIT | No | Soft delete flag |

## Relationships
- `LandingPage_MediaGallery.ModuleId` relates to `LandingPage_Module.ModuleId`
- `LandingPage_Setting.DealIds` contains references to deals managed in `LandingPage_Deal`

## Notes

---

### LandingPage_Campaign
**Purpose**: Stores campaign information for landing pages, including name, code, audit, and status.

| Column         | Type            | Nullable | Description |
|--------------- |----------------|----------|-------------|
| CampaignId     | INT (IDENTITY)  | No       | Primary key - Unique campaign identifier |
| CampaignName   | VARCHAR(500)    | Yes      | Name of the campaign |
| CampaignCode   | VARCHAR(100)    | Yes      | Campaign code (e.g. CAM_YYYYMMDD_CampaignId) |
| Description    | VARCHAR(500)    | Yes      | Description of the campaign |
| Creator        | INT             | Yes      | User ID who created the campaign |
| CreatedDate    | DATETIME        | Yes      | Timestamp when campaign was created |
| UpdatedBy      | INT             | Yes      | User ID who last modified the campaign |
| UpdatedDate    | DATETIME        | Yes      | Timestamp of last modification |
| StatusId       | TINYINT         | Yes      | Status (0: Draft, 1: Active, 2: Deactive, 3: Archived) |

### LandingPage_ComponentType
**Purpose**: Defines types of components for landing pages (e.g. Event, Media Group, Media Channel, Media Agency, Media Type).

| Column             | Type           | Nullable | Description |
|--------------------|--------------- |----------|-------------|
| ComponentTypeId    | INT (IDENTITY) | No       | Primary key - Unique type identifier |
| ComponentTypeName  | VARCHAR(100)   | Yes      | Name of the component type |

**Type Values:**
1: Event
2: Media Group
3: Media Channel
4: Media Agency
5: Media Type

### LandingPage_Component
**Purpose**: Stores individual components for landing pages, linked to a component type.

| Column         | Type            | Nullable | Description |
|--------------- |----------------|----------|-------------|
| ComponentId    | INT (IDENTITY)  | No       | Primary key - Unique component identifier |
| ComponentName  | VARCHAR(200)    | Yes      | Name of the component |
| ComponentType  | INT             | Yes      | Reference to ComponentTypeId |
| Creator        | INT             | Yes      | User ID who created the component |
| CreatedDate    | DATETIME        | Yes      | Timestamp when component was created |
| UpdatedBy      | INT             | Yes      | User ID who last modified the component |
| UpdatedDate    | DATETIME        | Yes      | Timestamp of last modification |
| StatusId       | TINYINT         | Yes      | Status (0: Active, 1: Inactive) |
