/******************************************************************
This query pulls the number of Qtext Replies by Hunt team members
******************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @StartDtID AS INT = 20171211
DECLARE @EndDtID AS INT = 20171213

SELECT
  qtext.MessageDtID
, em.CommonID
, em.FullNameFirstLast 'CCS'
, COUNT(qtext.LoanNumber) 'Number of Replies'

FROM Reporting.ops.DS_QText_QNotifier_BLD qtext
	LEFT JOIN QLODS.dbo.EmployeeMaster em ON qtext.InteractionTM = em.CommonID

WHERE 1=1
	AND qtext.MessageDtID BETWEEN @StartDtID AND @EndDtID
	AND qtext.MessageAction = 'replied'
	AND em.JobTitle IN ('PC Hunt Client Care Spec', 'Exec Hunt CCS')

GROUP BY qtext.MessageDtID, em.CommonID, em.FullNameFirstLast
ORDER BY 1, 4 DESC