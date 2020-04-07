SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT Distinct L.LoanNumber

FROM QLODS..LKWD L
	INNER JOIN QLODS..LKWDTrackingItemFact tif ON tif.LoanNumber = L.LoanNumber
	--INNER JOIN QLODS..LKWDTrackingItemDim tid ON tid.TrackingItemID = tif.TrackingItemID
	--INNER JOIN QLODS..LKWDTrackingItemStatusDim tisd ON tisd.StatusID = tif.StatusID
	--INNER JOIN QLODS..StatusDim sd ON sd.StatusID = tif.CurrentLoanStatusID
	CROSS APPLY ( 
					SELECT *
					FROM QLODS..LKWDTrackingItemFact tif
					WHERE tif.LoanNumber = L.LoanNumber
						AND tif.TrackingItemID = 4323  --TI 4583: Banker Clarification Needed
						AND tif.DeleteFlg = 0
				) ti4583 --this apply can be replaced with joining tif onto itself (tif2) and filtering on tif2


WHERE tif.StatusDtID BETWEEN 20170100 AND 20170131
	AND tif.TrackingItemID = 7087  --TI 7622: Loan Restructure Team (LRT) Review - Collateral
	AND tif.StatusID = 600 --Status Description: Collateral - Low Value - BC Set
	AND tif.DeleteFlg = 0
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	-- tid.TrackingItemID = 4323  --TI 4583: Banker Clarification Needed

	

-----INSTEAD of cross apply
-----Select Distinct LoanNumbers
-----FROM LWKD 
-----INNER TIF on L where ti=xxxx and status=xxxx
-----INNER TIF2 on L where ti2=xxxx and status2=xxxxx

		