# Copilot Instructions for B2C Affiliate Database

This document provides guidance for working with the B2C platform stored procedures and associated database scripts.

## 1. High-Level Focus

Development work is primarily concentrated in two main areas:
- **`B2C/`**: Contains the stored procedures for various B2C brands (YashBet, N88, etc.).
- **`Scripts/`**: Contains migration, deployment, and data manipulation scripts, organized by platform.

## 2. B2C Platform Structure

The `B2C/` directory is organized by brand. While there are several brands, development work is focused almost exclusively on:

- **`B2C/12B/`**
- **`B2C/N88/`**

Other brand folders like `B2C/YashBet/` exist but are not the primary focus of current development.

Within each brand's folder, the structure is consistent, with subdirectories for functional areas like `Admin/`, `User/`, and `Report/`.

## 3. Naming Conventions

Stored procedures within the `B2C` folder follow a strict and descriptive naming convention.

**Pattern:** `Aff_{Module}_{Entity}_{Action}`

- **Prefix:** All affiliate-related procedures start with `Aff_`.
- **Module:** Specifies the functional area (e.g., `Admin`, `User`, `Con`).
- **Entity:** The business entity the procedure operates on (e.g., `AffiliateInfo`, `MediaCategory`).
- **Action:** The operation performed (`_Sel`, `_Ins`, `_Upd`, `_Del`).

**Example:**
A procedure to select affiliate details for the N88 admin panel would be located in `B2C/N88/Admin/...` and likely named `Aff_Admin_AffiliateInfo_Sel`.

## 4. Code and Documentation Standards

### Stored Procedure Structure
All stored procedures should follow this general structure:

1.  **Metadata Header:** An XML-like comment block at the top.
2.  **Database Context:** `USE [DatabaseName]` statement (e.g., `USE [Affiliate_YashBet]`).
3.  **Standard Header:** A comment block detailing the author, date, and purpose.
4.  **Procedure Body:** The `ALTER PROCEDURE` or `CREATE PROCEDURE` statement.

### Metadata Header
This header provides context for deployment and execution.
```sql
/*<info serverAlias="DBAFFN88-Affiliate_N88" executers="wsv_affnet" isFunction="0" isNested="0"></info>*/
```
- `serverAlias`: The target database server alias (e.g., `DBAFFN88-Affiliate_N88` or `DBAFF12B-Affiliate_12B`).
- `executers`: The database roles or users permitted to execute the procedure (e.g., `wsv_affnet`).
- `isFunction`: Indicates if the object is a stored procedure (`0`) or a function (`1`).

### Standard Header & Revisions
This block documents the history and purpose of the procedure.
```sql
/*
	Created: {YYYYMMDD}@{Author}
	DB: {Server.Database}
	Task: {Task Description}

	Revisions:
		- {YYYYMMDD}@{Author}: {Change Description} [RedmineID: #{ID}]
*/
```
- Always include `Author`, `date`, and a clear `Description`.
- Document significant changes in a `Revisions` block, referencing a `RedmineID` if available.

### Common SQL Practices
- Start procedure bodies with `SET NOCOUNT ON;`.
- Use `WITH(NOLOCK)` on `SELECT` statements to prevent locking issues.
- Sanitize input string parameters using `LTRIM(RTRIM(@Parameter))`.

## 5. Scripts Folder

The `Scripts/` directory contains one-off or recurring scripts for database maintenance, deployment, or data fixes.

- **Structure:** Scripts are organized into subdirectories corresponding to the platform they target (e.g., `Scripts/B2C/`).
- **Purpose:** These scripts are not part of the main application logic but are used to manage the database state.
- **Execution:** Scripts often contain metadata headers indicating the target server, similar to stored procedures.

## 6. Workflow for Modifications

1.  **Identify the Brand:** Determine which B2C brand the change applies to (usually `12B` or `N88`).
2.  **Locate the Module:** Navigate to the appropriate functional directory within the brand's folder (e.g., `B2C/N88/Admin/`).
3.  **Find or Create the File:** If modifying an existing procedure, find its `.sql` file. If creating a new one, follow the established naming conventions.
4.  **Follow Standards:** Ensure your new or modified code includes the required headers and comments.
5.  **Create Scripts:** If the change requires a data migration or a one-time update, create a new file in `Scripts/B2C/` and follow the established script format.
