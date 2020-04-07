Set Transaction Isolation Level Read Uncommitted

DECLARE @date INT	= 20160625

SELECT DISTINCT
  lh.LoanNumber
, LH.PipelineDateTime
, L.Stat21ID
, A.StatusKey
, L.ClosingID
, L.FalloutID
, [Status Bucket]		= CASE WHEN L.FalloutID <= @date THEN 'Fallout'
						WHEN A.StatusKey IN (33,35,40) THEN 'Pipeline'
							ELSE 'Closed' END
, [Bucket Turn Time]	= CASE WHEN L.FalloutID <= @date THEN DATEDIFF(DAY,LH.PipelineDateTime,L.FalloutDt)
						WHEN A.StatusKey IN (33,35,40) THEN DATEDIFF(DAY,LH.PipelineDateTime,CONVERT(DATE,CONVERT(VARCHAR(8),@Date,112)))
							ELSE DATEDIFF(DAY,LH.PipelineDateTime,B.TransDateTime) END

FROM BILoan.Pipeline.LoanHistoryFact2016 lh
	INNER JOIN QLODS..LKWDTransFact ltf ON ltf.LKWDTransFactID = lh.LKWDTransFactID
	INNER JOIN QLODS..LKWD L ON L.LoanNumber = ltf.LoanNumber
	OUTER APPLY (
				SELECT sd.StatusKey
				FROM BILoan.Pipeline.LoanHistoryFact2016 lh2
					INNER JOIN QLODS..LKWDTransFact ltf2 ON ltf2.LKWDTransFactID = lh2.LKWDTransFactID
					INNER JOIN QLODS..StatusDim sd ON sd.StatusID = ltf2.StatusID
				WHERE lh2.LoanNumber = lh.LoanNumber
					AND lh2.PipelineDateID = @date
				) A
	OUTER APPLY(
				SELECT TOP 1 ltf3.TransDateTime
				FROM QLODS..LKWDTransFact ltf3
				WHERE ltf3.LoanNumber = lh.LoanNumber
					AND ltf3.StatusID = 151
					AND ltf3.EventTypeID = 2
					AND ltf3.TransDtID BETWEEN 20160413 AND @date
				ORDER BY ltf3.TransDtID DESC, ltf3.TransTmID DESC
				) B

WHERE 1=1
	AND lh.PipelineDateID BETWEEN 20160413 AND 20160624 --date range of New Process but 1 year prior
	AND DATEDIFF(DAY, L.Stat21Dt, lh.PipelineDateTime) = 60 --the loan was aged for 60 days at the time
	AND ltf.StatusID IN (83, 117) --Stat 33 or 35 aka 'in process'
	AND L.LoanPurposeID = 7 --Refi
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0