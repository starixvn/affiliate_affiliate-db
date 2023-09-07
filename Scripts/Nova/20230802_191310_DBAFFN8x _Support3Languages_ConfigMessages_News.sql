/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20230802@Sally
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: N88 Aff - Support 3 more languages  [RedmineID: #191310]
		- Add New Column to market, Messages  
		- Translate Languages Cambo, Vn, Banglades for Messages, News
*/

---1. Add 3 languages to market, Messages  
	ALTER TABLE dbo.Messages
	ADD MessageContentKH NVARCHAR(4000) NULL,
		MessageContentBN NVARCHAR(4000) NULL
	GO
	ALTER TABLE dbo.News 
	ADD Message_Kh NVARCHAR(4000) NULL,
		Message_Bn NVARCHAR(4000) NULL
	GO

--2.Translate Languages Cambo, Vn, Banglades for Messages, News	
	DROP TABLE IF EXISTS #Message;
	CREATE TABLE #Message(
		Message_EN NVARCHAR(4000), 
		Message_Kh NVARCHAR(4000), 
		Message_Bn NVARCHAR(4000), 
		Message_Vn NVARCHAR(4000)
	)

	INSERT INTO #Message(
		Message_EN,
		Message_Kh,
		Message_Bn,
		Message_Vn)
	SELECT t.En
		,t.Kh
		,t.Bn
		,t.Vn
	FROM (
		SELECT N'Account is closed' AS En, N'অ্যাকাউন্ট বন্ধ হয়েছে' AS Bn,  N'គណនីត្រូវបានបិទ' AS Kh, N'Tài khoản bị đóng' AS Vn UNION ALL
		SELECT N'Account is locked' AS En, N'অ্যাকাউন্ট লক হয়েছে' AS Bn,  N'គណនីត្រូវបានចាក់សោ' AS Kh, N'Tài khoản bị khóa' AS Vn UNION ALL
		SELECT N'Account is not approved' AS En, N'অ্যাকাউন্ট অনুমোদিত হয়নি' AS Bn,  N'គណនីមិនត្រូវបានអនុម័តទេ' AS Kh, N'Tài khoản chưa được duyệt.' AS Vn UNION ALL
		SELECT N'Account is not approved. Please contact your administrator!' AS En, N'অ্যাকাউন্টটি অনুমোদিত হয়নি। দয়া করে আপনার প্রশাসকের সাথে যোগাযোগ করুন!' AS Bn,  N'គណនីមិនត្រូវបានអនុម័តទេ។ សូមទាក់ទងទៅកាន់អ្នកគ្រប់គ្រងរបស់អ្នក!' AS Kh, N'Tài khoản chưa được duyệt. Vui lòng liên hệ với quản lý cuả bạn!' AS Vn UNION ALL
		SELECT N'At least 1 affiliate was assigned to this group. You cannot delete it.' AS En, N'একটি অ্যাফিলিয়েটের সাথে কমপক্ষে 1 টি গ্রুপ সংযুক্ত হয়েছে। আপনি এটি মুছতে পারবেন না।' AS Bn,  N'យ៉ាងហោចណាស់មានសាខាសម្ព័ន្ធ 1 ត្រូវបានចាត់តាំងឱ្យក្រុមនេះ។ អ្នកមិនអាចលុបវាចេញបានទេ។' AS Kh, N'Cần phân ít nhất một đại lý vào nhóm này. Bạn không thể xóa.' AS Vn UNION ALL
		SELECT N'Create customer failed. Please try again.' AS En, N'গ্রাহক তৈরি করা ব্যর্থ হয়েছে। দয়া করে আবার চেষ্টা করুন।' AS Bn,  N'ការបង្កើតអតិថិជនបានបរាជ័យ។ សូម​ព្យាយាម​ម្តង​ទៀត។' AS Kh, N'Tạo tài khoản không thành công. Vui lòng thử lại.' AS Vn UNION ALL
		SELECT N'Email Address has been used. Please choose another one!' AS En, N'ইমেল ঠিকানা ব্যবহৃত হয়ে গেছে। দয়া করে আরেকটি চয়ন করুন!' AS Bn,  N'អាសយដ្ឋានអ៊ីមែលត្រូវបានប្រើប្រាស់រួចហើយ។ សូមជ្រើសរើសមួយផ្សេងទៀត!' AS Kh, N'Email này đã được sử dụng. Vui lòng chọn cái khác!' AS Vn UNION ALL
		SELECT N'Error! Add favorite unsuccessfully!' AS En, N'ত্রুটি! প্রিয় যোগ করা যায়নি!' AS Bn,  N'កំហុស! ចំណូលចិត្តបញ្ជូលបន្ដែមមិនទទួលបានជោគជ័យទេ!' AS Kh, N'Đã có lỗi xảy ra! Thêm vào danh sách yêu thích không thành công.' AS Vn UNION ALL
		SELECT N'Error! Change password unsuccessfully!' AS En, N'ত্রুটি! পাসওয়ার্ড পরিবর্তন অসফল হয়েছে!' AS Bn,  N'កំហុស! ប្តូរលេខសម្ងាត់មិនទទួលបានជោគជ័យទេ!' AS Kh, N'Đã có lỗi xảy ra! Thay đổi mật khẩu không thành công.' AS Vn UNION ALL
		SELECT N'Error! Delete favorite unsuccessfully!' AS En, N'ত্রুটি! প্রিয় মুছে ফেলা যায়নি!' AS Bn,  N'កំហុស! លុប​ចំណូលចិត្ត​​មិនទទួលបាន​ជោគជ័យទេ!' AS Kh, N'Đã có lỗi xảy ra! Xóa khỏi danh sách yêu thích không thành công.' AS Vn UNION ALL
		SELECT N'Error! Invalid Tier Setting!' AS En, N'ত্রুটি! অবৈধ টিয়ার সেটিং!' AS Bn,  N'កំហុស! ការកំណត់កម្រិតមិនត្រឹមត្រូវ!' AS Kh, N'Đã có lỗi xảy ra! Cài đặt cấp không hợp lệ.' AS Vn UNION ALL
		SELECT N'Failed to delete group! Please try again!' AS En, N'গ্রুপ মুছতে ব্যর্থ হয়েছে! দয়া করে আবার চেষ্টা করুন!' AS Bn,  N'បរាជ័យក្នុងការលុបក្រុមចេញ! សូម​ព្យាយាម​ម្តង​ទៀត!' AS Kh, N'Xóa nhóm không thành công. Vui lòng thử lại.' AS Vn UNION ALL
		SELECT N'Failed to insert new group! Please try again!' AS En, N'নতুন গ্রুপ যোগ করা ব্যর্থ হয়েছে! দয়া করে আবার চেষ্টা করুন!' AS Bn,  N'ការបញ្ចូលក្រុមថ្មីទទួលបរាជ័យ! សូម​ព្យាយាម​ម្តង​ទៀត!' AS Kh, N'Không thể chèn nhóm mới. Vui lòng thử lại.' AS Vn UNION ALL
		SELECT N'Failed to update group! Please try again!' AS En, N'গ্রুপ আপডেট করতে ব্যর্থ হয়েছে! দয়া করে আবার চেষ্টা করুন!' AS Bn,  N'បរាជ័យក្នុងការអាបឌេតបច្ចុប្បន្នភាពនៃក្រុម! សូម​ព្យាយាម​ម្តង​ទៀត!' AS Kh, N'Cập nhật nhóm không thành công. Vui lòng thử lại.' AS Vn UNION ALL
		SELECT N'Group is not existed' AS En, N'গ্রুপ অস্তিত্ব নেই' AS Bn,  N'ក្រុមមិនមានទេ' AS Kh, N'Nhóm không tồn tại' AS Vn UNION ALL
		SELECT N'Group name is already existed' AS En, N'গ্রুপের নাম ইতিমধ্যে বিদ্যমান' AS Bn,  N'ឈ្មោះក្រុមមានរួចហើយ' AS Kh, N'Tên nhóm này đã tồn tại.' AS Vn UNION ALL
		SELECT N'Group name is invalid!' AS En, N'গ্রুপের নাম অবৈধ!' AS Bn,  N'ឈ្មោះក្រុមមិនត្រឹមត្រូវទេ!' AS Kh, N'Tên nhóm không hợp lệ.' AS Vn UNION ALL
		SELECT N'Insert transaction failed. Please try again!' AS En, N'ইনসার্ট লেনদেন ব্যর্থ হয়েছে। দয়া করে আবার চেষ্টা করুন!' AS Bn,  N'ការបញ្ចូលប្រតិបត្តិការទទួលបានបរាជ័យ។ សូម​ព្យាយាម​ម្តង​ទៀត!' AS Kh, N'Gửi yêu cầu rút tiền không thành công. Vui lòng thử lại!' AS Vn UNION ALL
		SELECT N'Invalid Affiliate!' AS En, N'অবৈধ এফিলিয়েট!' AS Bn,  N'សាខាសម្ព័ន្ធមិនត្រឹមត្រូវ!' AS Kh, N'Affiliate này không tồn tại!' AS Vn UNION ALL
		SELECT N'Invalid Balance Account.' AS En, N'অবৈধ ব্যালেন্স অ্যাকাউন্ট।' AS Bn,  N'គណនីសមតុល្យភាពមិនត្រឹមត្រូវ។' AS Kh, N'Số dư tài khoản không khả dụng.' AS Vn UNION ALL
		SELECT N'Invalid input password!' AS En, N'অবৈধ ইনপুট পাসওয়ার্ড!' AS Bn,  N'លេខសម្ងាត់បានបញ្ចូលមិនត្រឹមត្រូវ!' AS Kh, N'Mật khẩu không đúng!' AS Vn UNION ALL
		SELECT N'Invalid input status!' AS En, N'অবৈধ ইনপুট স্থিতি!' AS Bn,  N'ស្ថានភាពបានបញ្ចូលមិនត្រឹមត្រូវ!' AS Kh, N'Tình trạng không đúng!' AS Vn UNION ALL
		SELECT N'Invalid request amount! Amount must be between {MinAmount} and {MaxAmount}' AS En, N'অকার্যকর অনুরোধ পরিমাণ! পরিমাণ অবশ্যই {MinAmount} এবং {MaxAmount} এর মধ্যে হতে হবে।' AS Bn,  N'ចំនួនទឹកប្រាក់ដែលស្នើសុំមិនត្រឹមត្រូវ! ចំនួនទឹកប្រាក់ត្រូវតែស្ថិតនៅចន្លោះ {ចំនួនអប្បបរមា} និង {ចំនួនអតិបរមា}' AS Kh, N'Giá trị không hợp lệ! Giá trị phải nằm trong khoảng {MinAmount} đến {MaxAmount}' AS Vn UNION ALL
		SELECT N'Oops, maximum of 50 tiers are allowed!' AS En, N'উপস! সর্বাধিক 50 টিয়ারের অনুমতি প্রদান করা হয়!' AS Bn,  N'អូ៎ កម្រិតអតិបរមា ៥០ ត្រូវបានអនុញ្ញាតហើយ!' AS Kh, N'Tối đa chỉ có 50 cấp.' AS Vn UNION ALL
		SELECT N'Oops, this account is having 1 pending pay out request, please update this transaction first!' AS En, N'উফ, এই অ্যাকাউন্টটির 1 টি মুলতিরুদ্ধারের অনুরোধ রয়েছে, দয়া করে প্রথমে এই লেনদেনটি আপডেট করুন!' AS Bn,  N'អូ! គណនីនេះកំពុងមានសំណើបង់ប្រាក់ 1 ដែលមិនទាន់សម្រេច សូមធ្វើសម្រេចបច្ចុប្បន្នភាពប្រតិបត្តិការនេះជាមុនសិន!' AS Kh, N'Tài khoản này hiện có 1 yêu cầu thanh toán chờ xử lý. Vui lòng hoàn tất yêu cầu giao dịch này trước!' AS Vn UNION ALL
		SELECT N'Oops, You do not have permission to update this transaction.' AS En, N'ওহ, আপনার এই লেনদেনটি আপডেট করার অনুমতি নেই।' AS Bn,  N'អូ! អ្នកមិនមានសិទ្ធិអាបឌេតបច្ចុប្បន្នភាពនៃប្រតិបត្តិការនេះទេ។' AS Kh, N'Xin lỗi, bạn không có quyền trên giao dịch này.' AS Vn UNION ALL
		SELECT N'Player Username has been used. Please choose another one!' AS En, N'প্লেয়ার ব্যবহারকারী নাম ব্যবহৃত হয়ে গেছে। দয়া করে আরেকটি চয়ন করুন!' AS Bn,  N'ឈ្មោះគណនីអ្នករបស់អ្នកត្រូវបានប្រើប្រាស់រួចហើយ។សូមជ្រើសរើសមួយផ្សេងទៀត!' AS Kh, N'Tên tài khoản này đã được sử dụng. Vui lòng chọn cái khác!' AS Vn UNION ALL
		SELECT N'Recover password failed. Please try again!' AS En, N'পাসওয়ার্ড পুনরুদ্ধার ব্যর্থ হয়েছে। দয়া করে আবার চেষ্টা করুন!' AS Bn,  N'លេខសម្ងាត់ស្តារឡើងវិញបានបរាជ័យ។ សូម​ព្យាយាម​ម្តង​ទៀត!' AS Kh, N'Khôi phục mật khẩu không thành công. Vui lòng thử lại!' AS Vn UNION ALL
		SELECT N'Sorry, amount is invalid.' AS En, N'দুঃখিত, পরিমাণ অবৈধ।' AS Bn,  N'សូមអភ័យទោស ចំនួនទឹកប្រាក់មិនត្រឹមត្រូវទេ។' AS Kh, N'Xin lỗi, giá trị không hợp lệ.' AS Vn UNION ALL
		SELECT N'Sorry, only Player Account method is supported. Please contact your Administrator.' AS En, N'দুঃখিত, শুধুমাত্র প্লেয়ার অ্যাকাউন্ট পদ্ধতি সমর্থন করা হয়। দয়া করে আপনার প্রশাসকের সাথে যোগাযোগ করুন।' AS Bn,  N'សូមអភ័យទោស មានតែរគណនីបែបវិធីសាស្ត្ររបស់អ្នកលេងប៉ុណ្ណោះដែលត្រូវបានគាំទ្រ។ សូមទាក់ទងទៅអ្នកគ្រប់គ្រងរបស់អ្នក។' AS Kh, N'Xin lỗi, hệ thống chỉ hỗ trợ rút tiền thông qua tài khoản cá cược. Vui lòng liên hệ với quản lý của bạn.' AS Vn UNION ALL
		SELECT N'Sorry, this affiliate does not have Player Account.' AS En, N'দুঃখিত, এই এফিলিয়েটের কোনও প্লেয়ার অ্যাকাউন্ট নেই।' AS Bn,  N'សូមអភ័យទោស សាខាសម្ព័ន្ធនេះមិនមានគណនីអ្នកលេងទេ។' AS Kh, N'Rất tiếc, đại lý này không có Tài khoản người chơi.' AS Vn UNION ALL
		SELECT N'Sorry, this affiliate does not have Player Account. Please contact your Administrator.' AS En, N'দুঃখিত, এই এফিলিয়েটটির কাছে কোনও প্লেয়ার অ্যাকাউন্ট নেই। দয়া করে আপনার প্রশাসকের সাথে যোগাযোগ করুন।' AS Bn,  N'សូមអភ័យទោស សាខាសម្ព័ន្ធនេះមិនមានគណនីអ្នកលេងទេ។ សូមទាក់ទងទៅអ្នកគ្រប់គ្រងរបស់អ្នក។' AS Kh, N'Xin lỗi, Affilate này hiện chưa có tài khoản cá cược để rút tiền. Vui lòng liên hệ với quản lý của bạn.' AS Vn UNION ALL
		SELECT N'Sorry, you do not have enough money to withdraw.' AS En, N'দুঃখিত, আপনি উত্তোলন করতে যথেষ্ট টাকা রাখেন না।' AS Bn,  N'សូមអភ័យទោស អ្នកមិនមានទឹកប្រាក់គ្រប់គ្រាន់ដើម្បីដកប្រាក់ទេ។' AS Kh, N'Xin lỗi, số tiền trong tài khoản hiện không đủ.' AS Vn UNION ALL
		SELECT N'The address that you have used to request a new password is not valid.' AS En, N'আপনি নতুন পাসওয়ার্ড অনুরোধ করতে ব্যবহৃত ঠিকানা সঠিক নয়।' AS Bn,  N'អាសយដ្ឋានដែលអ្នកបានប្រើដើម្បីស្នើសុំលេខសម្ងាត់ថ្មីគឺមិនត្រឹមត្រូវទេ។' AS Kh, N'Email dùng để nhận mật khẩu mới không không hợp lệ.' AS Vn UNION ALL
		SELECT N'The information you have entered is invalid. Please check again.' AS En, N'আপনি প্রদত্ত তথ্যটি অবৈধ বলে প্রদর্শিত হয়েছে। দয়া করে আবার পরীক্ষা করুন।' AS Bn,  N'ព័ត៌មានដែលអ្នកបានបញ្ចូលមិនត្រឹមត្រូវទេ។ សូមពិនិត្យម្តងទៀត' AS Kh, N'Thông tin bạn đã nhập không hợp lệ. Vui lòng kiểm tra lại.' AS Vn UNION ALL
		SELECT N'This affiliate has been added before.' AS En, N'এই এফিলিয়েটটি ইতিমধ্যে যুক্ত হয়েছে।' AS Bn,  N'សាខាសម្ព័ន្ធនេះត្រូវបានបញ្ជូលពីមុនរួចហើយ។' AS Kh, N'Đại lý này đã được thêm vào trước đó.' AS Vn UNION ALL
		SELECT N'This affiliate has not been added before.' AS En, N'এই এফিলিয়েটটি আগে যোগ করা হয়নি।' AS Bn,  N'សាខាសម្ព័ន្ធនេះមិនទាន់បានបញ្ជូលបន្ថែមពីមុនទេ។' AS Kh, N'Đại lý này chưa được thêm vào trước đây.' AS Vn UNION ALL
		SELECT N'This transaction is not a withdrawal.' AS En, N'এই লেনদেনটি একটি উত্তোলন নয়।' AS Bn,  N'ប្រតិបត្តិការនេះមិនមែនជាការដកប្រាក់ទេ។' AS Kh, N'Đây không phải là giao dịch rút tiền.' AS Vn UNION ALL
		SELECT N'Update failed. Please try again!' AS En, N'আপডেট ব্যর্থ হয়েছে। দয়া করে আবার চেষ্টা করুন!' AS Bn,  N'ការអាប់ដេតទទួលបានបរាជ័យ។ សូម​ព្យាយាម​ម្តង​ទៀត!' AS Kh, N'Cập nhật không thành công. Vui lòng thử lại!' AS Vn UNION ALL
		SELECT N'Update process is unsuccessful. Please try again!' AS En, N'আপডেট প্রক্রিয়া ব্যর্থ হয়েছে। দয়া করে আবার চেষ্টা করুন!' AS Bn,  N'ដំណើរការអាប់ដេតមិនជោគជ័យទេ។ សូម​ព្យាយាម​ម្តង​ទៀត!' AS Kh, N'Quá trình cập nhật không thành công. Vui lòng thử lại!' AS Vn UNION ALL
		SELECT N'Welcome to Nova88 Affiliate Program! Register and Refer member to us and enjoy the most rewarding platform in Asia.' AS En, N'Nova88 অফিলিয়েট প্রোগ্রামে আপনাকে স্বাগতম! নিবন্ধন করুন এবং আমাদেরকে সদস্যের নিবন্ধন করুন এবং এশিয়ার সবচেয়ে অধিক প্রতিদান প্রদান করার মাধ্যমটি অবলম্বন করুন।' AS Bn,  N'សូមស្វាគមន៍មកកាន់កម្មវិធីសាខាសម្ព័ន្ធ Nova88! ចុះឈ្មោះ និង បញ្ជូនសមាជិកមកកាន់ពួកយើង ហើយរីករាយជាមួយវេទិកាដែលផ្តល់រង្វាន់ច្រើនបំផុតនៅអាស៊ី។' AS Kh, N'Xin chào mừng bạn đến Chương trình Đại Lý Nova88! Đăng ký và tìm người chơi mới, rinh tiền thưởng về nhà trên nền tảng thưởng lớn nhất châu Á.' AS Vn UNION ALL
		SELECT N'Wrong username/password.' AS En, N'ভুল ব্যবহারকারীনামা / পাসওয়ার্ড।' AS Bn,  N'ឈ្មោះគណនីអ្នកប្រើ/លេខសម្ងាត់ខុស។' AS Kh, N'Sai tên đăng nhập/ mật khẩu' AS Vn UNION ALL
		SELECT N'You can not do this function!' AS En, N'আপনি এই কার্যটি করতে পারবেন না!' AS Bn,  N'មុខងារនេះអ្នកមិនអាចធ្វើបានទេ!' AS Kh, N'Bạn không được quyền sử dụng chức năng này.' AS Vn UNION ALL
		SELECT N'You have not entered an email address that we recognise. Please try again or <a href=http://tag.ibc88.com/Affiliate/ContactUs.aspx>contact us</a>.' AS En, N'আমরা একটি পরিচিত ইমেল ঠিকানা লেখনি। দয়া করে আবার চেষ্টা করুন অথবা <a href=http://tag.ibc88.com/Affiliate/ContactUs.aspx>যোগাযোগ করুন</a>।' AS Bn,  N'អ្នកមិនបានបញ្ចូលអាសយដ្ឋានអ៊ីមែលដែលយើងទទួលស្គាល់ទេ។ សូមព្យាយាមម្តងទៀត ឬ <a href=http://tag.ibc88.com/Affiliate/ContactUs.aspx>ទាក់ទងមកយើងខ្ញុំ</a>' AS Kh, N'Email này không có. Vui lòng thử lại hoặc <a href=http://tag.ibc88.com/Affiliate/ContactUs.aspx>Liên hệ chúng tôi</a>.' AS Vn UNION ALL
		SELECT N'Your account is closed. Please contact your administrator!' AS En, N'আপনার অ্যাকাউন্ট বন্ধ হয়েছে। দয়া করে আপনার প্রশাসকের সাথে যোগাযোগ করুন!' AS Bn,  N'គណនីរបស់អ្នកត្រូវបានបិទ។ សូមទាក់ទងទៅកាន់អ្នកគ្រប់គ្រងរបស់អ្នក!' AS Kh, N'Tài khoản bị đóng. Vui lòng liên hệ với quản lý cuả bạn!' AS Vn 
	) AS t

	UPDATE M SET M.MessageContentVN = MS.Message_Vn
		,M.MessageContentKH = Message_Kh
		,M.MessageContentBN = MS.Message_Bn
	FROM dbo.Messages M WITH (UPDLOCK,ROWLOCK)
		INNER JOIN #Message MS ON M.MessageContentEN = MS.Message_EN

	UPDATE M SET M.Message_Vi = MS.Message_Vn
		,M.Message_Kh = MS.Message_Kh
		,M.Message_Bn = MS.Message_Bn
	FROM dbo.News M WITH (UPDLOCK,ROWLOCK)
		INNER JOIN #Message MS ON M.Message_En = MS.Message_EN

		;
	