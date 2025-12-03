/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20251119@Sally
    DB: DBAFF12B-Affiliate_12B
    Task: Add nullable ChannelCode column to MemberInfo [RedmineID]: #244655 

    Steps:
        1. Add ChannelCode column to dbo.MemberInfo
        2. Add MemberInfo_ChannelCode_CutOffDate flag in SystemSettings

*/
USE Affiliate_12B;
GO

/*============================================
  1. Add ChannelCode column if not exists
============================================*/
	IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.MemberInfo') AND name = 'ChannelCode')
	BEGIN
		ALTER TABLE dbo.MemberInfo
			ADD ChannelCode VARCHAR(50) NULL;  -- Nullable per requirement
		PRINT 'Column ChannelCode added to dbo.MemberInfo';
	END
	ELSE
	BEGIN  PRINT 'Column ChannelCode already exists';END;
	GO

/*============================================
  2. Add MemberInfo_ChannelCode_CutOffDate flag in SystemSettings
============================================*/
	DECLARE @SName SYSNAME = 'MemberInfo_ChannelCode_CutOffDate';
	DECLARE @SValue VARCHAR(50) = '2025-12-01';

	IF EXISTS (SELECT 1 FROM dbo.SystemSettings WHERE SName = @SName)
	BEGIN
		UPDATE dbo.SystemSettings
		SET SValue = @SValue
		WHERE SName = @SName;
		PRINT 'SystemSettings updated: ' + @SName + ' -> ' + @SValue;
	END
	ELSE
	BEGIN
		INSERT INTO dbo.SystemSettings (SName, SValue)
		VALUES (@SName, @SValue);
		PRINT 'SystemSettings inserted: ' + @SName + ' -> ' + @SValue;
	END