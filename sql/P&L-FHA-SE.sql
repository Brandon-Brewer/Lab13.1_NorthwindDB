--Find all FHA, Self employment with the P&L Tracking Item.  Need to find how to get S/E for a loss
--SRC.Mobius.PersonEmployment and PersonIncome

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT ticsf.LoanNumber
	, pd.ProductDescription
	, tid.TrackingItem
	, tid.TrackingItemDesc
	, tisd.StatusDescription 'TI Current Status'
	, sd.StatusFullDesc 'Loan Status'
	--, L.TotalIncomePct
	--, L.TotalLoanIncome
	--, ltf.EventTypeID
	, pe.MonthlyIncome
	--, mpi.IncomeValue


FROM QLODS..LKWD L
	--INNER JOIN QLODS..LKWDTransFact
		--ltf ON ltf.LoanNumber = L.LoanNumber
	--INNER JOIN QLODS..EventTypeDIM
		--etd ON etd.EventTypeID = ltf.EventTypeID
	INNER JOIN QLODS..StatusDim 
		sd ON sd.StatusID = L.CurrentStatusID
	INNER JOIN QLODS..ProductDim 
		pd ON pd.ProductID = L.ProductID
	INNER JOIN QLODS..TrackingItemCurrentStatusFact 
		ticsf ON ticsf.LoanNumber = L.LoanNumber
	INNER JOIN QLODS..LKWDTrackingItemDim 
		tid ON tid.TrackingItemID = ticsf.TrackingItemID
	INNER JOIN QLODS..LKWDTrackingItemStatusDim 
		tisd ON tisd.StatusID = ticsf.StatusID
	--The below inner Joins were an attempt at finding negative incomes.  Still returning a lot of loans
	INNER JOIN SRC.Mobius.PersonEmployment
		pe ON pe.LoanNumber = L.LoanNumber
	--INNER JOIN SRC.Mobius.PersonIncome
		--mpi ON mpi.LoanNumber = L.LoanNumber

WHERE tid.TrackingItem IN (1022, 76, 5371, 7204, 2090, 180)
	AND sd.StatusKey IN (21, 24, 33, 35, 41) 
	AND L.SelfEmployFlg = 1
	AND pe.MonthlyIncome < 0
	AND pe.IsSelfEmployed = 1
	--AND mpi.IncomeValue <= 0
	AND tisd.StatusDescription NOT LIKE '%cleared%' --aka not outstanding
	AND tisd.StatusDescription NOT LIKE '%cancelled%' --aka not outstanding
	AND pd.ProductDescription LIKE '%FHA%'
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	--AND ltf.EventTypeID = 75


