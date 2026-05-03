import { LightningElement, api, wire, track } from "lwc";
import { loadScript } from "lightning/platformResourceLoader";
import { refreshApex } from "@salesforce/apex";
import chartjs from "@salesforce/resourceUrl/ChartJs";
import getProposedSites from "@salesforce/apex/ExpansionDashboardController.getProposedSites";

const COLUMNS = [
  { label: "Location", fieldName: "name", sortable: true },
  { label: "City", fieldName: "city", sortable: true },
  {
    label: "Demand Score",
    fieldName: "demandScore",
    type: "number",
    sortable: true,
  },
  { label: "Competition", fieldName: "competitorDensity", sortable: true },
  {
    label: "Est. Revenue (INR/mo)",
    fieldName: "projectedRevenue",
    type: "currency",
    typeAttributes: { currencyCode: "INR", minimumFractionDigits: 0 },
  },
  { label: "Payback (yrs)", fieldName: "paybackPeriodYears", type: "number" },
  {
    type: "action",
    typeAttributes: {
      rowActions: [{ label: "View scorecard", name: "scorecard" }],
    },
  },
];

const COLOR_MAP = { Low: "#1D9E7580", Medium: "#BA751780", High: "#A32D2D80" };
const BORDER_MAP = { Low: "#1D9E75", Medium: "#BA7517", High: "#A32D2D" };

export default class ExpansionDashboard extends LightningElement {
  @track allSites = [];
  @track isLoading = true;
  @track selectedCity = "All";
  @track selectedCompetition = "All";
  @track minScore = 0;
  @track sortBy = "demandScore";
  @track sortDirection = "desc";
  @track showModal = false;
  @track selectedSite = {};

  @api chartTitle = "Store Expansion Intelligence";
  columns = COLUMNS;
  chartLoaded = false;
  chartInstance = null;
  _canvasClickHandler = null;

  cityOptions = [
    { label: "All cities", value: "All" },
    { label: "Mumbai", value: "Mumbai" },
    { label: "Jaipur", value: "Jaipur" },
    { label: "Bangalore", value: "Bangalore" },
    { label: "Delhi", value: "Delhi" },
  ];

  competitionOptions = [
    { label: "All levels", value: "All" },
    { label: "Low only (blind spots)", value: "Low" },
    { label: "Medium", value: "Medium" },
    { label: "High", value: "High" },
  ];

  get sliderLabel() {
    return `Min Demand Score: ${this.minScore}`;
  }

  get filteredSites() {
    return this.allSites
      .filter(
        (s) =>
          (this.selectedCity === "All" || s.city === this.selectedCity) &&
          (this.selectedCompetition === "All" ||
            s.competitorDensity === this.selectedCompetition) &&
          (s.demandScore == null || s.demandScore >= this.minScore),
      )
      .slice()
      .sort((a, b) => {
        const av = a[this.sortBy] || 0;
        const bv = b[this.sortBy] || 0;
        return this.sortDirection === "desc" ? bv - av : av - bv;
      });
  }

  get kpiCards() {
    const sites = this.filteredSites;

    // Calculate score thresholds dynamically based on actual data
    const validScores = sites
      .map((s) => s.demandScore)
      .filter((d) => d != null && d > 0);

    // Use 75th percentile for "high demand" threshold, minimum 50
    const sortedScores =
      validScores.length > 0 ? validScores.slice().sort((a, b) => b - a) : [];
    const highDemandThreshold =
      sortedScores.length > 0
        ? Math.max(
            50,
            sortedScores[Math.floor(sortedScores.length * 0.25)] || 50,
          )
        : 50;

    // Use 60th percentile for "blind spots" threshold, minimum 40
    const blindSpotThreshold =
      sortedScores.length > 0
        ? Math.max(
            40,
            sortedScores[Math.floor(sortedScores.length * 0.4)] || 40,
          )
        : 40;

    const highDemand = sites.filter(
      (s) => (s.demandScore || 0) >= highDemandThreshold,
    ).length;
    const blindSpots = sites.filter(
      (s) =>
        (s.demandScore || 0) >= blindSpotThreshold &&
        s.competitorDensity === "Low",
    ).length;
    const topRev =
      sites.length > 0
        ? Math.max(...sites.map((s) => s.projectedRevenue || 0))
        : 0;

    // Debug: Log KPI calculations
    console.log("KPI Debug:", {
      totalSites: sites.length,
      validScores: validScores.length,
      highDemandThreshold,
      blindSpotThreshold,
      highDemand,
      blindSpots,
      lowCompSites: sites.filter((s) => s.competitorDensity === "Low").length,
    });

    return [
      {
        id: "total",
        value: sites.length,
        label: "Prospect sites",
        sub: "total in view",
        cssClass: "kpi-card kpi-neutral",
      },
      {
        id: "high",
        value: highDemand,
        label: "High demand sites",
        sub: `score >= ${Math.round(highDemandThreshold)}`,
        cssClass: "kpi-card kpi-green",
      },
      {
        id: "blind",
        value: blindSpots,
        label: "Blind spots",
        sub: `score >= ${Math.round(blindSpotThreshold)}, low comp`,
        cssClass: "kpi-card kpi-amber",
      },
      {
        id: "revenue",
        value: topRev > 0 ? "INR " + topRev.toLocaleString("en-IN") : "—",
        label: "Top site revenue",
        sub: "est. monthly",
        cssClass: "kpi-card kpi-blue",
      },
    ];
  }

  wiredSitesResult;

  @wire(getProposedSites)
  wiredSites(result) {
    this.wiredSitesResult = result;
    this.isLoading = false;
    if (result.data) {
      this.allSites = result.data;
      // Debug: Log data to verify demand scores
      console.log("Loaded sites:", result.data.length);
      if (result.data.length > 0) {
        console.log("Sample site:", result.data[0]);
        console.log(
          "Demand scores:",
          result.data.map((s) => s.demandScore).filter((d) => d != null),
        );
        console.log("Competition levels:", [
          ...new Set(result.data.map((s) => s.competitorDensity)),
        ]);
      }
      this.renderChart();
    } else if (result.error) {
      console.error("Error loading sites", result.error);
    }
  }

  connectedCallback() {
    loadScript(this, chartjs)
      .then(() => {
        this.chartLoaded = true;
        this.renderChart();
      })
      .catch((e) => console.error("Chart.js load error", e));
  }

  renderChart() {
    if (!this.chartLoaded || !this.filteredSites.length) return;
    const canvas = this.refs.chartCanvas;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");

    if (this.chartInstance) {
      this.chartInstance.destroy();
      this.chartInstance = null;
    }
    if (this._canvasClickHandler) {
      canvas.removeEventListener("click", this._canvasClickHandler);
      this._canvasClickHandler = null;
    }

    const sites = this.filteredSites;
    const maxRev = Math.max(...sites.map((s) => s.projectedRevenue || 1));

    this.chartInstance = new window.Chart(ctx, {
      type: "bubble",
      data: {
        datasets: [
          {
            label: "Proposed sites",
            data: sites.map((s) => ({
              x: s.demandScore || 0,
              y: (s.nearestCompetitorDistanceM || 0) / 1000,
              r: Math.max(
                6,
                Math.min(28, ((s.projectedRevenue || 0) / maxRev) * 28),
              ),
              name: s.name,
              city: s.city,
              comp: s.competitorDensity,
              rev: s.projectedRevenue,
            })),
            backgroundColor: sites.map(
              (s) => COLOR_MAP[s.competitorDensity] || "#88878080",
            ),
            borderColor: sites.map(
              (s) => BORDER_MAP[s.competitorDensity] || "#888780",
            ),
            borderWidth: 1.5,
            hoverBorderWidth: 2.5,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          mode: "nearest",
          intersect: true,
        },
        plugins: {
          legend: { display: false },
          tooltip: {
            enabled: true,
            callbacks: {
              title: (items) => items[0].raw.name + ", " + items[0].raw.city,
              label: (item) => [
                `Demand Score: ${item.raw.x}/100`,
                `Nearest rival: ${item.raw.y.toFixed(1)}km`,
                `Monthly revenue: INR ${(item.raw.rev || 0).toLocaleString("en-IN")}`,
                `Competition: ${item.raw.comp}`,
              ],
            },
          },
        },
        onHover: (_evt, elements) => {
          canvas.style.cursor = elements.length ? "pointer" : "default";
        },
        scales: {
          x: {
            min: 0,
            max: 100,
            title: {
              display: true,
              text: "Demand Score (0=low, 100=high)",
              font: { size: 12 },
            },
            grid: { color: "rgba(136,135,128,0.15)" },
          },
          y: {
            min: 0,
            title: {
              display: true,
              text: "Distance to nearest competitor (km)",
              font: { size: 12 },
            },
            grid: { color: "rgba(136,135,128,0.15)" },
          },
        },
      },
    });

    this._canvasClickHandler = (evt) => {
      const points = this.chartInstance.getElementsAtEventForMode(
        evt,
        "nearest",
        { intersect: true },
        true,
      );
      if (!points.length) return;
      const site = this.filteredSites[points[0].index];
      if (!site) return;
      this.selectedSite = {
        ...site,
        projectedRevenueFormatted: site.projectedRevenue
          ? site.projectedRevenue.toLocaleString("en-IN")
          : "—",
        estimatedSetupCostFormatted: site.estimatedSetupCost
          ? site.estimatedSetupCost.toLocaleString("en-IN")
          : "—",
      };
      this.showModal = true;
    };
    canvas.addEventListener("click", this._canvasClickHandler);
  }

  handleCityChange(e) {
    this.selectedCity = e.detail.value;
    this.renderChart();
  }
  handleScoreFilter(e) {
    this.minScore = Number(e.detail.value);
    this.renderChart();
  }
  handleCompetitionChange(e) {
    this.selectedCompetition = e.detail.value;
    this.renderChart();
  }
  handleSort(e) {
    this.sortBy = e.detail.fieldName;
    this.sortDirection = e.detail.sortDirection;
  }

  refreshData() {
    refreshApex(this.wiredSitesResult);
  }

  handleRowAction(e) {
    const row = e.detail.row;
    if (e.detail.action.name === "scorecard") {
      this.selectedSite = {
        ...row,
        projectedRevenueFormatted: row.projectedRevenue
          ? row.projectedRevenue.toLocaleString("en-IN")
          : "—",
        estimatedSetupCostFormatted: row.estimatedSetupCost
          ? row.estimatedSetupCost.toLocaleString("en-IN")
          : "—",
      };
      this.showModal = true;
    }
  }

  closeModal() {
    this.showModal = false;
    this.selectedSite = {};
  }

  get scoreBadgeClass() {
    const s = this.selectedSite.demandScore || 0;
    return s >= 33
      ? "scorecard-score score-high"
      : s >= 25
        ? "scorecard-score score-mid"
        : "scorecard-score score-low";
  }

  get verdictClass() {
    const v = this.selectedSite.siteRecommendation || "";
    if (v === "Recommended") return "scorecard-verdict verdict-green";
    if (v === "Possible") return "scorecard-verdict verdict-amber";
    return "scorecard-verdict verdict-red";
  }
}
