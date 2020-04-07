SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
  L.LoanNumber 'Loan Number'
, sd.StatusKey 'Current Status'
, sd.StatusDesc 'Current Status Description'
, L.CurrStatDt ' Current Status Date'
, lcgd.FriendlyName 'Loan Channel'
, lpd.LoanPurpose 'Loan Purpose'
, pd.ProductDescription ' Product Description'
, L.AssociateUnderwriterID 'Assoicate Underwriter' --Need to join on EM to get name
, L.LoanUnderwriterID 'Underwriter' --Need to join on EM to get name
--, 'Underwriter FSO'
--, 'Client Care Specialist'  Acutally CCS is no longer needed
, L.Stat20Dt 'Status 20 Date'

FROM QLODS.dbo.LKWD L
	INNER JOIN QLODS.dbo.GeographyDim gd ON gd.GeographyID = L.PropertyGeographyID
	INNER JOIN QLODS.dbo.StatusDim sd ON sd.StatusID = L.CurrentStatusID
	INNER JOIN QLODS.dbo.LoanChannelGroupDim lcgd ON lcgd.LoanChannelGroupID = L.LoanChannelGroupID
	INNER JOIN QLODS.dbo.LoanPurposeDim lpd ON lpd.LoanPurposeID = L.LoanPurposeID
	INNER JOIN QLODS.dbo.ProductDim pd ON pd.ProductID = L.ProductID


WHERE gd.[STATE] = 'KY'
	AND sd.StatusKey BETWEEN 20 AND 57 --this is the highest the qlsice link shows
	AND L.Stat20ID > 20161209 --lastest date the extract pulled
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0

ORDER BY sd.StatusKey