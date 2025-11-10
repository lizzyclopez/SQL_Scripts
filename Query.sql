select * from CO_BillingCodeRate

strSet = "Billing_CodeID, BillingRateOnshore, BillingRateOffshore "
        strTableName = "CO_BillingCodeRate "
        strWhere = "WHERE Billing_CodeID = " & KeyValue & " "
        strUpdateValue = "BillingRateOnshore "

' Set DateTo of the last record to the DateFrom of the new record to prevent any gaps in dates
        sqlstr = "UPDATE " & strTableName _
                & " SET DateTo = '" & varDateFromAfter & "' " _
                & strWhere _
                & " AND DateTo = '12/31/2999'"

            sqlstr = "INSERT " & strTableName _
                    & " VALUES(" & KeyValue _
                    & ", '" & varDateFromAfter & "'" _
                    & ", '" & varDateToAfter & "'" _
                    & ", " & varUpdateValueAfter & ")"
                    
               UPDATE CO_BillingCodeRate SET DateTo = varDateFromAfter 
               WHERE Billing_CodeID = KeyValue 
                 AND DateTo = '12/31/2999'
                 
                 INSERT CO_BillingCodeRate VALUES(KeyValue, varDateFromAfter, varDateToAfter, varUpdateValueAfter)
                 
                 a.Billing_CodeID, BillingRate, Description "
        strTableName = "lkBillingCodeRate "
        strWhere = "WHERE   Billing_CodeID = " & KeyValue & " "
        strUpdateValue = "BillingRate "
        
        SELECT COUNT(*) FROM CO_BillingCodeRate
        WHERE Billing_CodeID = 3000 
            AND convert(varchar (10),DateTo,101) = '" & varDateFromBefore & "'"
        
        
select * from lkBillingCodeRate		/	select * from lkProjectType		/	select * from lkBillingRateOverride
select * from CO_BillingCodeRate

select convert(varchar (10),DateTo,101) from CO_BillingCodeRate