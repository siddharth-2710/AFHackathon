SELECT
    Location_Home__dlm.Id__c                       AS salesforce_location_id__c,
    Location_Home__dlm.Name__c                     AS location_name__c,
    Location_Home__dlm.cdp_sys_record_currency__c  AS currency_iso_code__c,
    MAX(TRY_CONVERT_CURRENCY(Location_Home__dlm.Estimated_Setup_Cost_c__c, Location_Home__dlm.cdp_sys_record_currency__c, 'INR')) /
    MAX(TRY_CONVERT_CURRENCY(Location_Home__dlm.Projected_Revenue_c__c, Location_Home__dlm.cdp_sys_record_currency__c, 'INR')) / 12 / 0.65
        AS payback_period_years__c
FROM Location_Home__dlm
GROUP BY
    Location_Home__dlm.Id__c,
    Location_Home__dlm.Name__c,
    Location_Home__dlm.cdp_sys_record_currency__c
