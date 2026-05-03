public with sharing class ExpansionDashboardController {

    public class SiteWrapper {
        @AuraEnabled public String  siteId;
        @AuraEnabled public String  name;
        @AuraEnabled public String  city;
        @AuraEnabled public Decimal demandScore;
        @AuraEnabled public String  competitorDensity;
        @AuraEnabled public Decimal projectedRevenue;
        @AuraEnabled public Decimal estimatedSetupCost;
        @AuraEnabled public Decimal paybackPeriodYears;
        @AuraEnabled public Decimal nearestCompetitorDistanceM;
        @AuraEnabled public String  siteRecommendation;
        @AuraEnabled public String  scorecardLastUpdated;
    }

    @AuraEnabled(cacheable=true)
    public static List<SiteWrapper> getProposedSites() {
        List<SObject> records = Database.query(
            'SELECT Id, Name, City__c, Demand_Score__c, Competitor_Density__c, ' +
            'Projected_Revenue__c, Estimated_Setup_Cost__c, Payback_Period_Years__c, ' +
            'Nearest_Competitor_Distance_M__c, Site_Recommendation__c, Scorecard_Last_Updated__c ' +
            'FROM Location ' +
            'WHERE RecordType.DeveloperName = \'Proposed_Site\' ' +
            'AND Site_Recommendation__c != \'Not Recommended\' ' +
            'ORDER BY Demand_Score__c DESC NULLS LAST LIMIT 100'
        );

        List<SiteWrapper> wrappers = new List<SiteWrapper>();
        for (SObject rec : records) {
            SiteWrapper w = new SiteWrapper();
            w.siteId                 = (String)  rec.get('Id');
            w.name                   = (String)  rec.get('Name');
            w.city                   = (String)  rec.get('City__c');
            w.demandScore            = (Decimal) rec.get('Demand_Score__c');
            w.competitorDensity      = (String)  rec.get('Competitor_Density__c');
            w.projectedRevenue       = (Decimal) rec.get('Projected_Revenue__c');
            w.estimatedSetupCost     = (Decimal) rec.get('Estimated_Setup_Cost__c');
            w.paybackPeriodYears     = (Decimal) rec.get('Payback_Period_Years__c');
            w.nearestCompetitorDistanceM = (Decimal) rec.get('Nearest_Competitor_Distance_M__c');
            w.siteRecommendation     = (String)  rec.get('Site_Recommendation__c');
            DateTime dt = (DateTime) rec.get('Scorecard_Last_Updated__c');
            w.scorecardLastUpdated   = dt != null ? dt.format() : null;
            wrappers.add(w);
        }
        return wrappers;
    }
}
