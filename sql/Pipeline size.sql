/****************************************************************
Get loan pipeline size (the number of loans in each status each day).

09.29.2017 - Brandon Brewer
****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DROP TABLE IF EXISTS #bp

SELECT
	  ltf.StatusID			'Loan Status'
	, lh.PipelineDateID		'Date'
	, count(lh.LoanNumber)	'Count of Loans'
INTO #bp

FROM 
	(SELECT * FROM BILoan.Pipeline.LoanHistoryFact2016
		Union ALL
	 SELECT * FROM BILoan.Pipeline.LoanHistoryFact2017) AS lh
	INNER JOIN QLODS.dbo.LKWDTransFact ltf ON ltf.LKWDTransFactID = lh.LKWDTransFactID
		AND ltf.DeleteFlg = 0
		AND ltf.RollBackFlg = 0
		AND ltf.StatusID IN (
							  119 --20 - Loan Setup Complete
							, 76  --21 - Folder Received
							, 137 --24 - Approved Pending Client Conditions and Property
							, 4438--26 - Approved Waiting For Property
							, 85  --30 - Submitted to Underwriting
							, 117 --33 - Suspended
							, 83  --35 - Conditionally Approved
							, 181 --40 - Final Signoff - Pending Action
							, 151 --41 - Final Signoff
							)

WHERE 1=1
	AND lh.PipelineDateID BETWEEN 20160900 AND 20170928

GROUP BY ltf.StatusID, lh.PipelineDateID


---------------------------------------- Get Result Set ----------------------------------------
SELECT sd.StatusKey, dd.[DayName], dd.[DayOfWeekName], #bp.[Count of Loans]
FROM #bp
	INNER JOIN QLODS.dbo.StatusDim sd ON sd.StatusID = #bp.[Loan Status]
	INNER JOIN QLODS.dbo.DateDim dd ON dd.DateID = #bp.[Date]
ORDER BY #bp.[Date], sd.StatusKey
------------------------------------------------------------------------------------------------

		


