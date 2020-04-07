SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DROP TABLE IF EXISTS #bp
SELECT
  orders.*
, L.Stat21Dt
, L.ClosingDt
, L.FalloutDt
, lpd.LoanPurpose
, lcgd.FriendlyName 'Loan Channel'
, pb.ProductDescription
, pb.ProductBucket
, pb.ProductType
INTO #bp
FROM BISandboxWrite.bbrewer.firstamerican orders
	LEFT JOIN QLODS.dbo.LKWD L (NOLOCK) ON L.LoanNumber = orders.[Loan Number]
	LEFT JOIN QLODS.dbo.LoanPurposeDim lpd WITH (NOLOCK) ON lpd.LoanPurposeID = L.LoanPurposeID
	LEFT JOIN QLODS.dbo.LoanChannelGroupDim lcgd WITH (NOLOCK) ON lcgd.LoanChannelGroupID = L.LoanChannelGroupID
	LEFT JOIN Reporting.dbo.vwProductBuckets pb WITH (NOLOCK) ON pb.ProductId = L.ProductID
	LEFT JOIN QLODS.dbo.GeographyDim gd WITH (NOLOCK) ON gd.GeographyID = L.PropertyGeographyID


DROP TABLE IF EXISTS #final
SELECT
  invoices.[Loan Number]
, CASE WHEN L.ClosingDt IS NOT NULL THEN 'Closed'
       WHEN L.FalloutDt IS NOT NULL THEN 'Fallout'
	   ELSE 'Open' END 'Closed/Fallout'
, SUM(invoices.Amount) 'Total Amount'
INTO #final
FROM BISandboxWrite.brewer.floodinvoices invoices
	LEFT JOIN QLODS.dbo.LKWD L (NOLOCK) ON L.LoanNumber = invoices.[Loan Number]
WHERE invoices.[Flood Cert] IS NOT NULL
GROUP BY
  invoices.[Loan Number]
  , CASE WHEN L.ClosingDt IS NOT NULL THEN 'Closed'
       WHEN L.FalloutDt IS NOT NULL THEN 'Fallout'
	   ELSE 'Open' END


SELECT *
FROM #final
WHERE CASE WHEN #final.[Closed/Fallout] = 'Closed' AND #final.[Total Amount] = 16.5 THEN 1
		   WHEN #final.[Closed/Fallout] = 'Fallout' AND #final.[Total Amount] = 0 THEN 1
	       ELSE 0 END = 0


SELECT
  invoices.*
, L.Stat21Dt
, L.ClosingDt
, L.FalloutDt
, lpd.LoanPurpose
, lcgd.FriendlyName 'Loan Channel'
, pb.ProductDescription
, pb.ProductBucket
, pb.ProductType
, #final.[Closed/Fallout]
, #final.[Total Amount] 'NetCharge'
FROM BISandboxWrite.brewer.floodinvoices invoices
	INNER JOIN #final ON #final.[Loan Number] = invoices.[Loan Number]
	LEFT JOIN QLODS.dbo.LKWD L (NOLOCK) ON L.LoanNumber = invoices.[Loan Number]
	LEFT JOIN QLODS.dbo.LoanPurposeDim lpd WITH (NOLOCK) ON lpd.LoanPurposeID = L.LoanPurposeID
	LEFT JOIN QLODS.dbo.LoanChannelGroupDim lcgd WITH (NOLOCK) ON lcgd.LoanChannelGroupID = L.LoanChannelGroupID
	LEFT JOIN Reporting.dbo.vwProductBuckets pb WITH (NOLOCK) ON pb.ProductId = L.ProductID
	LEFT JOIN QLODS.dbo.GeographyDim gd WITH (NOLOCK) ON gd.GeographyID = L.PropertyGeographyID
WHERE CASE WHEN #final.[Closed/Fallout] = 'Closed' AND #final.[Total Amount] = 16.5 THEN 1
		   WHEN #final.[Closed/Fallout] = 'Fallout' AND #final.[Total Amount] = 0 THEN 1
	       ELSE 0 END = 0

