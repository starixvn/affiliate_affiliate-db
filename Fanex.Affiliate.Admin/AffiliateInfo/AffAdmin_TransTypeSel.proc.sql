ALTER Procedure [dbo].[AffAdmin_TransTypeSel]
AS
	SELECT TypeID,TypeName,TypeDesc
	FROM TransType(nolock)
	Order by TypeName
