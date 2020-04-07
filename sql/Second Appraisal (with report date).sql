SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DROP TABLE IF EXISTS #bp
SELECT 
  L.LoanNumber			'Loan Number'
, L.Stat20Dt			'Stat 20 Date'
, sd.StatusFullDesc		'Current Status'
, pd.ProductDescription 'Product'
, L.LoanAmount			'Loan Amount'
, app.[Ordered Date]

INTO #bp

FROM QLODS..LKWD L
	INNER JOIN QLODS..ProductDim pd ON pd.ProductID = L.ProductID
	INNER JOIN QLODS..StatusDim sd ON sd.StatusID = L.CurrentStatusID
	OUTER APPLY(
				SELECT COUNT(*) 'Ordered Count'
					, MIN(tif.StatusDateTime) 'Ordered Date'
				FROM QLODS..LKWDTrackingItemFact tif
				WHERE tif.LoanNumber = L.LoanNumber
					AND tif.TrackingItemID = 161  --TI 327 *Appraisal
					AND tif.StatusID = 6 --Ordered
				)app		
WHERE 1=1
	AND L.LoanAmount > 1000000
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND sd.StatusKey BETWEEN 20 AND 40
	AND (pd.Product LIKE '%QJ%'
		OR pd.Product LIKE 'C%')
	AND app.[Ordered Count] = 1


SELECT #bp.*
	, CASE WHEN prodLoanAmt.[product Loan AMT date] >= #bp.[Ordered Date] THEN prodLoanAmt.[product Loan AMT date]
		   ELSE #bp.[Ordered Date] END 'Report Date'
FROM #bp
	OUTER APPLY(
				SELECT MIN(ltf.TransDateTime) 'product Loan AMT date'
				FROM QLODS.dbo.LKWDTransFact ltf
					INNER JOIN QLODS.dbo.StatusDim sd ON sd.StatusID = ltf.StatusID
						AND sd.StatusKey BETWEEN 20 AND 40
					INNER JOIN QLODS.dbo.ProductDim pd ON pd.ProductID = ltf.ProductID
						AND (pd.Product LIKE '%QJ%' OR pd.Product LIKE 'C%')
				WHERE ltf.LoanNumber = #bp.[Loan Number]
					AND ltf.LoanAmount > 1000000
					AND ltf.RollBackFlg = 0
					AND ltf.DeleteFlg = 0
				) prodLoanAmt

ORDER BY CASE WHEN prodLoanAmt.[product Loan AMT date] >= #bp.[Ordered Date] THEN prodLoanAmt.[product Loan AMT date]
		   ELSE #bp.[Ordered Date] END