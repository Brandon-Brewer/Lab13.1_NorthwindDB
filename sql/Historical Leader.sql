DECLARE @id AS INT
SET @id = 2292569 -- Enter the team member's common id

DECLARE @DateID AS INT
SET @DateID = 20170101 -- Enter the date

SELECT 
       CONVERT(DATETIME, CAST(@DateID AS CHAR)) Date
       , tmh.Name 'Team Member'
       , tmh.LeaderName 'Leader Name'
FROM BICommon.TeamMember.vwTeamMemberHierarchyUnPivot tmh
WHERE 
       tmh.LeafCommonID = tmh.CommonID
       AND tmh.LeafCommonID = @id
       AND @DateID BETWEEN tmh.ActiveStartDtID AND tmh.ActiveEndDtID
