/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20220301@Malcolm
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Add new column
*/
ALTER TABLE dbo.News 
ADD Message_Ms NVARCHAR(4000)
GO

ALTER TABLE dbo.Messages 
ADD MessageContentMS NVARCHAR(2000)
GO

DECLARE @Message TABLE (Message_EN NVARCHAR(MAX), Message_Ms NVARCHAR(MAX))

INSERT INTO @Message (Message_EN, Message_Ms)
VALUES 
(N'Welcome to Nova88 Affiliate Program! Register and Refer member to us and enjoy the most rewarding platform in Asia.',N'Selamat datang ke Program Nova88 Affiliate! Daftar dan Rujuk ahli kepada kami dan nikmati platform paling bermanfaat di Asia.')
,(N'Email Address has been used. Please choose another one!',N'Alamat E-mel telah digunakan. Sila pilih yang lain!')
,(N'Create customer failed. Please try again.',N'Buat pelanggan gagal. Sila cuba lagi.')
,(N'Player Username has been used. Please choose another one!',N'Nama Pengguna Pemain telah digunakan. Sila pilih yang lain!')
,(N'Wrong username/password.',N'Nama pengguna/kata laluan salah.')
,(N'Account is closed',N'Akaun ditutup')
,(N'Account is locked',N'Akaun dikunci')
,(N'Account is not approved',N'Akaun tidak diluluskan')
,(N'The information you have entered is invalid. Please check again.',N'Maklumat yang anda masukkan tidak sah. Sila semak semula.')
,(N'You have not entered an email address that we recognise. Please try again or <a href=http://tag.ibc88.com/Affiliate/ContactUs.aspx>contact us</a>.',N'Anda belum memasukkan alamat e-mel yang kami kenali. Sila cuba lagi atau <a href=http://tag.ibc88.com/Affiliate/ContactUs.aspx>hubungi kami</a>.')
,(N'Your account is closed. Please contact your administrator!',N'Akaun anda telah ditutup. Sila hubungi pentadbir anda!')
,(N'Account is not approved. Please contact your administrator!',N'Akaun tidak diluluskan. Sila hubungi pentadbir anda!')
,(N'The address that you have used to request a new password is not valid.',N'Alamat yang telah anda gunakan untuk meminta kata laluan baharu tidak sah.')
,(N'Recover password failed. Please try again!',N'Gagal memulihkan kata laluan. Sila cuba lagi!')
,(N'Oops, this account is having 1 pending pay out request, please update this transaction first!',N'Op, akaun ini mempunyai 1 permintaan pembayaran yang belum selesai, sila kemas kini transaksi ini dahulu!')
,(N'Email Address has been used. Please choose another one!',N'Alamat E-mel telah digunakan. Sila pilih yang lain!')
,(N'Update process is unsuccessful. Please try again!',N'Proses kemas kini tidak berjaya. Sila cuba lagi!')
,(N'Invalid Affiliate!',N'Ahli Gabungan Tidak Sah!')
,(N'Invalid input password!',N'Kata laluan input tidak sah!')
,(N'Invalid input status!',N'Status input tidak sah!')
,(N'You can not do this function!',N'Anda tidak boleh menggunakan fungsi ini!')
,(N'Error! Change password unsuccessfully!',N'Ralat! Tukar kata laluan tidak berjaya!')
,(N'This affiliate has been added before.',N'Ahli gabungan ini telah ditambah sebelum ini.')
,(N'Error! Add favorite unsuccessfully!',N'Ralat! Tambah kegemaran tidak berjaya!')
,(N'This affiliate has not been added before.',N'Ahli gabungan ini tidak pernah ditambah sebelum ini.')
,(N'Error! Delete favorite unsuccessfully!',N'Ralat! Padam kegemaran tidak berjaya!')
,(N'This transaction is not a withdrawal.',N'Transaksi ini bukan pengeluaran.')
,(N'Oops, You do not have permission to update this transaction.',N'Op, Anda tiada kebenaran untuk mengemas kini transaksi ini.')
,(N'Update failed. Please try again!',N'Kemas kini gagal. Sila cuba lagi!')
,(N'Invalid Balance Account.',N'Baki Akaun Tidak Sah.')
,(N'Sorry, you do not have enough money to withdraw.',N'Maaf, anda tidak mempunyai wang yang cukup untuk mengeluarkan.')
,(N'Sorry, amount is invalid.',N'Maaf, jumlah tidak sah.')
,(N'Sorry, only Player Account method is supported. Please contact your Administrator.',N'Maaf, hanya kaedah Akaun Pemain disokong. Sila hubungi Pentadbir anda.')
,(N'Sorry, this affiliate does not have Player Account. Please contact your Administrator.',N'Maaf, ahli gabungan ini tidak mempunyai Akaun Pemain. Sila hubungi Pentadbir anda.')
,(N'Sorry, this affiliate does not have Player Account.',N'Maaf, Affiliate ini tidak mempunyai Akaun Pemain.')
,(N'Invalid request amount! Amount must be between {MinAmount} and {MaxAmount}',N'Jumlah permintaan tidak sah! Amaun mestilah antara {MinAmount} dan {MaxAmount}')
,(N'Insert transaction failed. Please try again!',N'Sisip transaksi gagal. Sila cuba lagi!')
,(N'Group name is invalid!',N'Nama grup tidak sah!')
,(N'Group name is already existed',N'Nama grup telah pun wujud')
,(N'Oops, maximum of 50 tiers are allowed!',N'Op, maksimum 50 peringkat dibenarkan!')
,(N'Error! Invalid Tier Setting!',N'Ralat! Tetapan Peringkat Tidak Sah!')
,(N'Failed to insert new group! Please try again!',N'Gagal memasukkan grup baharu! Sila cuba lagi!')
,(N'Group is not existed',N'Kumpulan tidak wujud')
,(N'Failed to update group! Please try again!',N'Gagal mengemas kini grup! Sila cuba lagi!')
,(N'At least 1 affiliate was assigned to this group. You cannot delete it.',N'Sekurang-kurangnya 1 Affiliate telah diberikan kepada grup ini. Anda tidak boleh memadamnya.')
,(N'Failed to delete group! Please try again!',N'Gagal memadamkan grup! Sila cuba lagi!')

UPDATE m WITH(ROWLOCK)
	SET m.MessageContentMS = e.Message_Ms
FROM dbo.Messages m
	INNER JOIN @Message e ON e.Message_EN = m.MessageContentEN

UPDATE m WITH(ROWLOCK)
	SET m.Message_Ms = e.Message_Ms
FROM dbo.News m
	INNER JOIN @Message e ON e.Message_EN = m.Message_En