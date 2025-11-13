/*<info serverAlias="DBAFF12B-Affiliate_12B" ></info>*/
/*
	Created: 20251113@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Add DealVerifyFlags column to CommGroup table and migrate data [RedmineID: #244127]

	Description:
		- Add DealVerifyFlags INT NULL column to dbo.CommGroup, dbo.CommGroupHistory table
		- Set DealVerifyFlags = 1 for GroupName = 'NoCommission-CPA'
		- Set DealVerifyFlags = 0 for all other records
        - Update LogAction Items field for ActionTypeId = 29
*/

-- Step 1: Check if column already exists
	IF NOT EXISTS (
		SELECT 1 
		FROM INFORMATION_SCHEMA.COLUMNS 
		WHERE TABLE_SCHEMA = 'dbo' 
		AND TABLE_NAME = 'CommGroup' 
		AND COLUMN_NAME = 'DealVerifyFlags'
	)
	BEGIN
		PRINT 'Adding DealVerifyFlags column to dbo.CommGroup table...'
		
		-- Step 2: Add the new column
		ALTER TABLE dbo.CommGroup 
		ADD DealVerifyFlags INT NULL
		
		PRINT 'Column DealVerifyFlags added successfully.'
	END
	ELSE
	BEGIN
		PRINT 'Column DealVerifyFlags already exists in dbo.CommGroup table.'
	END

    IF NOT EXISTS (
		SELECT 1 
		FROM INFORMATION_SCHEMA.COLUMNS 
		WHERE TABLE_SCHEMA = 'dbo' 
		AND TABLE_NAME = 'CommGroupHistory' 
		AND COLUMN_NAME = 'DealVerifyFlags'
	)
	BEGIN
		PRINT 'Adding DealVerifyFlags column to dbo.CommGroupHistory table...'
		
		-- Step 2: Add the new column
		ALTER TABLE dbo.CommGroupHistory 
		ADD DealVerifyFlags INT NULL
		
		PRINT 'Column DealVerifyFlags added successfully.'
	END
	ELSE
	BEGIN
		PRINT 'Column DealVerifyFlags already exists in dbo.CommGroupHistory table.'
	END

GO
-- Update LogAction Items field for ActionTypeId = 29
PRINT 'Updating LogAction Items field for ActionTypeId = 29...'

UPDATE c 
SET c.Items ='{"Items": [    {"Alias": "di", "Item": "Deal Information"},    {"Alias": "dn", "Item": "Deal Name"},    {"Alias": "dt", "Item": "Deal Type"},    {"Alias": "dv", "Item": "Verification Method"},    {"Alias": "d", "Item": "Description"},    {"Alias": "sr", "Item": "Sub Rate"},    {"Alias": "ci", "Item": "CPA Information"},    {"Alias": "tc", "Item": "Target Country"},    {"Alias": "ap", "Item": "Active Period"},    {"Alias": "hd", "Item": "Holding Days"},    {"Alias": "ht", "Item": "Holding Tickets"},    {"Alias": "q", "Item": "Quota"},    {"Alias": "rr", "Item": "Redeposit Rate"},    {"Alias": "rd", "Item": "Redeposit Days"},    {"Alias": "pf", "Item": "Payment Frequency"},    {"Alias": "sd", "Item": "Start Date"},    {"Alias": "ct", "Item": "CPA Tier"},    {"Alias": "cpg", "Item": "CPA Product Group"},    {"Alias": "cti", "Item": "Tier"},    {"Alias": "fdm", "Item": "Min FDM"},    {"Alias": "tdm", "Item": "Min Total Deposit"},    {"Alias": "w", "Item": "Min Wagering"},    {"Alias": "cpa", "Item": "CPA Amount"},    {"Alias": "ri", "Item": "Revenue Share Information"},    {"Alias": "qpt", "Item": "QP Turnover"},    {"Alias": "cqp", "Item": "Count QP"},    {"Alias": "rt", "Item": "Revenue Share Tier"},    {"Alias": "rpg", "Item": "Rev Share Product Group"},    {"Alias": "rti", "Item": "Rev Share Tier"},    {"Alias": "rf", "Item": "Royalty Fee"},    {"Alias": "nw", "Item": "Min Net Win"},    {"Alias": "qp", "Item": "Min Qualified Member"},    {"Alias": "rs", "Item": "Rev Share %"},    {"Alias": "df", "Item": "Deposit Fee"},    {"Alias": "dfx", "Item": "Deposit Fee Fix Amount"},    {"Alias": "wf", "Item": "Withdrawal Fee"},    {"Alias": "wfx", "Item": "Withdrawal Fee Fix Amount"},    {"Alias": "fd", "Item": "From Date"},    {"Alias": "td", "Item": "To Date"}  ]}'
FROM dbo.LogAction c WITH (ROWLOCK, UPDLOCK) WHEre ActionTypeId = 29


/*===================================================================================================
=======================================================================================
*/
	-- Step 3: Update data - Set DealVerifyFlags = 1 for 'NoCommission-CPA'
	PRINT 'Updating DealVerifyFlags for NoCommission-CPA group...'
	
    DECLARE @GroupId INT = NULL
    SELECT @GroupId = GroupId
    FROM dbo.CommGroup WITH (NOLOCK)
    WHERE GroupName = 'NoCommission-CPA'

    IF @GroupId IS NULL
    BEGIN
        PRINT 'No records found for NoCommission-CPA group. Exiting migration.'
        RETURN
    END
    ELSE
    BEGIN
        UPDATE dbo.CommGroup WITH(ROWLOCK, UPDLOCK)
	    SET DealVerifyFlags = 1
	    WHERE GroupId = @GroupId

        UPDATE dbo.CommGroup WITH(ROWLOCK, UPDLOCK)
	    SET DealVerifyFlags = 0
	    WHERE GroupId <> @GroupId AND DealVerifyFlags IS NULL

        UPDATE dbo.CommGroupHistory WITH(ROWLOCK, UPDLOCK)
	    SET DealVerifyFlags = 1
	    WHERE GroupId = @GroupId

        UPDATE dbo.CommGroupHistory WITH(ROWLOCK, UPDLOCK)
	    SET DealVerifyFlags = 0
	    WHERE GroupId <> @GroupId AND DealVerifyFlags IS NULL

    END	

	-- Step 5: Verify the migration
	PRINT 'Verification of migration:'
	SELECT 'CommGroup Table' AS TableName,
		'NoCommission-CPA' AS GroupType,
		COUNT(1) AS RecordCount,
		DealVerifyFlags
	FROM dbo.CommGroup WITH (NOLOCK)
	WHERE GroupId = @GroupId
	GROUP BY DealVerifyFlags

	UNION ALL

	SELECT 
        'CommGroup Table' AS TableName,
		'Other Groups' AS GroupType,
		COUNT(1) AS RecordCount,
		DealVerifyFlags
	FROM dbo.CommGroup WITH (NOLOCK)
	WHERE GroupId <> @GroupId
	GROUP BY DealVerifyFlags
    UNION ALL
    SELECT 'CommGroupHistory Table' AS TableName,
		'NoCommission-CPA' AS GroupType,
		COUNT(1) AS RecordCount,
		DealVerifyFlags
	FROM dbo.CommGroupHistory WITH (NOLOCK)
	WHERE GroupId = @GroupId
	GROUP BY DealVerifyFlags

	UNION ALL

	SELECT 
        'CommGroupHistory Table' AS TableName,
		'Other Groups' AS GroupType,
		COUNT(1) AS RecordCount,
		DealVerifyFlags
	FROM dbo.CommGroup WITH (NOLOCK)
	WHERE GroupId <> @GroupId
	GROUP BY DealVerifyFlags
	ORDER BY GroupType ASC, DealVerifyFlags ASC


PRINT 'Migration completed successfully!'

