/****************************************************************

****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	L.LoanNumber
  , L.LockExpireDt
  , L.Stat21Dt
  , L.FalloutDt
  --, tisd.StatusDescription
  , sd.StatusFullDesc				'Current Loan Status'
  , AtLockExpired.StatusFullDesc	'Loan Status at Lock Expired'

FROM QLODS.dbo.LKWD L
	LEFT JOIN QLODS.dbo.LKWDTrackingItemFact		tif ON tif.LoanNumber = L.LoanNumber
		AND tif.TrackingItemID = 5177
		AND tif.DeleteFlg = 0
	LEFT JOIN QLODS.dbo.LKWDTrackingItemStatusDim	tisd ON tisd.StatusID = tif.StatusID
	LEFT JOIN QLODS.dbo.StatusDim					sd ON sd.StatusID = L.CurrentStatusID
	OUTER APPLY(
				SELECT TOP 1 sd2.StatusFullDesc
				FROM QLODS.dbo.LKWDTransFact ltf
					INNER JOIN QLODS.dbo.StatusDim sd2 ON sd2.StatusID = ltf.StatusID
				WHERE ltf.LoanNumber = L.LoanNumber
					AND ltf.TransDateTime < L.LockExpireDt
					AND ltf.EventTypeID = 2
					AND ltf.DeleteFlg = 0
					AND ltf.RollBackFlg = 0
				ORDER BY ltf.TransDtID DESC, ltf.TransTmID DESC
				) AtLockExpired

WHERE 1=1
	AND L.LockExpireID > 20170800
	AND L.LockExpireID < (CASE WHEN L.Stat21ID IS NULL THEN L.FalloutID-1 ELSE L.Stat21ID-1 END)
	AND (L.Stat21ID < 20170915
		OR L.Stat21ID IS NULL)
	AND (L.FalloutID < 20170915
		OR L.FalloutID IS NULL)
	AND tif.StatusID IS NULL
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	
