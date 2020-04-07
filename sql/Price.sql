/****************************************************************
This get the base population
****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DROP TABLE IF EXISTS #bp
SELECT
	  L.LoanNumber		
	, AppDt.TransDateTime	
	, AppDt.TransDtID
	, AppDt.TransTmID
	, L.AppraisedValue		
	, L.PurchasePrice

INTO #bp
FROM QLODS..LKWD L
	OUTER APPLY(
				SELECT TOP 1 
					  ltf.TransDateTime
					, ltf.TransDtID
					, ltf.TransTmID
				FROM QLODS..LKWDTransFact ltf 
				WHERE ltf.LoanNumber = L.LoanNumber
					AND EventTypeID = 73 --Appraised Value
					AND ltf.DeleteFlg = 0
					AND ltf.RollBackFlg = 0
				ORDER BY ltf.TransDtID ASC, ltf.TransTmID ASC
				) AppDt
				
WHERE 1=1
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND L.LoanPurposeID <> 7 --Not Refi.  AKA Purchase
	AND L.Stat21ID IS NOT NULL
	AND COALESCE(L.ClosingID, L.FalloutID) BETWEEN 20170100 AND 20170699
	

/****************************************************************
This is to get Purchase price before appraisal.  This was an 
outer apply but had poor performance. However it still takes forever
so might have to split up the date range above.
****************************************************************/
SELECT
	#bp.LoanNumber
	, BeforePrice.PurchasePrice	'Price Before Appraisal'
	, #bp.AppraisedValue
	, #bp.PurchasePrice			'Final Purchase Price'

FROM #bp 
	 OUTER APPLY(
				SELECT TOP 1 lotf.PurchasePrice
				FROM QLODS..LOLATransFact lotf 
				WHERE lotf.JacketNumber = #bp.LoanNumber
					AND lotf.DateID <= #bp.TransDtID
					AND lotf.TimeID <= #bp.TransTmID
				ORDER BY lotf.DateID DESC, lotf.TimeID DESC
				) BeforePrice
WHERE 1=1
	AND BeforePrice.PurchasePrice > #bp.AppraisedValue

