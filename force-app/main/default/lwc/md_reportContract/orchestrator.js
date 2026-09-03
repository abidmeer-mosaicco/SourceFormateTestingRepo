import getLatestQuoteIdsForAccounts from "@salesforce/apex/md_reportContractController.getLatestQuoteIdsForAccounts";
import getWhereClauseExcludingRejected from "@salesforce/apex/md_reportContractController.getWhereClauseExcludingRejected";
import getContractEnrichmentData from "@salesforce/apex/md_reportContractController.getContractEnrichmentData";
import hasDebug from "@salesforce/customPermission/MD_DEBUG";

const DEBUG = (...args) => {
    if (hasDebug) console.log("[md_reportContract]", ...args);
};

const ENRICHMENT_CHUNK_SIZE = 1000;
const ENRICHMENT_CONCURRENCY = 5;

export default class ContractReportOrchestrator {
    constructor({ onProgress, onComplete, onError } = {}) {
        this._onProgress = onProgress || (() => { });
        this._onComplete = onComplete || (() => { });
        this._onError = onError || ((e) => console.error("[ContractReportOrchestrator]", e));
        this._aborted = false;
    }

    start(accountIds) {
        if (!accountIds?.length) {
            this._onError(new Error("accountIds is empty."));
            return;
        }
        this._aborted = false;
        this._run(accountIds).catch((err) => this._onError(err));
    }

    abort() {
        this._aborted = true;
    }

    async _run(accountIds) {
        this._onProgress({ stage: "collecting_quotes" });

        const quoteIds = await getLatestQuoteIdsForAccounts({ accountIds });
        if (this._aborted) return;

        if (!quoteIds?.length) {
            this._onComplete({ quoteIds: [], rejectedClause: "", enrichmentMap: {} });
            return;
        }

        this._onProgress({ stage: "collecting_rejected" });

        const rejectedClause = await getWhereClauseExcludingRejected({ quoteIds });
        if (this._aborted) return;

        const enrichmentMap = {};
        const chunks = [];
        for (let i = 0; i < quoteIds.length; i += ENRICHMENT_CHUNK_SIZE) {
            chunks.push(quoteIds.slice(i, i + ENRICHMENT_CHUNK_SIZE));
        }

        for (let i = 0; i < chunks.length; i += ENRICHMENT_CONCURRENCY) {
            if (this._aborted) return;
            this._onProgress({ stage: "collecting_enrichment", count: i * ENRICHMENT_CHUNK_SIZE, total: quoteIds.length });

            const batch = chunks.slice(i, i + ENRICHMENT_CONCURRENCY);
            const results = await Promise.all(batch.map((chunk) => getContractEnrichmentData({ quoteIds: chunk })));
            if (this._aborted) return;

            results.forEach((enrichmentList) => {
                (enrichmentList || []).forEach((item) => {
                    if (item?.quoteLineId) enrichmentMap[item.quoteLineId] = item;
                });
            });
        }

        this._onComplete({ quoteIds, rejectedClause: rejectedClause || "", enrichmentMap });
    }
}