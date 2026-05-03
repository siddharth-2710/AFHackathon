Id rtId = [SELECT Id FROM RecordType WHERE SobjectType='Location' AND DeveloperName='Proposed_Site' LIMIT 1].Id;

Schema.SObjectType locType = Schema.getGlobalDescribe().get('Location');

String[] names   = new String[]{ 'Marol Naka Site', 'Kurla West Junction', 'Andheri Station East', 'Malviya Nagar Crossing', 'C-Scheme Central', 'Vaishali Nagar West', 'Koramangala 5th Block', 'HSR Layout Sector 2', 'Indiranagar 100ft Road', 'Whitefield Main Road' };
String[] cities  = new String[]{ 'Mumbai', 'Mumbai', 'Mumbai', 'Jaipur', 'Jaipur', 'Jaipur', 'Bangalore', 'Bangalore', 'Bangalore', 'Bangalore' };
Double[] scores  = new Double[]{ 87.4, 71.2, 65.8, 79.1, 68.3, 55.6, 91.2, 82.7, 74.4, 61.1 };
String[] comps   = new String[]{ 'Low', 'Medium', 'High', 'Low', 'Medium', 'High', 'Low', 'Low', 'Medium', 'High' };
Double[] revs    = new Double[]{ 2185000, 1780000, 1320000, 1640000, 1290000, 890000, 2750000, 2210000, 1890000, 1150000 };
Double[] costs   = new Double[]{ 52000000, 48000000, 45000000, 38000000, 36000000, 34000000, 58000000, 54000000, 50000000, 47000000 };
Double[] payback = new Double[]{ 2.3, 3.1, 4.2, 2.7, 3.4, 4.8, 2.1, 2.5, 3.0, 4.5 };
Integer[] dists  = new Integer[]{ 2800, 820, 380, 3200, 1100, 420, 3800, 2900, 950, 310 };
String[] recs    = new String[]{ 'Recommended', 'Recommended', 'Possible', 'Recommended', 'Recommended', 'Possible', 'Recommended', 'Recommended', 'Recommended', 'Possible' };

List<SObject> sites = new List<SObject>();
for (Integer i = 0; i < names.size(); i++) {
    SObject loc = locType.newSObject();
    loc.put('RecordTypeId', rtId);
    loc.put('Name', names[i]);
    loc.put('City__c', cities[i]);
    loc.put('Demand_Score__c', scores[i]);
    loc.put('Competitor_Density__c', comps[i]);
    loc.put('Projected_Revenue__c', revs[i]);
    loc.put('Estimated_Setup_Cost__c', costs[i]);
    loc.put('Payback_Period_Years__c', payback[i]);
    loc.put('Nearest_Competitor_Distance_M__c', dists[i]);
    loc.put('Site_Recommendation__c', recs[i]);
    loc.put('Scorecard_Last_Updated__c', Datetime.now());
    sites.add(loc);
}

insert sites;
System.debug('SUCCESS: Inserted ' + sites.size() + ' proposed site records.');
