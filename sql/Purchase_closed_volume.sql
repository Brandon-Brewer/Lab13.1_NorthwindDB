/****************************************************************

****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DROP TABLE IF EXISTS #bp

SELECT
	  l.LoanNumber
	, l.ClosingID
	, l.LoanAmount

INTO #bp

FROM QLODS.dbo.LKWD L

WHERE 1=1
	AND L.LoanPurposeID <> 7
	AND L.DeleteFlg = 0
	AND L.ClosingID BETWEEN 20171000 AND 20171099


SELECT 
 	  COUNT(#bp.LoanNumber)						'Loans Closed'
	, SUM(#bp.LoanAmount)/POWER(10,9)			'Volume'
	, sum(#bp.LoanAmount)/Count(#bp.LoanAmount) 'Avg LoanAmt'
FROM #bp

SELECT
	  #bp.ClosingID
 	, COUNT(#bp.LoanNumber)						'Loans Closed'
	, SUM(#bp.LoanAmount)						'Volume'
	, sum(#bp.LoanAmount)/Count(#bp.LoanAmount) 'Avg LoanAmt'
FROM #bp
GROUP BY #bp.ClosingID
ORDER BY #bp.ClosingID


