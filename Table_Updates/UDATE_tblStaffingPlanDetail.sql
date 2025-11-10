select * from tblStaffingPlanDetail where fte_frcst_mo18 is null

update tblStaffingPlanDetail set fte_frcst_mo11 = '0.00', fte_frcst_mo12 = '0.00', fte_frcst_mo13 = '0.00', 
fte_frcst_mo14 = '0.00', fte_frcst_mo15 = '0.00', fte_frcst_mo16 = '0.00', fte_frcst_mo17 = '0.00', fte_frcst_mo18 = '0.00' 
where fte_frcst_mo18 is null
