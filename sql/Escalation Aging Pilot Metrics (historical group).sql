/**************************************************************************************************************
Aging Loan Metrics for Escalation Team (Historical/Comparison Group)
Stakeholders: Lindsay Villasenor, Jeanine Taylor, Debra Abrams, Eric Birk
Updated - 09.12.2017 - Brandon Brewer

This query is an attempt to have a comparison group,
by imitating the new process as if it had happened 1 year prior (4/13/2016 to current day of 2016).
	*If a loan had aged (for 60 days) in that time range, then we include that loan in the population.
	*Of those loans, we ask what status (closed/fallout/pipeline) was the loan in exactly 1 year ago.
		*This is not a perfect comparison since it includes many more loans since we are including all
		 aging loans without needing to be scrubbed.  
		*The average age of a loan that enters the actual process is nearly 1 month older than 60 days.
**************************************************************************************************************/
Set Transaction Isolation Level Read Uncommitted

DECLARE	@date INT	= Convert(VARCHAR(8), DateAdd(yy, -1, GETDATE()), 112) --1 year ago
DROP TABLE IF EXISTS #bp

SELECT DISTINCT
  lh.LoanNumber
, LH.PipelineDateTime
, L.Stat21ID
, hist.StatusKey
, L.ClosingID
, L.FalloutID
, [Status Bucket]		= CASE WHEN L.FalloutID <= @date THEN 'Fallout'
							   WHEN hist.StatusKey IN (33,35,40) THEN 'Pipeline'
							   ELSE 'Closed' END
, [Pullthrough]			= CASE WHEN L.ClosingID IS NOT NULL THEN 1 ELSE 0 END
, [Process Turn Time]	= DATEDIFF(DAY, LH.PipelineDateTime, COALESCE(L.ClosingDt, L.FalloutDt))
--, [Bucket Turn Time]	= CASE WHEN L.FalloutID <= @date THEN DATEDIFF(DAY,LH.PipelineDateTime,L.FalloutDt)
--							   WHEN A.StatusKey IN (33,35,40) THEN DATEDIFF(DAY,LH.PipelineDateTime,CONVERT(DATE,CONVERT(VARCHAR(8),@Date,112)))
--							   ELSE DATEDIFF(DAY,LH.PipelineDateTime,CONVERT(DATE,CONVERT(VARCHAR(8),B.TransDtID,112))) END
INTO #bp

FROM BILoan.Pipeline.LoanHistoryFact2016 lh
	INNER JOIN QLODS.dbo.LKWDTransFact ltf ON ltf.LKWDTransFactID = lh.LKWDTransFactID
	INNER JOIN QLODS.dbo.LKWD L ON L.LoanNumber = ltf.LoanNumber
	OUTER APPLY (
				SELECT sd.StatusKey
				FROM BILoan.Pipeline.LoanHistoryFact2016 lh2
					INNER JOIN QLODS.dbo.LKWDTransFact ltf2 ON ltf2.LKWDTransFactID = lh2.LKWDTransFactID
					INNER JOIN QLODS.dbo.StatusDim sd ON sd.StatusID = ltf2.StatusID
				WHERE lh2.LoanNumber = lh.LoanNumber
					AND lh2.PipelineDateID = @date
				) hist
	--OUTER APPLY(
	--			SELECT TOP 1 ltf3.TransDtID
	--			FROM QLODS..LKWDTransFact ltf3
	--			WHERE ltf3.LoanNumber = lh.LoanNumber
	--				AND (L.FalloutID > @date
	--					OR L.FalloutID IS NULL)
	--				AND A.StatusKey NOT IN (33, 35, 40)
	--				AND ltf3.StatusID = 151
	--				AND ltf3.EventTypeID = 2
	--				AND ltf3.TransDtID BETWEEN 20160413 AND @date
	--			ORDER BY ltf3.TransDtID DESC, ltf3.TransTmID DESC
	--			) B

WHERE 1=1
	AND lh.PipelineDateID BETWEEN 20160413 AND @date - 1 --date range of New Process but 1 year (less 1 day) prior
	AND DATEDIFF(DAY, L.Stat21Dt, lh.PipelineDateTime) = 60 --the loan was aged for 60 days at the time
	AND ltf.StatusID IN (83, 117) --Stat 33 or 35 aka 'in process'
	AND L.LoanPurposeID = 7 --Refi
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0




----------------------------------- Grab Bucket Turn Time -----------------------------------
SELECT 
  #bp.*
, stat41hist.TransDtID 'Stat41ID'
, [Bucket Turn Time]	= CASE WHEN #bp.FalloutID <= @date THEN DATEDIFF(DAY,#bp.PipelineDateTime,CONVERT(DATE,CONVERT(VARCHAR(8),#bp.FalloutID,112)))
							   WHEN #bp.StatusKey IN (33,35,40) THEN DATEDIFF(DAY,#bp.PipelineDateTime,CONVERT(DATE,CONVERT(VARCHAR(8),@Date,112)))
							   ELSE DATEDIFF(DAY,#bp.PipelineDateTime,CONVERT(DATE,CONVERT(VARCHAR(8),stat41hist.TransDtID,112))) END

FROM #bp
	OUTER APPLY(
				SELECT TOP 1 ltf.TransDtID
				FROM QLODS.dbo.LKWDTransFact ltf
				WHERE ltf.LoanNumber = #bp.LoanNumber
					AND ltf.StatusID = 151  --Stat 41 Final Signoff
					AND ltf.EventTypeID = 2 --status change
					AND ltf.TransDtID BETWEEN 20160413 AND @date --date range of process if it had happen 1 year ago
				ORDER BY ltf.TransDtID DESC, ltf.TransTmID DESC
				) stat41hist

/***************************************************************  The End  ***************************************************************/