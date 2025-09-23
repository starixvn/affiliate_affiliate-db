/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250822@Sophia
	DB: DBAFF12B-Affiliate_12B
	Task: New Landing Page Setting - Insert Module Data [RedmineId : #236797]
		- Insert initial data into LandingPage_Module table
*/
use Affiliate_12B
GO
-- Insert data into LandingPage_Module
TRUNCATE TABLE LandingPage_Module;
INSERT INTO LandingPage_Module (ModuleId, ModuleName, ModuleType, Remark, NavigateTo, IsMultipleUpload, IsRequired, IsUnique, StatusId)
VALUES
(1, 'Background', 1, 'Image', 0, 0, 1, 1, 1),
(2, 'Logo & Sponsorship', 1, 'Image', 9, 0, 1, 0, 1),
(3, 'Logo Sponsorship & Register', 1, 'Image', 9, 0, 0, 0, 1),
(4, 'Hero Image', 1, 'Image', 9, 1, 1, 0, 1),
(5, 'CTA Button', 1, 'Image', 9, 0, 1, 0, 1),
(6, 'Promo List', 1, 'Image', 9, 1, 0, 0, 1),
(7, 'Favorite Games', 1, 'Image', 9, 1, 0, 0, 1),
(8, 'Youtube', 4, 'Link', 0, 0, 0, 0, 1),
(9, 'Registration Form', 3, 'Form', 0, 0, 1, 1, 1),
(10, 'Payment Method', 1, 'Image', 9, 1, 0, 0, 1),
(11, 'Provider', 1, 'Image', 9, 1, 0, 0, 1),
(12, 'Contact Us', 2, 'Contact (Image + Account)', 0, 0, 0, 0, 1),
(13, 'Licensee & Awards', 1, 'Image', 9, 0, 1, 0, 1),
(14, 'Login Button', 5, 'Login (Image + Path)', 0, 0, 0, 0, 1);
