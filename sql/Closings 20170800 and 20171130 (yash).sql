/****************************************************************

****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
  L.LoanNumber
, lpd.LoanPurpose
, lcd.FriendlyName 'Loan Channel'
, pd.ProductType
, pb.ProductBucket
, pb.ProductDescription
, L.Stat21Dt
, L.[1stStat35Dt]
, L.ClosingDt
, em.CommonID 'CCS CommonID'
, em.FullNameFirstLast

FROM QLODS.dbo.LKWD L
	INNER JOIN QLODS.dbo.LoanPurposeDIM lpd ON lpd.LoanPurposeID = L.LoanPurposeID
	INNER JOIN QLODS.dbo.ProductDim pd ON pd.ProductID = L.ProductID
	INNER JOIN QLODS.dbo.LoanChannelGroupDim lcd ON lcd.LoanChannelGroupID = L.LoanChannelGroupID
	INNER JOIN Reporting.dbo.vwProductBuckets pb ON pb.ProductID = L.ProductID
	INNER JOIN QLODS.dbo.EmployeeMaster em ON em.EmployeeDimID = L.LoanProcessorID

WHERE 1=1
	AND L.ClosingID BETWEEN 20170800 AND 20171130
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND L.IsQLMSFlg = 0

ORDER BY L.ClosingID

