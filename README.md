# Store Expansion Strategy Advisor
### Agentforce Hackathon 2025 — Retail & Consumer Goods Cloud Track

AI-powered retail site intelligence built on Salesforce. Helps the Central Planning Team identify optimal new store locations by synthesizing footfall data, competitor proximity, and demographic insights into real-time recommendations via Agentforce and WhatsApp.

---

## The Problem

A leading Indian retail brand needs to evaluate potential store locations across Mumbai, Bangalore, and Jaipur. The current process — manually cross-referencing footfall surveys, competitor maps, and census data — takes weeks and produces inconsistent results. Leadership has no real-time answer to: *"Where should our next store be?"*

## The Solution

A unified intelligence platform that:
- **Scores every proposed site** using a Data Cloud Calculated Insight combining footfall (50%), demographic growth (30%), and competitor proximity (20%)
- **Advises the planning team** through an Agentforce agent that answers natural language questions about sites, blind spots, and financial projections
- **Empowers field surveyors** to WhatsApp a location name and receive a full AI-generated scorecard in seconds

---

## Architecture

```
External Data Sources                  Salesforce Data Cloud
┌─────────────────────┐               ┌───────────────────────────────────┐
│ footfall_data.csv   │──── Stream ──▶│ Footfall_DMO                      │
│ competitor_data.csv │──── Stream ──▶│ Competitor_DMO  ──▶ Demand Score  │
│ demographic_data.csv│──── Stream ──▶│ Demographic_DMO     CI (SQL)      │
│ Salesforce CRM      │──── Stream ──▶│ Location_Home_DMO                 │
└─────────────────────┘               └──────────────┬────────────────────┘
                                                      │ Data Cloud Triggered Flow
                                                      ▼
                                         Location Records (CRM)
                                         Demand_Score__c, Payback_Period_Years__c, etc.
                                                      │
                              ┌───────────────────────┼────────────────────────┐
                              ▼                       ▼                        ▼
                    Agentforce Agent          LWC Dashboard             WhatsApp
                    (SOQL queries)            (Bubble Chart)           (REST Webhook)
```

---

## Features

### 1. Automated Site Scoring
Every proposed site gets a **Demand Score (0–100)** computed by a Data Cloud Calculated Insight:

```
Demand Score = (footfall_daily / footfall_max) × 50
             + (annual_growth_rate) × 0.3
             - (competitor_distance / max_competitors / 500) × 20
```

Scores are written back to `Location` records via Data Cloud-triggered Flows, giving Agentforce sub-second SOQL access.

### 2. Agentforce Expansion Strategy Advisor
Natural language interface for the planning team:
- *"Score the Marol Naka Site"* → full scorecard with demand score, competition level, revenue, payback, verdict
- *"Where should we open next in Bangalore?"* → ranked blind spots (high demand + low competition)
- *"What is the payback period for C-Scheme Central?"* → financial analysis

### 3. Expansion Intelligence Dashboard (LWC)
Built with Vibe Coding — bubble chart where:
- **X-axis:** Demand Score
- **Y-axis:** Distance to nearest competitor (km)
- **Bubble size:** Projected monthly revenue
- **Colour:** Competition level (green = Low, amber = Medium, red = High)

Includes KPI cards (total sites, high-demand count, blind spots, top revenue) and live city/competition filters.

### 4. WhatsApp Field Intelligence
Field surveyors send a location name via WhatsApp and receive the full AI scorecard in seconds — no computer required.

```
Surveyor: "Marol Naka Site"
Bot:       SITE SCORECARD
           Location: Marol Naka Site, Mumbai
           Demand Score: 34.89/100
           Competition: Low (380m to nearest rival)
           Est. Monthly Revenue: INR 21,85,000
           Payback Period: 2.3 years
           Verdict: RECOMMENDED
           Powered by Agentforce
```

---

## Tech Stack

| Component | Technology |
|---|---|
| CRM Objects | Salesforce Consumer Goods Cloud — `Location` (Proposed_Site Record Type), `RetailLocationGroup` |
| AI Agent | Agentforce — `Expansion_Strategy_Advisor` with 2 subagents |
| Data Unification | Salesforce Data Cloud — 4 streams, 3 DMOs, 2 Calculated Insights |
| Score Writeback | Data Cloud-triggered Flows → Location records |
| Apex Actions | `AnalyzeSiteScore`, `FindBlindSpots` (InvocableMethods) |
| Dashboard | LWC `expansionDashboard` with Chart.js |
| Agent Flows | `Analyze_Site_Score_Flow`, `Find_Blind_Spots_Flow` |
| WhatsApp | Meta WhatsApp Cloud API v18.0 + Force.com Site REST endpoint |
| Deployment | Salesforce CLI + MCP (full metadata pipeline) |

---

## Project Structure

```
force-app/main/default/
├── bots/                          # Agentforce agent definition
├── classes/                       # Apex — AnalyzeSiteScore, FindBlindSpots,
│                                  #        ExpansionDashboardController, WhatsAppScorecardHandler
├── dataStreamDefinitions/         # Data Cloud stream definitions (4 streams)
├── flows/                         # Agentforce action flows + Data Cloud triggered flows
├── genAiPlugins/                  # Agentforce subagent topics
├── lwc/expansionDashboard/        # Bubble chart dashboard component
├── mktCalcInsightObjectDefs/      # Calculated Insights (Demand Score + Financial)
├── objects/
│   ├── Location/                  # 11 custom fields + Proposed_Site record type
│   ├── *__dlm/                    # Data Cloud DMO definitions
│   ├── Location_Update_Target__e/ # Platform Event for score writeback
│   └── WhatsApp_Config__mdt/      # WhatsApp API token storage
├── permissionsets/                # Expansion_Agent_PS
├── profiles/                      # WhatsApp site guest user profile
├── remoteSiteSettings/            # Meta Graph API
├── sites/                         # Force.com Site for public webhook endpoint
└── triggers/                      # LocationUpdateTargetTrigger (Platform Event handler)

data_cloud/
├── footfall_data.csv              # 10 location footfall records
├── competitor_data.csv            # 10 competitor locations
├── demographic_data.csv           # 10 demographic records
├── ci_demand_score.sql            # Calculated Insight SQL (Demand Score)
└── ci_financial_projection.sql    # Calculated Insight SQL (Financial)

scripts/apex/
├── insertDemoData.apex            # Loads 10 demo Location records
└── createRetailGroups.apex        # Creates RetailLocationGroup hierarchy
```

---

## Data Cloud Setup

The Data Cloud components cannot be deployed via CLI and must be configured in the UI:

**Data Streams** — Upload the 3 CSV files in `data_cloud/`:

| File | Stream Name | DMO | Primary Key |
|---|---|---|---|
| `footfall_data.csv` | `Footfall_Stream` | `Footfall_DMO` | `location_name` |
| `competitor_data.csv` | `Competitor_Stream` | `Competitor_DMO` | `competitor_name` |
| `demographic_data.csv` | `Demographic_Stream` | `Demographic_DMO` | `location_name` |

Plus one CRM stream: Data Cloud → Data Streams → New → Salesforce CRM → `Location` object → name `Location_Home`.

**Calculated Insights** — Paste SQL from `data_cloud/ci_demand_score.sql` and `data_cloud/ci_financial_projection.sql` into Data Cloud → Calculated Insights → New. Schedule: Every 12 Hours.

---

## Deployment

```bash
# Authenticate
sf org login web --alias hackathon

# Deploy all metadata
sf project deploy start --source-dir force-app --target-org hackathon --wait 10

# Load demo data (run once)
sf apex run --file scripts/apex/insertDemoData.apex --target-org hackathon
sf apex run --file scripts/apex/createRetailGroups.apex --target-org hackathon
```

---

## Demo Sites (Pre-loaded)

| Location | City | Demand Score | Verdict |
|---|---|---|---|
| C-Scheme Central | Jaipur | 36.12 | RECOMMENDED |
| Koramangala 5th Block | Bangalore | 34.96 | RECOMMENDED |
| Marol Naka Site | Mumbai | 34.89 | RECOMMENDED |
| HSR Layout Sector 2 | Bangalore | 32.18 | POSSIBLE |
| Indiranagar 100ft Road | Bangalore | 29.40 | POSSIBLE |
| Kurla West Junction | Mumbai | 28.94 | POSSIBLE |
| Andheri Station East | Mumbai | 27.18 | POSSIBLE |
| Malviya Nagar Crossing | Jaipur | 26.76 | POSSIBLE |
| Whitefield Main Road | Bangalore | 23.15 | NOT RECOMMENDED |
| Vaishali Nagar West | Jaipur | 21.58 | NOT RECOMMENDED |

---

## Potential Improvements

1. **Real-time footfall** — Replace CSV with live IoT/mobile location feeds via Data Cloud connectors
2. **Geospatial visualisation** — Salesforce Maps integration with drive-time isochrones to nearest competitor
3. **Automated competitor intelligence** — Nightly scraping of competitor store locators into Data Cloud
4. **WhatsApp photo analysis** — Einstein Vision to assess storefront viability from field photos
5. **Approval workflow** — Auto-trigger due diligence task assignment for RECOMMENDED sites
6. **Multi-brand support** — Extend data model to support brand-specific demand weighting
7. **Dynamic financial modelling** — Replace static payback formula with POS benchmarks from existing stores

---

## Team

Built for the **Agentforce Hackathon 2025 — Retail & Consumer Goods Cloud** track.
