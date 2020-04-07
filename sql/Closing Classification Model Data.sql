/****************************************************************
Query to get data on a folder to determine closing probability.
****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
-- OME at folder
-- pre folder turn times
-- TI that describe loan...ie new construction
-- DemographyDim stuff?
-- LOLA stuff might be after 21
-- ClientID, ClientPortal, Person Model all seem to not link
		-- PersonLoan ON LoanNumber seems the best way to go (See Client Person Model.sql)
SELECT
  L.LoanNumber
--, person.PersonId
, ad.AdSource
, app.AppType
, lola.FICOHigh
, lola.FICOLow
, lola.FICOMed
, leadgrade2.LeadGrade 'LeadGrade (lola)'
, leadsource.LeadSource
, lola.AttemptedContacts
, lola.CreditPulls
, lola.EmailsSent
, lola.NumberofBorrowers
, lola.SelfReportedCredit
, lola.CurrentRate
, lola.UPEMScore
, hearabout.[Description] 'HearAboutUs'
, gpa.GPA
, leadgrade.LeadGrade
, submission.YearHomeBought
, L.Stat20toStat21
, ltf.LoanAmount
, ltf.BaseLoanAmount
, ltf.ActualPITI
, ltf.CashoutAmount
, ltf.DrawAmount
, ltf.HedgeAllocationValue
, ltf.Income
, ltf.InvestorPropertyValue
, ltf.LiquidAssets
, otd.OccupancyType
, ltf.PrepaidEscrows
, ltf.OverageShortage
, ltf.QualFICO
, ltf.RegulatoryDTI
, ltf.DTI
, ltf.HCLTV
, ltf.CLTV
, ltf.LTV
, ltf.SalesConcessions
, ltf.TargetProfit
, ltf.ThirdPartyCosts
, property.PropertyType
, ctd.CondoType
, dtd.DocType
, lien.Lien
, branch.Branch
, ltf.CostToCure
, ltf.EscrowedAmount
, ltf.HasMI
, ltf.InterestRate
, ltf.ClientPoints
, ltf.RequiredPoints
, ltf.InvestorPropertyValue
, ltf.InvestorTargetAmount
, ltdim.LoanTerm
, ltf.IsNewYorkCemaFlg
, L.EmployeeLoanFlg
, L.PIWFlg
, L.SelfEmployFlg
, L.EmailFlg
, L.ESigEligibleFlg
, lpd.LoanPurpose
, refiPurpose.RefiPurpose
, lcgd.FriendlyName 'Loan Channel'
, pb.ProductDescription
, pb.Jumboflg
, pb.ProductBucket
, pb.ProductType
, gd.StateName
, gd.[AVE HOME VAL]
, [ClosedFlg]		= CASE WHEN L.ClosingID IS NOT NULL THEN 1 ELSE 0 END

FROM QLODS.dbo.LKWD L WITH (NOLOCK)
	LEFT JOIN QLODS.dbo.LKWDTransFact ltf WITH (NOLOCK) ON ltf.LoanNumber = L.LoanNumber
	LEFT JOIN QLODS.dbo.LOLA lola WITH (NOLOCK) ON lola.JacketNumber = L.LoanNumber
	LEFT JOIN QLODS.dbo.AdSourceDim ad WITH (NOLOCK) ON ad.AdSourceID = lola.AdSourceID
	LEFT JOIN QLODS.dbo.AppTypeDim app WITH (NOLOCK) ON app.AppTypeID = lola.AppTypeID
	LEFT JOIN QLODS.dbo.LeadGradeDim leadgrade2 (NOLOCK) ON leadgrade2.LeadGradeID = lola.LeadGradeID
	LEFT JOIN QLODS.dbo.LeadSourceDim leadsource (NOLOCK) ON leadsource.LeadSourceID = lola.LeadSourceID
	LEFT JOIN QLODS.dbo.LoanPurposeDim lpd WITH (NOLOCK) ON lpd.LoanPurposeID = ltf.LoanPurposeID
	LEFT JOIN QLODS.dbo.LoanChannelGroupDim lcgd WITH (NOLOCK) ON lcgd.LoanChannelGroupID = ltf.LoanChannelGroupID
	LEFT JOIN Reporting.dbo.vwProductBuckets pb WITH (NOLOCK) ON pb.ProductId = ltf.ProductID
	LEFT JOIN QLODS.dbo.GeographyDim gd WITH (NOLOCK) ON gd.GeographyID = L.PropertyGeographyID
	LEFT JOIN QLODS.dbo.OccupancyTypeDim otd WITH (NOLOCK) ON otd.OccupancyTypeID = ltf.OccupancyTypeID
	LEFT JOIN QLODS.dbo.PropertyTypeDim property WITH (NOLOCK) ON property.PropertyTypeID = L.PropertyTypeID
	LEFT JOIN QLODS.dbo.CondoTypeDim ctd WITH (NOLOCK) ON ctd.CondoTypeID = ltf.CondoTypeID
	LEFT JOIN QLODS.dbo.DocTypeDim dtd WITH (NOLOCK) ON dtd.DocTypeID = ltf.DocTypeID
	LEFT JOIN QLODS.dbo.LoanTermDim ltdim WITH (NOLOCK) ON ltdim.LoanTermID = ltf.LoanTermID
	LEFT JOIN QLODS.dbo.LienDim lien WITH (NOLOCK) ON lien.LienID = ltf.LienID
	LEFT JOIN QLODS.dbo.BranchDim branch WITH (NOLOCK) ON branch.BranchID = ltf.BranchID
	LEFT JOIN BISubmissions.dbo.LeadSubmissionFact submission WITH (NOLOCK) ON submission.JacketNumber = L.LoanNumber
	LEFT JOIN BISubmissions.dbo.HearAboutUsCdDim hearabout WITH (NOLOCK) ON hearabout.HearAboutUsCd = submission.HearAboutUsID
	LEFT JOIN QLODS.dbo.LeadGradeDim leadgrade WITH (NOLOCK) ON leadgrade.LeadGradeID = submission.SubmissionLeadGradeID
	LEFT JOIN QLODS.dbo.RefiPurposeDim refiPurpose WITH (NOLOCK) ON refiPurpose.RefiPurposeID = ltf.RefiPurposeID
	--LEFT JOIN BIClient.dbo.ClientDim client WITH (NOLOCK) ON client.GCID = L.BorrowerGCID
	--LEFT JOIN BIClient.dbo.ClientDim coclient WITH (NOLOCK) ON coclient.GCID = L.CoBorrowerGCID
	--LEFT JOIN BIClient.dbo.ClientEmploymentDim clientEmp WITH (NOLOCK) ON clientEmp.ClientEmploymentId = L.BorrowerClientEmploymentID
	--LEFT JOIN SRC.Person.PersonLoan person WITH (NOLOCK) ON person.LoanNumber = L.LoanNumber
	LEFT JOIN Reporting.BIIQ.GPA_HistoricalFact gpa WITH (NOLOCK) ON gpa.LoanNumber = L.LoanNumber
		AND gpa.IsMostRecent = 1


WHERE 1=1
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND L.ISQLMSFlg = 0
	AND COALESCE(L.ClosingID, L.FalloutID) BETWEEN 20181000 AND 20181099
	AND ltf.EventTypeID = 2
	AND ltf.StatusID = 76
	AND ltf.RollBackFlg = 0
	AND ltf.DeleteFlg = 0