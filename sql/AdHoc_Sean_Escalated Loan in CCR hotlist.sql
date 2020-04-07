/****************************************************************

****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
L.LoanNumber
, sd.StatusFullDesc

	
FROM QLODS.dbo.LKWD L
	INNER JOIN QLODS.dbo.StatusDim sd ON sd.StatusID = L.CurrentStatusID
	INNER JOIN QLODS.dbo.TrackingItemCurrentStatusFact ticsf ON ticsf.LoanNumber = l.LoanNumber
		AND ticsf.TrackingItemID = 6531 --Escalated Loan
		AND ticsf.StatusID = 25 --Confirmed
	INNER JOIN BILoan.dbo.LoanPriorityMovementFact_Current lpmf ON lpmf.LoanNumber = l.LoanNumber
		--AND lpmf.ListEndDateID IS NULL
	INNER JOIN BILoan.dbo.LoanPriorityListDim lpd ON lpd.LoanPriorityListID = lpmf.LoanPriorityListID
		AND lpd.LoanPriorityListID = 388 --Closing Care Rep

--WHERE 1=1
	--AND sd.StatusKey IN (21,33,35,40,41)