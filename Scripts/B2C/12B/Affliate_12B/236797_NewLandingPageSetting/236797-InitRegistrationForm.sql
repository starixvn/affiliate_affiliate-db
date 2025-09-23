/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" isFunction="0" isNested="0"></info>*/
/*
	Created: 20250918@Sally	
	Task: Init Registration Form data
	DB: DBAFF12B-Affiliate_12B
	
	Revisions:
		- 20250918@Sally: Created [RedmineID: #236797]

	Description:
		- Create temporary table to store registration form data
        - Delete existing records with matching MediaCode values from LandingPage_MediaGallery
        - Insert the data from the temporary table into LandingPage_MediaGallery with Creator and CreatedDate
*/
USE Affiliate_12B
GO

-- Declare the CustID variable and set its value
DECLARE @CustID INT = 0;
DECLARE @tblMediaCode TABLE (MediaId INT, MediaCode VARCHAR(10))

SELECT @CustID = CustId 
FROM dbo.Affiliate_User WITH (NOLOCK) 
WHERE UserName = 'AACandy';

-- Create a temporary table to store the registration form data
CREATE TABLE #TempRegistrationFormData (
    [MediaName] VARCHAR(200),
    [FileName]  VARCHAR(200),
    [ModuleId] INT,
    [Dimension] VARCHAR(20),
    [TargetCountryCode] VARCHAR(50),
    [MarketId] VARCHAR(50),
    [StatusId] TINYINT,
    [MediaCode] VARCHAR(10)
);

-- Insert the data from the VALUES in the original script into the temporary table
INSERT INTO #TempRegistrationFormData ([MediaName], [FileName], [ModuleId], [Dimension], [TargetCountryCode], [MarketId], [StatusId], [MediaCode])
VALUES 
    ('Form_en_theme-gold_TC', 'Asset/Malaysia/English/RegistrationForm/Form_en_theme-gold_TC.png', '9', '390x844', 'MY', 'en-US', '1', 'F1'),
    ('Form_en_theme-gold', 'Asset/Malaysia/English/RegistrationForm/Form_en_theme-gold.png', '9', '390x844', 'MY', 'en-US', '1', 'F2'),
    ('Form_en_theme-yellow_TC', 'Asset/Malaysia/English/RegistrationForm/Form_en_theme-yellow_TC.png', '9', '390x844', 'MY', 'en-US', '1', 'F11'),
    ('Form_en_theme-yellow', 'Asset/Malaysia/English/RegistrationForm/Form_en_theme-yellow.png', '9', '390x844', 'MY', 'en-US', '1', 'F12'),
    ('Form_en_theme-orange_TC', 'Asset/Malaysia/English/RegistrationForm/Form_en_theme-orange_TC.png', '9', '390x844', 'MY', 'en-US', '1', 'F21'),
    ('Form_en_theme-orange', 'Asset/Malaysia/English/RegistrationForm/Form_en_theme-orange.png', '9', '390x844', 'MY', 'en-US', '1', 'F22'),
    ('Form_en_theme-green_TC', 'Asset/Malaysia/English/RegistrationForm/Form_en_theme-green_TC.png', '9', '390x844', 'MY', 'en-US', '1', 'F31'),
    ('Form_en_theme-green', 'Asset/Malaysia/English/RegistrationForm/Form_en_theme-green.png', '9', '390x844', 'MY', 'en-US', '1', 'F32'),
    ('Form_en_theme-lightgreen_TC', 'Asset/Malaysia/English/RegistrationForm/Form_en_theme-lightgreen_TC.png', '9', '390x844', 'MY', 'en-US', '1', 'F41'),
    ('Form_en_theme-lightgreen', 'Asset/Malaysia/English/RegistrationForm/Form_en_theme-lightgreen.png', '9', '390x844', 'MY', 'en-US', '1', 'F42'),
    ('Form_en_theme-sky_TC', 'Asset/Malaysia/English/RegistrationForm/Form_en_theme-sky_TC.png', '9', '390x844', 'MY', 'en-US', '1', 'F51'),
    ('Form_en_theme-sky', 'Asset/Malaysia/English/RegistrationForm/Form_en_theme-sky.png', '9', '390x844', 'MY', 'en-US', '1', 'F52'),
    ('Form_en_theme-navy_TC', 'Asset/Malaysia/English/RegistrationForm/Form_en_theme-navy_TC.png', '9', '390x844', 'MY', 'en-US', '1', 'F61'),
    ('Form_en_theme-navy', 'Asset/Malaysia/English/RegistrationForm/Form_en_theme-navy.png', '9', '390x844', 'MY', 'en-US', '1', 'F62'),
    ('Form_en_theme-pink_TC', 'Asset/Malaysia/English/RegistrationForm/Form_en_theme-pink_TC.png', '9', '390x844', 'MY', 'en-US', '1', 'F71'),
    ('Form_en_theme-pink', 'Asset/Malaysia/English/RegistrationForm/Form_en_theme-pink.png', '9', '390x844', 'MY', 'en-US', '1', 'F72'),
    ('Form_en_theme-purple_TC', 'Asset/Malaysia/English/RegistrationForm/Form_en_theme-purple_TC.png', '9', '390x844', 'MY', 'en-US', '1', 'F81'),
    ('Form_en_theme-purple', 'Asset/Malaysia/English/RegistrationForm/Form_en_theme-purple.png', '9', '390x844', 'MY', 'en-US', '1', 'F82'),
    ('Form_vn_theme-gold_TC', 'Asset/Vietnam/Vietnamese/RegistrationForm/Form_vn_theme-gold_TC.png', '9', '390x844', 'VN', 'vi-VN', '1', 'F3'),
    ('Form_vn_theme-gold', 'Asset/Vietnam/Vietnamese/RegistrationForm/Form_vn_theme-gold.png', '9', '390x844', 'VN', 'vi-VN', '1', 'F4'),
    ('Form_vn_theme-yellow_TC', 'Asset/Vietnam/Vietnamese/RegistrationForm/Form_vn_theme-yellow_TC.png', '9', '390x844', 'VN', 'vi-VN', '1', 'F13'),
    ('Form_vn_theme-yellow', 'Asset/Vietnam/Vietnamese/RegistrationForm/Form_vn_theme-yellow.png', '9', '390x844', 'VN', 'vi-VN', '1', 'F14'),
    ('Form_vn_theme-orange_TC', 'Asset/Vietnam/Vietnamese/RegistrationForm/Form_vn_theme-orange_TC.png', '9', '390x844', 'VN', 'vi-VN', '1', 'F23'),
    ('Form_vn_theme-orange', 'Asset/Vietnam/Vietnamese/RegistrationForm/Form_vn_theme-orange.png', '9', '390x844', 'VN', 'vi-VN', '1', 'F24'),
    ('Form_vn_theme-green_TC', 'Asset/Vietnam/Vietnamese/RegistrationForm/Form_vn_theme-green_TC.png', '9', '390x844', 'VN', 'vi-VN', '1', 'F33'),
    ('Form_vn_theme-green', 'Asset/Vietnam/Vietnamese/RegistrationForm/Form_vn_theme-green.png', '9', '390x844', 'VN', 'vi-VN', '1', 'F34'),
    ('Form_vn_theme-lightgreen_TC', 'Asset/Vietnam/Vietnamese/RegistrationForm/Form_vn_theme-lightgreen_TC.png', '9', '390x844', 'VN', 'vi-VN', '1', 'F43'),
    ('Form_vn_theme-lightgreen', 'Asset/Vietnam/Vietnamese/RegistrationForm/Form_vn_theme-lightgreen.png', '9', '390x844', 'VN', 'vi-VN', '1', 'F44'),
    ('Form_vn_theme-sky_TC', 'Asset/Vietnam/Vietnamese/RegistrationForm/Form_vn_theme-sky_TC.png', '9', '390x844', 'VN', 'vi-VN', '1', 'F53'),
    ('Form_vn_theme-sky', 'Asset/Vietnam/Vietnamese/RegistrationForm/Form_vn_theme-sky.png', '9', '390x844', 'VN', 'vi-VN', '1', 'F54'),
    ('Form_vn_theme-navy_TC', 'Asset/Vietnam/Vietnamese/RegistrationForm/Form_vn_theme-navy_TC.png', '9', '390x844', 'VN', 'vi-VN', '1', 'F63'),
    ('Form_vn_theme-navy', 'Asset/Vietnam/Vietnamese/RegistrationForm/Form_vn_theme-navy.png', '9', '390x844', 'VN', 'vi-VN', '1', 'F64'),
    ('Form_vn_theme-pink_TC', 'Asset/Vietnam/Vietnamese/RegistrationForm/Form_vn_theme-pink_TC.png', '9', '390x844', 'VN', 'vi-VN', '1', 'F73'),
    ('Form_vn_theme-pink', 'Asset/Vietnam/Vietnamese/RegistrationForm/Form_vn_theme-pink.png', '9', '390x844', 'VN', 'vi-VN', '1', 'F74'),
    ('Form_vn_theme-purple_TC', 'Asset/Vietnam/Vietnamese/RegistrationForm/Form_vn_theme-purple_TC.png', '9', '367x614', 'VN', 'vi-VN', '1', 'F83'),
    ('Form_vn_theme-purple', 'Asset/Vietnam/Vietnamese/RegistrationForm/Form_vn_theme-purple.png', '9', '367x553', 'VN', 'vi-VN', '1', 'F84'),
    ('Form_th_theme-gold_TC', 'Asset/Thailand/Thai/RegistrationForm/Form_th_theme-gold_TC.png', '9', '390x844', 'TH', 'th-TH', '1', 'F5'),
    ('Form_th_theme-gold', 'Asset/Thailand/Thai/RegistrationForm/Form_th_theme-gold.png', '9', '390x844', 'TH', 'th-TH', '1', 'F6'),
    ('Form_th_theme-yellow_TC', 'Asset/Thailand/Thai/RegistrationForm/Form_th_theme-yellow_TC.png', '9', '390x844', 'TH', 'th-TH', '1', 'F15'),
    ('Form_th_theme-yellow', 'Asset/Thailand/Thai/RegistrationForm/Form_th_theme-yellow.png', '9', '390x844', 'TH', 'th-TH', '1', 'F16'),
    ('Form_th_theme-orange_TC', 'Asset/Thailand/Thai/RegistrationForm/Form_th_theme-orange_TC.png', '9', '390x844', 'TH', 'th-TH', '1', 'F25'),
    ('Form_th_theme-orange', 'Asset/Thailand/Thai/RegistrationForm/Form_th_theme-orange.png', '9', '390x844', 'TH', 'th-TH', '1', 'F26'),
    ('Form_th_theme-green_TC', 'Asset/Thailand/Thai/RegistrationForm/Form_th_theme-green_TC.png', '9', '390x844', 'TH', 'th-TH', '1', 'F35'),
    ('Form_th_theme-green', 'Asset/Thailand/Thai/RegistrationForm/Form_th_theme-green.png', '9', '390x844', 'TH', 'th-TH', '1', 'F36'),
    ('Form_th_theme-lightgreen_TC', 'Asset/Thailand/Thai/RegistrationForm/Form_th_theme-lightgreen_TC.png', '9', '390x844', 'TH', 'th-TH', '1', 'F45'),
    ('Form_th_theme-lightgreen', 'Asset/Thailand/Thai/RegistrationForm/Form_th_theme-lightgreen.png', '9', '390x844', 'TH', 'th-TH', '1', 'F46'),
    ('Form_th_theme-sky_TC', 'Asset/Thailand/Thai/RegistrationForm/Form_th_theme-sky_TC.png', '9', '390x844', 'TH', 'th-TH', '1', 'F55'),
    ('Form_th_theme-sky', 'Asset/Thailand/Thai/RegistrationForm/Form_th_theme-sky.png', '9', '390x844', 'TH', 'th-TH', '1', 'F56'),
    ('Form_th_theme-navy_TC', 'Asset/Thailand/Thai/RegistrationForm/Form_th_theme-navy_TC.png', '9', '390x844', 'TH', 'th-TH', '1', 'F65'),
    ('Form_th_theme-navy', 'Asset/Thailand/Thai/RegistrationForm/Form_th_theme-navy.png', '9', '390x844', 'TH', 'th-TH', '1', 'F66'),
    ('Form_th_theme-pink_TC', 'Asset/Thailand/Thai/RegistrationForm/Form_th_theme-pink_TC.png', '9', '390x844', 'TH', 'th-TH', '1', 'F75'),
    ('Form_th_theme-pink', 'Asset/Thailand/Thai/RegistrationForm/Form_th_theme-pink.png', '9', '390x844', 'TH', 'th-TH', '1', 'F76'),
    ('Form_th_theme-purple_TC', 'Asset/Thailand/Thai/RegistrationForm/Form_th_theme-purple_TC.png', '9', '390x844', 'TH', 'th-TH', '1', 'F85'),
    ('Form_th_theme-purple', 'Asset/Thailand/Thai/RegistrationForm/Form_th_theme-purple.png', '9', '390x844', 'TH', 'th-TH', '1', 'F86'),
    ('Form_cs_theme-gold_TC', 'Asset/Malaysia/Chinese Simplified/RegistrationForm/Form_cs_theme-gold_TC.png', '9', '390x844', 'MY', 'zh-CN', '1', 'F7'),
    ('Form_cs_theme-gold', 'Asset/Malaysia/Chinese Simplified/RegistrationForm/Form_cs_theme-gold.png', '9', '390x844', 'MY', 'zh-CN', '1', 'F8'),
    ('Form_cs_theme-yellow_TC', 'Asset/Malaysia/Chinese Simplified/RegistrationForm/Form_cs_theme-yellow_TC.png', '9', '390x844', 'MY', 'zh-CN', '1', 'F17'),
    ('Form_cs_theme-yellow', 'Asset/Malaysia/Chinese Simplified/RegistrationForm/Form_cs_theme-yellow.png', '9', '390x844', 'MY', 'zh-CN', '1', 'F18'),
    ('Form_cs_theme-orange_TC', 'Asset/Malaysia/Chinese Simplified/RegistrationForm/Form_cs_theme-orange_TC.png', '9', '390x844', 'MY', 'zh-CN', '1', 'F27'),
    ('Form_cs_theme-orange', 'Asset/Malaysia/Chinese Simplified/RegistrationForm/Form_cs_theme-orange.png', '9', '390x844', 'MY', 'zh-CN', '1', 'F28'),
    ('Form_cs_theme-green_TC', 'Asset/Malaysia/Chinese Simplified/RegistrationForm/Form_cs_theme-green_TC.png', '9', '390x844', 'MY', 'zh-CN', '1', 'F37'),
    ('Form_cs_theme-green', 'Asset/Malaysia/Chinese Simplified/RegistrationForm/Form_cs_theme-green.png', '9', '390x844', 'MY', 'zh-CN', '1', 'F38'),
    ('Form_cs_theme-lightgreen_TC', 'Asset/Malaysia/Chinese Simplified/RegistrationForm/Form_cs_theme-lightgreen_TC.png', '9', '390x844', 'MY', 'zh-CN', '1', 'F47'),
    ('Form_cs_theme-lightgreen', 'Asset/Malaysia/Chinese Simplified/RegistrationForm/Form_cs_theme-lightgreen.png', '9', '390x844', 'MY', 'zh-CN', '1', 'F48'),
    ('Form_cs_theme-sky_TC', 'Asset/Malaysia/Chinese Simplified/RegistrationForm/Form_cs_theme-sky_TC.png', '9', '390x844', 'MY', 'zh-CN', '1', 'F57'),
    ('Form_cs_theme-sky', 'Asset/Malaysia/Chinese Simplified/RegistrationForm/Form_cs_theme-sky.png', '9', '390x844', 'MY', 'zh-CN', '1', 'F58'),
    ('Form_cs_theme-navy_TC', 'Asset/Malaysia/Chinese Simplified/RegistrationForm/Form_cs_theme-navy_TC.png', '9', '390x844', 'MY', 'zh-CN', '1', 'F67'),
    ('Form_cs_theme-navy', 'Asset/Malaysia/Chinese Simplified/RegistrationForm/Form_cs_theme-navy.png', '9', '390x844', 'MY', 'zh-CN', '1', 'F68'),
    ('Form_cs_theme-pink_TC', 'Asset/Malaysia/Chinese Simplified/RegistrationForm/Form_cs_theme-pink_TC.png', '9', '390x844', 'MY', 'zh-CN', '1', 'F77'),
    ('Form_cs_theme-pink', 'Asset/Malaysia/Chinese Simplified/RegistrationForm/Form_cs_theme-pink.png', '9', '390x844', 'MY', 'zh-CN', '1', 'F78'),
    ('Form_cs_theme-purple_TC', 'Asset/Malaysia/Chinese Simplified/RegistrationForm/Form_cs_theme-purple_TC.png', '9', '390x844', 'MY', 'zh-CN', '1', 'F87'),
    ('Form_cs_theme-purple', 'Asset/Malaysia/Chinese Simplified/RegistrationForm/Form_cs_theme-purple.png', '9', '390x844', 'MY', 'zh-CN', '1', 'F88'),
    ('Form_iden_theme-gold_TC', 'Asset/India/English/RegistrationForm/Form_iden_theme-gold_TC.png', '9', '390x844', 'IN', 'en-US', '1', 'F9'),
    ('Form_iden_theme-gold', 'Asset/India/English/RegistrationForm/Form_iden_theme-gold.png', '9', '390x844', 'IN', 'en-US', '1', 'F10'),
    ('Form_iden_theme-yellow_TC', 'Asset/India/English/RegistrationForm/Form_iden_theme-yellow_TC.png', '9', '390x844', 'IN', 'en-US', '1', 'F19'),
    ('Form_iden_theme-yellow', 'Asset/India/English/RegistrationForm/Form_iden_theme-yellow.png', '9', '390x844', 'IN', 'en-US', '1', 'F20'),
    ('Form_iden_theme-orange_TC', 'Asset/India/English/RegistrationForm/Form_iden_theme-orange_TC.png', '9', '390x844', 'IN', 'en-US', '1', 'F29'),
    ('Form_iden_theme-orange', 'Asset/India/English/RegistrationForm/Form_iden_theme-orange.png', '9', '390x844', 'IN', 'en-US', '1', 'F30'),
    ('Form_iden_theme-green_TC', 'Asset/India/English/RegistrationForm/Form_iden_theme-green_TC.png', '9', '390x844', 'IN', 'en-US', '1', 'F39'),
    ('Form_iden_theme-green', 'Asset/India/English/RegistrationForm/Form_iden_theme-green.png', '9', '390x844', 'IN', 'en-US', '1', 'F40'),
    ('Form_iden_theme-lightgreen_TC', 'Asset/India/English/RegistrationForm/Form_iden_theme-lightgreen_TC.png', '9', '390x844', 'IN', 'en-US', '1', 'F49'),
    ('Form_iden_theme-lightgreen', 'Asset/India/English/RegistrationForm/Form_iden_theme-lightgreen.png', '9', '390x844', 'IN', 'en-US', '1', 'F50'),
    ('Form_iden_theme-sky_TC', 'Asset/India/English/RegistrationForm/Form_iden_theme-sky_TC.png', '9', '390x844', 'IN', 'en-US', '1', 'F59'),
    ('Form_iden_theme-sky', 'Asset/India/English/RegistrationForm/Form_iden_theme-sky.png', '9', '390x844', 'IN', 'en-US', '1', 'F60'),
    ('Form_iden_theme-navy_TC', 'Asset/India/English/RegistrationForm/Form_iden_theme-navy_TC.png', '9', '390x844', 'IN', 'en-US', '1', 'F69'),
    ('Form_iden_theme-navy', 'Asset/India/English/RegistrationForm/Form_iden_theme-navy.png', '9', '390x844', 'IN', 'en-US', '1', 'F70'),
    ('Form_iden_theme-pink_TC', 'Asset/India/English/RegistrationForm/Form_iden_theme-pink_TC.png', '9', '390x844', 'IN', 'en-US', '1', 'F79'),
    ('Form_iden_theme-pink', 'Asset/India/English/RegistrationForm/Form_iden_theme-pink.png', '9', '364x425', 'IN', 'en-US', '1', 'F80'),
    ('Form_iden_theme-purple_TC', 'Asset/India/English/RegistrationForm/Form_iden_theme-purple_TC.png', '9', '390x844', 'IN', 'en-US', '1', 'F89'),
    ('Form_iden_theme-purple', 'Asset/India/English/RegistrationForm/Form_iden_theme-purple.png', '9', '390x844', 'IN', 'en-US', '1', 'F90');

-- Delete any existing records with matching MediaCode values from the LandingPage_MediaGallery table
DELETE FROM LandingPage_MediaGallery WITH(ROWLOCK)
WHERE EXISTS (SELECT 1 FROM #TempRegistrationFormData t WHERE t.MediaCode = LandingPage_MediaGallery.MediaCode);

-- Set MediaId to NULL in LandingPage_MediaCode for records with matching MediaCode values
UPDATE l 
SET l.MediaId = NULL
FROM dbo.LandingPage_MediaCode l WITH (ROWLOCK, UPDLOCK)
WHERE EXISTS (SELECT 1 FROM #TempRegistrationFormData t WHERE t.MediaCode = l.MediaCode);

-- Insert the data from the temporary table into LandingPage_MediaGallery
INSERT INTO LandingPage_MediaGallery 
    (MediaName, FileName, ModuleId, Dimension, TargetCountryCode, MarketId, StatusId, MediaCode, Creator, CreatedDate)
OUTPUT INSERTED.MediaId, INSERTED.MediaCode 
INTO @tblMediaCode (MediaId, MediaCode)
SELECT 
    t.MediaName,
    t.FileName,
    t.ModuleId,
    t.Dimension,
    t.TargetCountryCode,
    t.MarketId,
    t.StatusId,
    t.MediaCode,
    @CustID AS Creator,
    DATEADD(HOUR, 8, GETUTCDATE()) AS CreatedDate
FROM 
    #TempRegistrationFormData t;

UPDATE t 
SET t.MediaId = mc.MediaId
FROM dbo.LandingPage_MediaCode t WITH (ROWLOCK, UPDLOCK)
	INNER JOIN @tblMediaCode mc ON t.MediaCode = mc.MediaCode
WHERE t.MediaId IS NULL;

-- Display the number of records inserted
SELECT COUNT(1) AS RecordsInserted FROM @tblMediaCode;

-- Clean up the temporary table
DROP TABLE #TempRegistrationFormData;