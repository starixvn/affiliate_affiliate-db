/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20220301@Malcolm
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Add new column
*/
ALTER TABLE dbo.News 
ADD Message_Hi NVARCHAR(4000)

DECLARE @Message TABLE (Message_EN NVARCHAR(MAX), Message_HI NVARCHAR(MAX))

INSERT INTO @Message (Message_EN, Message_HI)
VALUES 
(N'Welcome to Nova88 Affiliate Program! Register and Refer member to us and enjoy the most rewarding platform in Asia.',N'Nova88 एफिलिएट प्रोग्राम में आपका स्वागत है! रजिस्टर करें और हमारे लिए सदस्य का संदर्भ लें और एशिया में सबसे पुरस्कृत मंच का आनंद लें।')
,(N'Email Address has been used. Please choose another one!',N'ईमेल पते का उपयोग किया गया है। कृपया कोई और चुनें!')
,(N'Create customer failed. Please try again.',N'ग्राहक बनाना विफल रहा. कृपया पुन: प्रयास करें।')
,(N'Player Username has been used. Please choose another one!',N'प्लेयर यूजरनेम का इस्तेमाल किया गया है। कृपया कोई और चुनें!')
,(N'Wrong username/password.',N'ग़लत उपयोगकर्ता नाम / पासवर्ड।')
,(N'Account is closed',N'खाता बंद है')
,(N'Account is locked',N'खाता अवरोधित है')
,(N'Account is not approved',N'खाता स्वीकृत नहीं है')
,(N'The information you have entered is invalid. Please check again.',N'आपके द्वारा दर्ज की गई जानकारी अमान्य है। कृपया दोबारा जांच करें।')
,(N'You have not entered an email address that we recognise. Please try again or <a href=http://tag.ibc88.com/Affiliate/ContactUs.aspx>contact us</a>.',N'आपने कोई ईमेल पता दर्ज नहीं किया है जिसे हम पहचानते हैं। कृपया पुन: प्रयास करें या <a href=http://tag.ibc88.com/Affiliate/ContactUs.aspx>हमसे संपर्क करें</a>।')
,(N'Your account is closed. Please contact your administrator!',N'आपका खाता बंद है। कृपया अपने व्यवस्थापक से संपर्क करें!')
,(N'Account is not approved. Please contact your administrator!',N'खाता स्वीकृत नहीं है। कृपया अपने व्यवस्थापक से संपर्क करें!')
,(N'The address that you have used to request a new password is not valid.',N'नए पासवर्ड का अनुरोध करने के लिए आपने जिस पते का उपयोग किया है वह मान्य नहीं है।')
,(N'Recover password failed. Please try again!',N'पासवर्ड पुनर्प्राप्त करना विफल रहा. कृपया पुन: प्रयास करें!')
,(N'Oops, this account is having 1 pending pay out request, please update this transaction first!',N'ओह, इस खाते में 1 पे आउट अनुरोध लंबित है, कृपया पहले इस लेन-देन को अपडेट करें!')
,(N'Email Address has been used. Please choose another one!',N'ईमेल पते का उपयोग किया गया है। कृपया कोई और चुनें!')
,(N'Update process is unsuccessful. Please try again!',N'प्रक्रिया असफल है। कृपया पुन: प्रयास करें!')
,(N'Invalid Affiliate!',N'अमान्य सहयोगी!')
,(N'Invalid input password!',N'अमान्य इनपुट पासवर्ड!')
,(N'Invalid input status!',N'अमान्य इनपुट स्थिति!')
,(N'You can not do this function!',N'आप यह कार्य नहीं कर सकते!')
,(N'Error! Change password unsuccessfully!',N'त्रुटि! पासवर्ड बदलें असफल!')
,(N'This affiliate has been added before.',N'इस सहबद्ध को पहले जोड़ा जा चुका है।')
,(N'Error! Add favorite unsuccessfully!',N'त्रुटि! पसंदीदा जोड़ें असफल!')
,(N'This affiliate has not been added before.',N'इस सहबद्ध को पहले नहीं जोड़ा गया है।')
,(N'Error! Delete favorite unsuccessfully!',N'त्रुटि! पसंदीदा हटाना असफल !')
,(N'This transaction is not a withdrawal.',N'यह लेन-देन निकासी नहीं है।')
,(N'Oops, You do not have permission to update this transaction.',N'ओह, आपको इस लेन-देन को अपडेट करने की अनुमति नहीं है।')
,(N'Update failed. Please try again!',N'अपडेट विफल हुआ। कृपया पुन: प्रयास करें!')
,(N'Invalid Balance Account.',N'अमान्य शेष खाता.')
,(N'Sorry, you do not have enough money to withdraw.',N'क्षमा करें, आपके पास निकालने के लिए पर्याप्त धन नहीं है।')
,(N'Sorry, amount is invalid.',N'क्षमा करें, राशि अमान्य है।')
,(N'Sorry, only Player Account method is supported. Please contact your Administrator.',N'क्षमा करें, केवल प्लेयर खाता पद्धति समर्थित है। कृपया अपने व्यवस्थापक से संपर्क करें।')
,(N'Sorry, this affiliate does not have Player Account. Please contact your Administrator.',N'क्षमा करें, इस सहयोगी के पास प्लेयर खाता नहीं है। कृपया अपने व्यवस्थापक से संपर्क करें।')
,(N'Sorry, this affiliate does not have Player Account.',N'क्षमा करें, इस सहयोगी के पास प्लेयर खाता नहीं है।')
,(N'Invalid request amount! Amount must be between {MinAmount} and {MaxAmount}',N'अमान्य अनुरोध राशि! राशि {MinAmount} और {MaxAmount} के बीच होनी चाहिए')
,(N'Insert transaction failed. Please try again!',N'सम्मिलित लेनदेन विफल। कृपया पुन: प्रयास करें!')
,(N'Group name is invalid!',N'समूह का नाम अमान्य है!')
,(N'Group name is already existed',N'समूह का नाम पहले से मौजूद है')
,(N'Oops, maximum of 50 tiers are allowed!',N'ओह, अधिकतम 50 स्तरों की अनुमति है!')
,(N'Error! Invalid Tier Setting!',N'त्रुटि! अमान्य टियर सेटिंग!')
,(N'Failed to insert new group! Please try again!',N'नया समूह सम्मिलित करने में विफल! कृपया पुन: प्रयास करें!')
,(N'Group is not existed',N'समूह मौजूद नहीं है')
,(N'Failed to update group! Please try again!',N'समूह अपडेट करने में विफल! कृपया पुन: प्रयास करें!')
,(N'At least 1 affiliate was assigned to this group. You cannot delete it.',N'इस समूह को कम से कम 1 सहयोगी असाइन किया गया था। आप इसे हटा नहीं सकते।')
,(N'Failed to delete group! Please try again!',N'समूह हटाने में विफल! कृपया पुन: प्रयास करें!')

UPDATE m WITH(ROWLOCK)
	SET m.MessageContentHIEN = e.Message_HI
FROM dbo.Messages m
	INNER JOIN @Message e ON e.Message_EN = m.MessageContentEN

UPDATE m WITH(ROWLOCK)
	SET m.Message_Hi = e.Message_HI
FROM dbo.News m
	INNER JOIN @Message e ON e.Message_EN = m.Message_En