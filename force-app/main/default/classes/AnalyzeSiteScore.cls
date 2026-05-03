public with sharing class AnalyzeSiteScore {

    @InvocableMethod(
        label='Analyze Site Score'
        description='Returns the full site scorecard for a named location including demand score, competition, revenue, and payback period.'
    )
    public static List<SiteScoreResult> analyze(List<SiteScoreRequest> requests) {
        List<SiteScoreResult> results = new List<SiteScoreResult>();

        for (SiteScoreRequest req : requests) {
            SiteScoreResult res = new SiteScoreResult();

            String namePattern = '%' + req.locationQuery + '%';
            List<SObject> sites = Database.query(
                'SELECT Id, Name, City__c, Demand_Score__c, Competitor_Density__c, ' +
                'Projected_Revenue__c, Estimated_Setup_Cost__c, Payback_Period_Years__c, ' +
                'Nearest_Competitor_Distance_M__c, Demo_Growth_Rate__c, Footfall_Index_Normalized__c, ' +
                'Scorecard_Last_Updated__c ' +
                'FROM Location ' +
                'WHERE (Name LIKE :namePattern OR City__c LIKE :namePattern) ' +
                'AND RecordType.DeveloperName = \'Proposed_Site\' ' +
                'ORDER BY Demand_Score__c DESC NULLS LAST LIMIT 1'
            );

            if (sites.isEmpty()) {
                res.found = false;
                res.message = 'No proposed site found matching "' + req.locationQuery + '". Please check the location name.';
                results.add(res);
                continue;
            }

            SObject site = sites[0];
            res.found = true;
            res.locationName = (String) site.get('Name');
            res.city = (String) site.get('City__c');
            res.demandScore = site.get('Demand_Score__c') != null ? (Decimal) site.get('Demand_Score__c') : 0;
            res.competitorDensity = site.get('Competitor_Density__c') != null ? (String) site.get('Competitor_Density__c') : 'Unknown';
            res.projectedMonthlyRevenue = site.get('Projected_Revenue__c') != null ? (Decimal) site.get('Projected_Revenue__c') : 0;
            res.paybackPeriodYears = site.get('Payback_Period_Years__c') != null ? (Decimal) site.get('Payback_Period_Years__c') : 0;
            Decimal nearestDist = site.get('Nearest_Competitor_Distance_M__c') != null ? (Decimal) site.get('Nearest_Competitor_Distance_M__c') : 0;
            res.nearestCompetitorM = nearestDist.intValue();

            if (res.demandScore >= 33) {
                res.recommendation = 'RECOMMENDED';
                res.recommendationEmoji = 'High priority — proceed to due diligence';
            } else if (res.demandScore >= 25) {
                res.recommendation = 'POSSIBLE';
                res.recommendationEmoji = 'Moderate potential — requires further research';
            } else {
                res.recommendation = 'NOT RECOMMENDED';
                res.recommendationEmoji = 'Low demand score — consider alternative areas';
            }

            res.formattedScorecard =
                'SITE SCORECARD\n' +
                'Location: ' + res.locationName + ', ' + res.city + '\n' +
                'Demand Score: ' + res.demandScore + '/100\n' +
                'Competition: ' + res.competitorDensity +
                    ' (' + res.nearestCompetitorM + 'm to nearest rival)\n' +
                'Est. Monthly Revenue: INR ' + String.valueOf(res.projectedMonthlyRevenue.longValue()) + '\n' +
                'Payback Period: ' + res.paybackPeriodYears + ' years\n' +
                'Verdict: ' + res.recommendation + '\n' +
                res.recommendationEmoji + '\n' +
                'Powered by Agentforce';

            res.message = res.formattedScorecard;
            results.add(res);
        }
        return results;
    }

    public class SiteScoreRequest {
        @InvocableVariable(
            label='Location Query'
            description='Location name, area, or city to look up — e.g. Marol Naka or Mumbai'
            required=true
        )
        public String locationQuery;
    }

    public class SiteScoreResult {
        @InvocableVariable public Boolean found;
        @InvocableVariable public String  message;
        @InvocableVariable public String  formattedScorecard;
        @InvocableVariable public String  locationName;
        @InvocableVariable public String  city;
        @InvocableVariable public Decimal demandScore;
        @InvocableVariable public String  competitorDensity;
        @InvocableVariable public Decimal projectedMonthlyRevenue;
        @InvocableVariable public Decimal paybackPeriodYears;
        @InvocableVariable public Integer nearestCompetitorM;
        @InvocableVariable public String  recommendation;
        @InvocableVariable public String  recommendationEmoji;
    }
}