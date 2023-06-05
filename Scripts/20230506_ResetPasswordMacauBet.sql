/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/

/*
	Creator: 20230506@Eddie
	DB: DBCUST.bodb_Licensee
	Task: Reset password [RedmineId : #180311]
*/

UPDATE Users
SET UserPwd = '13CFC208FD60DB13F6BF6F5937BF15744E3D37D5'
WHERE UserId = 11463 AND UserSalt = 'l477o6/1s2iE3arzRA==' -- starixsas, old : l477o6/1s2iE3arzRA==, D7C24613952319DC09D6EEA17FDDB1C41002C1F4

UPDATE Users
SET UserPwd = 'B09B216EAB82606011A9027EA5E4AE1AB2E4627E'
WHERE UserId = 9374 AND UserSalt = 'DhkIk90OMKqIWPQrWA==' --StarixQC1 old DhkIk90OMKqIWPQrWA==, 73ABD0F59CC3D4E9293ABDFAD9410F6FECC0D2C8
