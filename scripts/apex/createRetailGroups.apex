// Create RetailLocationGroup hierarchy for demo
// India → West Zone / South Zone → Mumbai / Jaipur / Bangalore → Area level

// Level 0 - Country
RetailLocationGroup india = new RetailLocationGroup(
    Name = 'India',
    Description = 'National expansion territory — all proposed sites across India'
);
insert india;

// Level 1 - Zones
RetailLocationGroup westZone = new RetailLocationGroup(
    Name = 'West Zone',
    Description = 'Western India zone covering Mumbai and Jaipur markets'
);
RetailLocationGroup southZone = new RetailLocationGroup(
    Name = 'South Zone',
    Description = 'Southern India zone covering Bangalore market'
);
insert new List<RetailLocationGroup>{ westZone, southZone };

// Level 2 - Cities
RetailLocationGroup mumbai = new RetailLocationGroup(
    Name = 'Mumbai',
    Description = 'Mumbai city — 3 proposed sites including high-demand Marol Naka'
);
RetailLocationGroup jaipur = new RetailLocationGroup(
    Name = 'Jaipur',
    Description = 'Jaipur city — 3 proposed sites including C-Scheme Central'
);
RetailLocationGroup bangalore = new RetailLocationGroup(
    Name = 'Bangalore',
    Description = 'Bangalore city — 4 proposed sites including top-ranked Koramangala'
);
insert new List<RetailLocationGroup>{ mumbai, jaipur, bangalore };

// Level 3 - Areas
RetailLocationGroup andheriEast = new RetailLocationGroup(
    Name = 'Andheri East',
    Description = 'Andheri East micro-market — Marol Naka site (Demand Score: 34.89, RECOMMENDED)'
);
RetailLocationGroup malviyaNagar = new RetailLocationGroup(
    Name = 'Malviya Nagar',
    Description = 'Malviya Nagar micro-market — Jaipur prime retail corridor'
);
RetailLocationGroup cScheme = new RetailLocationGroup(
    Name = 'C-Scheme',
    Description = 'C-Scheme micro-market — highest scoring Jaipur site (36.12)'
);
RetailLocationGroup koramangala = new RetailLocationGroup(
    Name = 'Koramangala',
    Description = 'Koramangala micro-market — Bangalore top site (Demand Score: 34.96)'
);
RetailLocationGroup hsrLayout = new RetailLocationGroup(
    Name = 'HSR Layout',
    Description = 'HSR Layout micro-market — Bangalore high-growth residential area'
);
insert new List<RetailLocationGroup>{ andheriEast, malviyaNagar, cScheme, koramangala, hsrLayout };

System.debug('SUCCESS: Created RetailLocationGroup hierarchy');
System.debug('India → West Zone (Mumbai, Jaipur) + South Zone (Bangalore)');
System.debug('IDs: India=' + india.Id + ', West Zone=' + westZone.Id + ', South Zone=' + southZone.Id);
