public without sharing class FindBlindSpots {

    @InvocableMethod(
        label='Find Blind Spot Locations'
        description='Returns locations with high demand (score >= minScore) and low or medium competition. These are underserved markets with high revenue potential.'
    )
    public static List<BlindSpotResult> find(List<BlindSpotRequest> requests) {
        List<BlindSpotResult> results = new List<BlindSpotResult>();
        BlindSpotRequest req = requests[0];

        Decimal minScore = req.minDemandScore != null ? req.minDemandScore : 30;
        String cityFilter = String.isBlank(req.city) ? null : req.city;

        String query =
            'SELECT Id, Name, City__c, Demand_Score__c, Competitor_Density__c, ' +
            'Projected_Revenue__c, Payback_Period_Years__c, Nearest_Competitor_Distance_M__c ' +
            'FROM Location ' +
            'WHERE RecordType.DeveloperName = \'Proposed_Site\' ' +
            'AND Demand_Score__c >= :minScore ' +
            'AND Competitor_Density__c IN (\'Low\', \'Medium\') ';

        if (cityFilter != null) {
            query += 'AND City__c = :cityFilter ';
        }
        query += 'ORDER BY Demand_Score__c DESC NULLS LAST LIMIT 10';

        List<SObject> sites = Database.query(query);

        BlindSpotResult res = new BlindSpotResult();
        res.siteCount = sites.size();

        if (sites.isEmpty()) {
            res.summary = 'No blind spot locations found with demand score >= ' + minScore +
                          (cityFilter != null ? ' in ' + cityFilter : '') + '. Try lowering the threshold.';
            results.add(res);
            return results;
        }

        List<String> lines = new List<String>();
        lines.add('TOP BLIND SPOT LOCATIONS (High Demand + Low Competition)\n');

        Integer rank = 1;
        for (SObject s : sites) {
            String siteName  = (String) s.get('Name');
            String siteCity  = (String) s.get('City__c');
            Decimal score    = s.get('Demand_Score__c') != null ? (Decimal) s.get('Demand_Score__c') : 0;
            String comp      = (String) s.get('Competitor_Density__c');
            Decimal dist     = s.get('Nearest_Competitor_Distance_M__c') != null ? (Decimal) s.get('Nearest_Competitor_Distance_M__c') : null;
            Decimal rev      = s.get('Projected_Revenue__c') != null ? (Decimal) s.get('Projected_Revenue__c') : 0;
            Decimal payback  = s.get('Payback_Period_Years__c') != null ? (Decimal) s.get('Payback_Period_Years__c') : 0;
            String distStr   = dist != null ? dist.intValue() + 'm' : 'N/A';

            lines.add(
                rank + '. ' + siteName + ', ' + siteCity + '\n' +
                '   Demand Score: ' + score + '/100\n' +
                '   Competition: ' + comp + ' (' + distStr + ')\n' +
                '   Est. Monthly Revenue: INR ' + rev.longValue() + '\n' +
                '   Payback: ' + payback + ' years\n'
            );
            rank++;
        }

        res.summary = String.join(lines, '\n');
        SObject top = sites[0];
        res.topLocationName = (String) top.get('Name') + ', ' + (String) top.get('City__c');
        res.topLocationScore = top.get('Demand_Score__c') != null ? (Decimal) top.get('Demand_Score__c') : 0;
        results.add(res);
        return results;
    }

    public class BlindSpotRequest {
        @InvocableVariable(label='Minimum Demand Score' description='Minimum score threshold, default 65')
        public Decimal minDemandScore;
        @InvocableVariable(label='City Filter' description='Optional city filter e.g. Mumbai')
        public String city;
    }

    public class BlindSpotResult {
        @InvocableVariable public String  summary;
        @InvocableVariable public Integer siteCount;
        @InvocableVariable public String  topLocationName;
        @InvocableVariable public Decimal topLocationScore;
    }
}