import { LightningElement, api, wire, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import getProposedSites from '@salesforce/apex/ExpansionDashboardController.getProposedSites';

const COLUMNS = [
    { label: 'Location', fieldName: 'name', sortable: true },
    { label: 'City', fieldName: 'city', sortable: true },
    { label: 'Demand Score', fieldName: 'demandScore', type: 'number', sortable: true },
    { label: 'Competition', fieldName: 'competitorDensity', sortable: true },
    {
        label: 'Est. Revenue (INR/mo)', fieldName: 'projectedRevenue', type: 'currency',
        typeAttributes: { currencyCode: 'INR', minimumFractionDigits: 0 }
    },
    { label: 'Payback (yrs)', fieldName: 'paybackPeriodYears', type: 'number' },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'View scorecard', name: 'scorecard' }
            ]
        }
    }
];

const COLOR_MAP   = { Low: '#1D9E7580', Medium: '#BA751780', High: '#A32D2D80' };
const BORDER_MAP  = { Low: '#1D9E75',   Medium: '#BA7517',   High: '#A32D2D'  };

export default class ExpansionDashboard extends LightningElement {
    @track allSites = [];
    @track isLoading = true;
    @track selectedCity = 'All';
    @track selectedCompetition = 'All';
    @track minScore = 0;
    @track sortBy = 'demandScore';
    @track sortDirection = 'desc';

    @api chartTitle = 'Store Expansion Intelligence';
    columns = COLUMNS;
    chartLoaded = false;
    chartInstance = null;

    cityOptions = [
        { label: 'All cities',  value: 'All'       },
        { label: 'Mumbai',      value: 'Mumbai'     },
        { label: 'Jaipur',      value: 'Jaipur'     },
        { label: 'Bangalore',   value: 'Bangalore'  },
        { label: 'Delhi',       value: 'Delhi'      }
    ];

    competitionOptions = [
        { label: 'All levels',              value: 'All'    },
        { label: 'Low only (blind spots)',  value: 'Low'    },
        { label: 'Medium',                  value: 'Medium' },
        { label: 'High',                    value: 'High'   }
    ];

    get sliderLabel() { return `Min Demand Score: ${this.minScore}`; }

    get filteredSites() {
        return this.allSites
            .filter(s =>
                (this.selectedCity === 'All' || s.city === this.selectedCity) &&
                (this.selectedCompetition === 'All' || s.competitorDensity === this.selectedCompetition) &&
                (s.demandScore == null || s.demandScore >= this.minScore)
            )
            .slice()
            .sort((a, b) => {
                const av = a[this.sortBy] || 0;
                const bv = b[this.sortBy] || 0;
                return this.sortDirection === 'desc' ? bv - av : av - bv;
            });
    }

    get kpiCards() {
        const sites = this.filteredSites;
        const highDemand = sites.filter(s => (s.demandScore || 0) >= 70).length;
        const blindSpots = sites.filter(s => (s.demandScore || 0) >= 65 && s.competitorDensity === 'Low').length;
        const avgScore = sites.length > 0
            ? (sites.reduce((a, b) => a + (b.demandScore || 0), 0) / sites.length).toFixed(1)
            : '—';
        const topRev = sites.length > 0
            ? Math.max(...sites.map(s => s.projectedRevenue || 0))
            : 0;
        return [
            { id: 'total',   value: sites.length, label: 'Prospect sites',      sub: 'total in view',         cssClass: 'kpi-card kpi-neutral' },
            { id: 'high',    value: highDemand,   label: 'High demand sites',    sub: 'score >= 70',           cssClass: 'kpi-card kpi-green'   },
            { id: 'blind',   value: blindSpots,   label: 'Blind spots',          sub: 'high demand, low comp', cssClass: 'kpi-card kpi-amber'   },
            { id: 'revenue', value: topRev > 0 ? 'INR ' + topRev.toLocaleString('en-IN') : '—', label: 'Top site revenue', sub: 'est. monthly', cssClass: 'kpi-card kpi-blue' }
        ];
    }

    @wire(getProposedSites)
    wiredSites({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.allSites = data;
            this.renderChart();
        } else if (error) {
            console.error('Error loading sites', error);
        }
    }

    connectedCallback() {
        loadScript(this, 'https://cdn.jsdelivr.net/npm/chart.js@4/dist/chart.umd.min.js')
            .then(() => { this.chartLoaded = true; this.renderChart(); })
            .catch(e => console.error('Chart.js load error', e));
    }

    renderChart() {
        if (!this.chartLoaded || !this.filteredSites.length) return;
        const canvas = this.refs.chartCanvas;
        if (!canvas) return;
        const ctx = canvas.getContext('2d');
        if (this.chartInstance) { this.chartInstance.destroy(); this.chartInstance = null; }

        const sites = this.filteredSites;
        const maxRev = Math.max(...sites.map(s => s.projectedRevenue || 1));

        /* global Chart */
        this.chartInstance = new Chart(ctx, {
            type: 'bubble',
            data: {
                datasets: [{
                    label: 'Proposed sites',
                    data: sites.map(s => ({
                        x: s.demandScore || 0,
                        y: (s.nearestCompetitorDistanceM || 0) / 1000,
                        r: Math.max(6, Math.min(28, ((s.projectedRevenue || 0) / maxRev) * 28)),
                        name: s.name,
                        city: s.city,
                        comp: s.competitorDensity,
                        rev:  s.projectedRevenue
                    })),
                    backgroundColor: sites.map(s => COLOR_MAP[s.competitorDensity] || '#88878080'),
                    borderColor:     sites.map(s => BORDER_MAP[s.competitorDensity] || '#888780'),
                    borderWidth: 1.5
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        callbacks: {
                            title: (items) => items[0].raw.name + ', ' + items[0].raw.city,
                            label: (item) => [
                                `Demand Score: ${item.raw.x}/100`,
                                `Nearest rival: ${(item.raw.y).toFixed(1)}km`,
                                `Monthly revenue: INR ${(item.raw.rev || 0).toLocaleString('en-IN')}`,
                                `Competition: ${item.raw.comp}`
                            ]
                        }
                    }
                },
                scales: {
                    x: {
                        min: 0, max: 100,
                        title: { display: true, text: 'Demand Score (0=low, 100=high)', font: { size: 12 } },
                        grid: { color: 'rgba(136,135,128,0.15)' }
                    },
                    y: {
                        min: 0,
                        title: { display: true, text: 'Distance to nearest competitor (km)', font: { size: 12 } },
                        grid: { color: 'rgba(136,135,128,0.15)' }
                    }
                }
            }
        });
    }

    handleCityChange(e)        { this.selectedCity        = e.detail.value; this.renderChart(); }
    handleScoreFilter(e)       { this.minScore            = Number(e.detail.value); this.renderChart(); }
    handleCompetitionChange(e) { this.selectedCompetition = e.detail.value; this.renderChart(); }
    handleSort(e)              { this.sortBy = e.detail.fieldName; this.sortDirection = e.detail.sortDirection; }

    refreshData() {
        this.isLoading = true;
        this.allSites = [];
    }

    handleRowAction(e) {
        const row = e.detail.row;
        this.dispatchEvent(new CustomEvent('scorecard', { detail: row }));
    }
}
