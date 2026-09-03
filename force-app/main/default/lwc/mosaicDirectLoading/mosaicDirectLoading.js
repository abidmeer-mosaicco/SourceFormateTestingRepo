import { LightningElement, track } from 'lwc';

const ORCHESTRATOR_EVENT = 'openAmountProgress';

const STAGE_LABELS = {
    collecting_sold_to: 'Buscando contas...',
    collecting_payers: 'Refinando os resultados...',
    fetching_sap: 'Consultando a integração...'
};

export default class MosaicDirectLoading extends LightningElement {
    @track isLoading = false;
    @track loadingStatus = {};
    @track isOrchestratorLoading = false;
    @track orchestratorTitle = '';
    @track orchestratorStageLabel = '';
    @track orchestratorCount = 0;
    @track orchestratorPage = null;

    _loadingRequests = 0;
    _boundLoadingEvent = this.handleLoadingEvent.bind(this);
    _boundOrchestratorEvent = this.handleOrchestratorEvent.bind(this);

    connectedCallback() {
        window.addEventListener('loadingEvent', this._boundLoadingEvent);
        window.addEventListener(ORCHESTRATOR_EVENT, this._boundOrchestratorEvent);
    }

    disconnectedCallback() {
        window.removeEventListener('loadingEvent', this._boundLoadingEvent);
        window.removeEventListener(ORCHESTRATOR_EVENT, this._boundOrchestratorEvent);
    }

    handleLoadingEvent(event) {
        const detail = event?.detail;
        if (!detail) return;

        console.log('[LoadingEvent]', detail);
        const name = detail.name || detail.id;

        if (name) {
            this._handleNamedAction(name, detail.action);
        } else {
            this._handleLegacyAction(detail.action);
        }

        this._updateLoadingState();
    }

    handleOrchestratorEvent(event) {
        const detail = event?.detail;
        if (!detail) return;

        if (detail.action === 'start') {
            this.isOrchestratorLoading = true;
            this.orchestratorTitle = detail.title || 'Sincronizando com o SAP...';
            this.orchestratorStageLabel = STAGE_LABELS.collecting_sold_to || 'Inicializando...';
            this.orchestratorCount = 0;
            this.orchestratorPage = null;
            return;
        }

        if (detail.action === 'stop') {
            this.isOrchestratorLoading = false;
            this.orchestratorTitle = '';
            this.orchestratorStageLabel = '';
            this.orchestratorCount = 0;
            this.orchestratorPage = null;
            return;
        }

        if (detail.action === 'progress') {
            this.orchestratorStageLabel = detail.label || STAGE_LABELS[detail.stage] || 'Loading...';
            this.orchestratorCount = detail.count ?? this.orchestratorCount;
            this.orchestratorPage = detail.sapPage ?? null;
        }
    }

    get orchestratorProgressLabel() {
        const parts = [this.orchestratorStageLabel];
        if (this.orchestratorCount > 0) parts.push(`(${this.orchestratorCount} registros)`);
        return parts.join(' ');
    }

    _handleNamedAction(name, action) {
        const isStart = action === 'start';
        this.loadingStatus = { ...this.loadingStatus, [name]: isStart };
    }

    _handleLegacyAction(action) {
        if (action === 'start') {
            this._loadingRequests++;
            return;
        }

        if (action === 'stop') {
            this._loadingRequests = Math.max(0, this._loadingRequests - 1);
            return;
        }

        this._loadingRequests = this.isLoading ? 0 : 1;
    }

    _updateLoadingState() {
        const hasActiveNamedProcess = Object.values(this.loadingStatus).some(val => val === true);
        this.isLoading = this._loadingRequests > 0 || hasActiveNamedProcess;
    }
}