/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/

/*
	Creator: 20221208@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add Cambodia [RedmineId : #176429]
*/

ALTER TABLE dbo.Messages
ADD MessageContentKH NVARCHAR(2000)
GO

DECLARE @Msg TABLE (EN NVARCHAR(2000), KH NVARCHAR(2000))

INSERT INTO  @Msg (EN, KH)
SELECT N.EN, N.KH
FROM (
VALUES	(N'Welcome to 12Bet Affiliate Program! Register and Refer member to us and enjoy the most rewarding platform in Asia.',N'សូមស្វាគមន៍មកកាន់កម្មវិធីភ្នាក់ងារ12Bet - ចុះឈ្មោះនិងបញ្ជូនសមាជិកមកពួកយើង រីករាយជាមួយវេទិកាដែលផ្តល់រង្វាន់ជាច្រើននៅអាស៊ី។')
,(N'Email Address has been used. Please choose another one!',N'អាសយដ្ឋានអ៊ីមែលត្រូវបានប្រើប្រាស់រួចហើយ សូមជ្រើសរើសផ្សេងទៀត!')
,(N'Create customer failed. Please try again.',N'ការបង្កើតអតិថិជនបរាជ័យ សូម​ព្យាយាម​ម្តង​ទៀត។')
,(N'Player Username has been used. Please choose another one!',N'ឈ្មោះប្រើសមាជិកត្រូវបានប្រើប្រាស់រួចហើយ សូមជ្រើសរើសផ្សេងទៀត!')
,(N'Wrong username/password.',N'ឈ្មោះប្រើប្រាស់ខុស/ពាក្យសម្ងាត់ខុស')
,(N'Account is closed',N'គណនីត្រូវបានបិទ')
,(N'Account is locked',N'គណនីត្រូវបានចាក់សោ')
,(N'Account is not approved',N'គណនីមិនត្រូវបានអនុញ្ញាតទេ')
,(N'The information you have entered is invalid. Please check again.',N'ព័ត៌មានដែលអ្នកបានបញ្ចូលមិនត្រឹមត្រូវទេ។ សូមពិនិត្យម្តងទៀត។')
,(N'You have not entered an email address that we recognise. Please try again or <a href=http://tag.ibc88.com/Affiliate/ContactUs.aspx>contact us</a>.',N'អ្នកមិនបានបញ្ចូលអាសយដ្ឋានអ៊ីមែលដែលយើងទទួលស្គាល់ទេ។ សូមព្យាយាមម្តងទៀត ឬ <a href=http://tag.ibc88.com/Affiliate/ContactUs.aspx>ទាក់ទងមកយើងខ្ញុំ</a>។')
,(N'Your account is closed. Please contact your administrator!',N'គណនីរបស់អ្នកត្រូវបានបិទ។ សូមទាក់ទងអ្នកគ្រប់គ្រងរបស់អ្នក!')
,(N'Account is not approved. Please contact your administrator!',N'គណនីមិនត្រូវបានអនុញាតិទេ សូមទាក់ទងអ្នកគ្រប់គ្រងរបស់អ្នក!')
,(N'The address that you have used to request a new password is not valid.',N'អាសយដ្ឋានដែលអ្នកបានប្រើដើម្បីស្នើសុំពាក្យសម្ងាត់ថ្មីគឺមិនត្រឹមត្រូវទេ។')
,(N'Recover password failed. Please try again!',N'ការសង្គ្រោះពាក្យសម្ងាត់ត្រូវបានបរាជ័យ សូម​ព្យាយាម​ម្តង​ទៀត!')
,(N'Oops, this account is having 1 pending pay out request, please update this transaction first!',N'អូ! គណនីនេះកំពុងមានសំណើទូទាត់ប្រាក់ 1 ដែលមិនទាន់បានសម្រេច សូមធ្វើការអាប់ដេតប្រតិបត្តិការនេះជាមុនសិន!')
,(N'Email Address has been used. Please choose another one!',N'អាសយដ្ឋានអ៊ីមែលត្រូវបានប្រើប្រាស់ សូមជ្រើសរើសផ្សេងទៀត!')
,(N'Update process is unsuccessful. Please try again!',N'ដំណើរការអាប់ដេតមិនបានជោគជ័យទេ សូម​ព្យាយាម​ម្តង​ទៀត!')
,(N'Invalid Affiliate!',N'ភ្នាក់ងារមិនត្រឹមត្រូវ!')
,(N'Invalid input password!',N'បញ្ចូលពាក្យសម្ងាត់មិនត្រឹមត្រូវ!')
,(N'Invalid input status!',N'ស្ថានភាពបញ្ចូលមិនត្រឹមត្រូវ!')
,(N'You can not do this function!',N'អ្នកមិនអាចធ្វើមុខងារនេះបានទេ!')
,(N'Error! Change password unsuccessfully!',N'កំហុស! ប្តូរលេខសម្ងាត់មិនបានជោគជ័យ!')
,(N'This affiliate has been added before.',N'ភ្នាក់ងារនេះត្រូវបានបន្ថែមពីមុន។')
,(N'Error! Add favorite unsuccessfully!',N'កំហុស! បន្ថែមចំណូលចិត្តមិនបានជោគជ័យ!')
,(N'This affiliate has not been added before.',N'ភ្នាក់ងារនេះមិនត្រូវបានបន្ថែមពីមុននោះទេ')
,(N'Error! Delete favorite unsuccessfully!',N'កំហុស! លុបចំណូលចិត្តមិនបានជោគជ័យទេ!')
,(N'This transaction is not a withdrawal.',N'ប្រតិបត្តិការនេះមិនមែនជាការដកប្រាក់ទេ។')
,(N'Oops, You do not have permission to update this transaction.',N'អូ! អ្នកពុំមានសិទ្ធិធ្វើការអាប់ដេតប្រតិបត្តិការនេះទេ។')
,(N'Update failed. Please try again!',N'ការអាប់ដេតបរាជ័យ សូម​ព្យាយាម​ម្តង​ទៀត!')
,(N'Invalid Balance Account.',N'សមតុល្យគណនីមិនត្រឹមត្រូវ')
,(N'Sorry, you do not have enough money to withdraw.',N'សូមអភ័យទោស លោកអ្នកមិនមានប្រាក់គ្រប់គ្រាន់ដើម្បីដកនោះទេ។')
,(N'Sorry, amount is invalid.',N'សូមអភ័យទោស ចំនួនទឹកប្រាក់មិនត្រឹមត្រូវនោះទេ។')
,(N'Sorry, only Player Account method is supported. Please contact your Administrator.',N'សូមអភ័យទោស មានតែគណនីសំរាប់សមាជិកប៉ុណ្ណោះដែលត្រូវបានអនុញាតិ សូមទាក់ទងអ្នកគ្រប់គ្រងរបស់អ្នកដើម្បីពត៍មានបន្ថែម។')
,(N'Sorry, this affiliate does not have Player Account. Please contact your Administrator.',N'សូមអភ័យទោស សំរាប់ភ្នាក់ងារនេះមិនទាន់មានគណនីសមាជិកនោះទេ សូមទាក់ទងអ្នកគ្រប់គ្រងរបស់អ្នក។')
,(N'Sorry, this affiliate does not have Player Account.',N'សូមអភ័យទោស សំរាប់ភ្នាក់ងារនេះមិនទាន់មានគណនីសមាជិកនោះទេ។')
,(N'Invalid request amount! Amount must be between {MinAmount} and {MaxAmount}',N'ចំនួនទឹកប្រាក់ស្នើសុំមិនត្រឹមត្រូវ! ចំនួនទឹកប្រាក់ត្រូវតែស្ថិតនៅចន្លោះ {MinAmount} និង {MaxAmount}')
,(N'Insert transaction failed. Please try again!',N'ការបញ្ចូលប្រតិបត្តិការត្រូវបានបរាជ័យ សូម​ព្យាយាម​ម្តង​ទៀត!')
,(N'Group name is invalid!',N'ឈ្មោះក្រុមមិនត្រឹមត្រូវទេ!')
,(N'Group name is already existed',N'ឈ្មោះក្រុមមានរួចហើយ')
,(N'Oops, maximum of 50 tiers are allowed!',N'អូប! កម្រិតអតិបរមា 50 ត្រូវបានអនុញ្ញាត!')
,(N'Error! Invalid Tier Setting!',N'កំហុស! ការកំណត់កម្រិតមិនត្រឹមត្រូវ!')
,(N'Failed to insert new group! Please try again!',N'បរាជ័យក្នុងការបញ្ចូលក្រុមថ្មី! សូម​ព្យាយាម​ម្តង​ទៀត!')
,(N'Group is not existed',N'ក្រុមមិនមានទេ')
,(N'Failed to update group! Please try again!',N'បរាជ័យសំរាប់អាបដេតក្រុម! សូម​ព្យាយាម​ម្តង​ទៀត!')
,(N'At least 1 affiliate was assigned to this group. You cannot delete it.',N'យ៉ាងហោចណាស់ភ្នាក់ងារត្រូវមាន1ដើម្បីចាត់តាំងក្នុងក្រុមនេះ អ្នកមិនអាចលុបវាបានទេ។')
,(N'Failed to delete group! Please try again!',N'បរាជ័យក្នុងការលុបក្រុម! សូម​ព្យាយាម​ម្តង​ទៀត!')
,(N'You are not authorized on this function!',N'អ្នកមិនត្រូវបានអនុញ្ញាតលើមុខងារនេះទេ!')
,(N'With or without a website you can promote 12BET with your creative ideas and start receiving big money up to 50% COMMISSION every month even while you are sleeping!! Write to us today!!',N'ទោះបីមានឬមិនមានវេបសាយក៏ដោយ លោកអ្នកក៏អាចធ្វើការផ្សព្វផ្សាយអំពី12BETយើងបានដែរជាមួយនឹងគំនិតច្នៃប្រឌិតរបស់អ្នក។ ចាប់ផ្តើមទទួលបានប្រាក់ដ៏ធំនិងកំរៃជើងសាររហូតដល់ 50% ជារៀងរាល់ខែ ទោះបីជាអ្នកកំពុងតែគេងក៏ដោយ!! សរសេរមកយើងនៅថ្ងៃនេះ !!')
,(N'You send us customers, we send you CASH! FAST and EASY. Find out how...SIGN UP TODAY!!',N'អ្នករកអតិថិជនមកអោយយើង យើងផ្ញើលុយទៅអោយអ្នកវិញ! រហ័សនិងងាយស្រួល ស្វែងរកវិធី...ចុះឈ្មោះថ្ងៃនេះ!!')
,(N'DAILY LUCKY DRAWS, MONTHLY NEWSLETTER, EMAIL PROMOTIONS, CUSTOMER RETENTION SERVICES ARE JUST SOME OF THE WAYS WE HELP YOU TO RETAIN YOUR MEMBERS SO THAT YOU CAN CONTINUE EARNING!',N'ការចាប់រង្វាន់ប្រចាំថ្ងៃ ព្រឹត្តិបត្រព័ត៌មានប្រចាំខែ ការផ្សព្វផ្សាយតាមអ៊ីមែល សេវារក្សាអតិថិជន​ទាំងនេះគឺជាវិធីសាស្ត្រមួយដែលយើងជួយអ្នកក្នុងការរក្សាសមាជិក ដើម្បីឱ្យអ្នកអាចបន្តរកប្រាក់ចំណូលបាន!')
,(N'Our records show many of our top income affiliate earners talk to us almost daily to discuss new ways to market, latest news, sports articles, new banners, special promotions ...and more. Contact us today!',N'កំណត់ត្រារបស់យើងបានបង្ហាញអំពីភ្នាក់ងារកំពូលៗដែលជំនាញរកចំណូល ពួកគេពិភាក្សនិងនិយាយជាមួយយើងស្ទើរតែរាល់ថ្ងៃអំពីវិធីសាស្ត្រថ្មីៗក្នុងការធ្វើទីផ្សារ ព័ត៌មានចុងក្រោយថ្មីៗ អត្ថបទកីឡា បដាថ្មីៗ ប្រូម៉ូសិនពិសេសៗនិងមានជាច្រើនទៀត...សូមទាក់ទងមកយើងនៅថ្ងៃនេះ!')
,(N'Welcome to a world of business opportunities!',N'សូមស្វាគមន៍មកកាន់ពិភពនៃឱកាសអាជីវកម្ម!')
,(N'Our records show many of our top income affiliate earners talk to us almost daily to discuss new ways to market, latest news, sports articles, new banners, special promotions ...and more. Contact us today!',N'កំណត់ត្រារបស់យើងបានបង្ហាញអំពីភ្នាក់ងារកំពូលៗដែលជំនាញរកចំណូល ពួកគេពិភាក្សនិងនិយាយជាមួយយើងស្ទើរតែរាល់ថ្ងៃអំពីវិធីសាស្ត្រថ្មីៗក្នុងការធ្វើទីផ្សារ ព័ត៌មានចុងក្រោយថ្មីៗ អត្ថបទកីឡា បដាថ្មីៗ ប្រូម៉ូសិនពិសេសៗនិងមានជាច្រើនទៀត...សូមទាក់ទងមកយើងនៅថ្ងៃនេះ!')
,(N'You may update Affiliate banner of this month on your website now! Banners are available in your 12BET Affiliate account under Media Gallery.',N'អ្នកគួរតែអាបដេតបដាផ្សព្វផ្សាយគេហទំព័ររបស់អ្នកនៅក្នុងខែនេះ! បដាមាននៅក្នុងគណនីភ្នាក់ងារ 12BET របស់អ្នកក្រោម Media Gallery។')
) AS N(EN, KH)

UPDATE m WITH(ROWLOCK, UPDLOCK)
	SET m.MessageContentKH = g.KH
FROM Messages m
	INNER JOIN @Msg g ON g.EN = m.MessageContentEN

UPDATE m WITH(ROWLOCK, UPDLOCK)
	SET m.Message_Kh = g.KH
FROM News m
	INNER JOIN @Msg g ON g.EN = m.Message_En
