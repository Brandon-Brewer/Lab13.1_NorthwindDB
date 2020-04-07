SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--add: only include new loans

SELECT 
  L.LoanNumber				'Loan Number'
, L.Stat20Dt				'Stat 20 Date'
, sd.StatusFullDesc			'Current Status'
, pd.ProductDescription		'Product'
, L.LoanAmount				'Loan Amount'
, app.[Ordered Count]
, [Previous Reported Flg]	= CASE WHEN L.LoanNumber IN (3383221091, 3373106935, 3372490531, 3382228525, 3383728566)
								THEN 1 ELSE 0 END

FROM QLODS..LKWD L
	INNER JOIN QLODS..ProductDim pd ON pd.ProductID = L.ProductID
	INNER JOIN QLODS..StatusDim sd ON sd.StatusID = L.CurrentStatusID
	OUTER APPLY(
				SELECT COUNT(*) 'Ordered Count'
				FROM QLODS..LKWDTrackingItemFact tif
				WHERE tif.LoanNumber = L.LoanNumber
					AND tif.TrackingItemID = 161  --TI 327 *Appraisal
					AND tif.StatusID = 6 --Ordered
				)app		
WHERE 1=1
	AND L.LoanAmount >= 1000000
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND sd.StatusKey BETWEEN 20 AND 89
	AND (pd.Product LIKE '%QJ%'
		OR pd.Product LIKE 'C%')
	--AND app.[Ordered Count] = 1
