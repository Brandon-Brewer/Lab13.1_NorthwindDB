/****** Script for SelectTopNRows command from SSMS  ******/
DECLARE @date AS INT	= 2016051
DECLARE @id AS INT		= 2340591    

SELECT
      hfc.[ActiveStartDtID]
      ,hfc.[ActiveEndDtID]
	  ,em.FullNameFirstLast 'DVP at time'
	  --,em.JobTitle 'current job title'
	  ,jtdim.JobTitle 'job title at time'
	  ,jtb.ActiveStartDtID 'jt start'
	  ,jtb.ActiveEndDtID 'jt end'
  FROM [BICommon].[TeamMember].[HierarchyFullyConnected] hfc
	LEFT JOIN QLODS.dbo.EmployeeMaster em ON em.CommonID = hfc.AncestorCommonID
	INNER JOIN BICommon.TeamMember.JobTitleBridge jtb ON jtb.CommonID = hfc.AncestorCommonID
		AND @date BETWEEN jtb.ActiveStartDtID AND jtb.ActiveEndDtID
	INNER JOIN BICommon.TeamMember.JobTitleDim jtdim ON jtdim.JobTitleID = jtb.JobTitleID
		AND (jtdim.JobTitle LIKE '%DVP%'
		OR jtdim.JobTitle LIKE '%Divisional VP%')
  WHERE hfc.DescendantCommonID = @id
		AND @date BETWEEN hfc.ActiveStartDtID AND hfc.ActiveEndDtID