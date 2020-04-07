SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
/*********************************************************************************************
This query returns loans with amount increases after TI 6319 [Schwab FSO Approval Needed] 
	was statused [Approved to Close].

Cross Apply "TI" grabs the most recent Approved to Close date on TI 6319.

Cross Apply "TF" grabs the previous transactional date on the loan before or on the 
	Approved to Close date.
Therefore, the Loan Amount can be pulled at the time of Approved to Close.

Return loans where the current loan amount is higher than the loan amount at approved to close.
**********************************************************************************************/
SELECT 
  L.LoanNumber	'Loan Number'
, TI.[Approved to Close Date]
, loanAmtDt.[Loan Amt Change Date]
, TF.[Loan Amount at AtC]
, L.LoanAmount	'Current Loan Amount'

FROM QLODS..LKWD L (NOLOCK)
	CROSS APPLY	(
				SELECT MAX(tif.StatusDateTime) 'Approved to Close Date' --The most recent approved to close date
				FROM QLODS..LKWDTrackingItemFact tif (NOLOCK)
				WHERE tif.LoanNumber = L.LoanNumber
					AND tif.TrackingItemID = 5785 --TI 6319 Schwab FSO Approval Needed
					AND tif.StatusID = 133 --Approved to Close
					AND tif.DeleteFlg = 0
				GROUP BY tif.LoanNumber
				) TI
	
	CROSS APPLY	(
				SELECT TOP 1 
					  ltf.TransDateTime 'Previous TransDateTime'
					, ltf.LoanAmount 'Loan Amount at AtC'
				FROM QLODS..LKWDTransFact ltf (NOLOCK)
				WHERE ltf.LoanNumber = L.LoanNumber
					AND ltf.TransDateTime <= TI.[Approved to Close Date] --The previous transactional date before AtC
					AND ltf.DeleteFlg = 0
					AND ltf.RollBackFlg = 0
				ORDER BY ltf.TransDtID DESC, ltf.TransTmID DESC
				) TF

	OUTER APPLY(
				SELECT TOP 1 ltf.TransDateTime 'Loan Amt Change Date'
				FROM QLODS.dbo.LKWDTransFact ltf
				WHERE ltf.LoanNumber = L.LoanNumber
					AND ltf.EventTypeID = 6 --Loan Amount Change flag
				ORDER BY ltf.TransDtID DESC, ltf.TransTmID DESC --finding the most current loan amount change
				) loanAmtDt
				
	
WHERE L.LoanAmount > TF.[Loan Amount at AtC] --We want loan amount increases
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0

ORDER BY loanAmtDt.[Loan Amt Change Date] DESC
