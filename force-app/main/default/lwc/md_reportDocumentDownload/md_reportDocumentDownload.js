import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getDocumentInfo from "@salesforce/apex/md_reportDocumentDownloadController.getDocumentInfo";
import downloadNFE from "@salesforce/apex/md_reportDocumentDownloadController.downloadNFE";
import downloadZBQI from "@salesforce/apex/md_reportDocumentDownloadController.downloadZBQI";
import downloadNfeXml from "@salesforce/apex/md_reportDocumentDownloadController.downloadNfeXml";

const DOCUMENT_TYPES = {
    NFE: "nfe",
    ZBQI: "zbqi",
    XML: "xml",
    DOWNLOAD_ALL: "download_all",
};

const DOCUMENT_CONFIG = {
    [DOCUMENT_TYPES.NFE]: {
        label: "NFE",
        downloadApex: downloadNFE,
        fileNamePrefix: "NF",
        idRequired: "shipmentItemId",
    },
    [DOCUMENT_TYPES.ZBQI]: {
        label: "ZBQI",
        downloadApex: downloadZBQI,
        fileNamePrefix: "ZBQI",
        idRequired: "shipmentItemId",
        apexParams: (deliveryNumber, itemNumber) => ({ strBillingDocNumber: deliveryNumber, strItemNumber: itemNumber }),
    },
    [DOCUMENT_TYPES.XML]: {
        label: "XML",
        downloadApex: downloadNfeXml,
        fileNamePrefix: "NFe",
        idRequired: "shipmentItemId",
    },
};

export default class Md_reportDocumentDownload extends LightningElement {
    @api OrderId;
    @api ShipmentItemId;
    @api nfeFounded = false;
    @api zbqiFounded = false;
    @api xmlFounded = false;
    @api documentType = DOCUMENT_TYPES.NFE;

    @api get orderId() { return this.OrderId; }
    set orderId(value) { this.OrderId = value; }

    @api get shipmentItemId() { return this.ShipmentItemId; }
    set shipmentItemId(value) { this.ShipmentItemId = value; }

    isLoading = false;

    get isNFEButton() { return this.nfeFounded && this.documentType === DOCUMENT_TYPES.NFE; }
    get isZBQIButton() { return this.zbqiFounded && this.documentType === DOCUMENT_TYPES.ZBQI; }
    get isXMLButton() { return this.xmlFounded && this.documentType === DOCUMENT_TYPES.XML; }

    get isDownloadAllButton() {
        return this.documentType === DOCUMENT_TYPES.DOWNLOAD_ALL &&
            (this.nfeFounded || this.zbqiFounded);
    }

    get iconName() {
        return this.isLoading
            ? "utility:spinner"
            : (this.documentType === DOCUMENT_TYPES.DOWNLOAD_ALL ? "utility:download" : "utility:preview");
    }

    async handleClick() {
        await this._processDocumentRequest(this.documentType);
    }

    async _processDocumentRequest(documentType) {
        if (!this.orderId && !this.shipmentItemId) {
            this._dispatchDocumentEvent("documentdownloaderror", {
                documentType,
                orderId: this.orderId,
                shipmentItemId: this.shipmentItemId,
                error: "ID do registro é obrigatório",
            });
            return;
        }

        this._dispatchDocumentEvent("documentdownloadstart", { documentType, orderId: this.orderId, shipmentItemId: this.shipmentItemId });
        this.isLoading = true;

        try {
            if (documentType === DOCUMENT_TYPES.DOWNLOAD_ALL) {
                await this._handleDownloadAll();
            } else {
                await this._handleSingleDocumentView(documentType);
            }
            this._dispatchDocumentEvent("documentdownloadsuccess", { documentType, orderId: this.orderId, shipmentItemId: this.shipmentItemId });
        } catch (error) {
            this._handleError(error, documentType);
        } finally {
            this.isLoading = false;
            this._dispatchDocumentEvent("documentdownloadcomplete", { documentType, orderId: this.orderId, shipmentItemId: this.shipmentItemId });
        }
    }

    async _handleSingleDocumentView(documentType) {
        const config = DOCUMENT_CONFIG[documentType];
        if (!config) throw new Error(`Tipo de documento não suportado: ${documentType}`);

        if (!this.shipmentItemId) throw new Error(`ID do ShipmentItem é obrigatório para visualizar ${config.label}`);

        let downloadResult;

        if (documentType === DOCUMENT_TYPES.NFE) {
            downloadResult = await downloadNFE({ shipmentItemId: this.shipmentItemId });
            const fileName = `NF_${downloadResult.invoiceNumber || this.shipmentItemId}.pdf`;
            this._handleDownloadResult(downloadResult, fileName, config.label, true);

        } else if (documentType === DOCUMENT_TYPES.ZBQI) {
            const docInfo = await getDocumentInfo({ shipmentItemId: this.shipmentItemId });
            if (!docInfo.success) throw new Error(docInfo.message || `Erro ao recuperar informações do documento ${config.label}`);

            const fileName = `ZBQI_${docInfo.deliveryNumber}.pdf`;
            downloadResult = await downloadZBQI(config.apexParams(docInfo.deliveryNumber, docInfo.itemNumber));
            this._handleDownloadResult(downloadResult, fileName, config.label, true);

        } else if (documentType === DOCUMENT_TYPES.XML) {
            downloadResult = await downloadNfeXml({ shipmentItemId: this.shipmentItemId });
            const fileName = `NFe_${downloadResult.invoiceNumber || this.shipmentItemId}.xml`;
            this._handleXmlDownloadResult(downloadResult, fileName, config.label);
        }
    }

    async _handleDownloadAll() {
        const documentsToDownload = [
            this.nfeFounded && DOCUMENT_TYPES.NFE,
            this.zbqiFounded && DOCUMENT_TYPES.ZBQI,
        ].filter(Boolean);

        let docInfo;
        try {
            const raw = await getDocumentInfo({ shipmentItemId: this.shipmentItemId });
            if (raw.success) docInfo = raw;
        } catch (error) {
            console.warn("Could not retrieve document info for download all:", error.message);
        }

        let downloadedCount = 0;
        const errors = [];

        for (const docType of documentsToDownload) {
            const config = DOCUMENT_CONFIG[docType];
            try {
                let downloadResult;
                let fileName;

                if (docType === DOCUMENT_TYPES.NFE) {
                    downloadResult = await downloadNFE({ shipmentItemId: this.shipmentItemId });
                    fileName = `NF_${downloadResult.invoiceNumber || this.shipmentItemId}.pdf`;

                } else if (docType === DOCUMENT_TYPES.ZBQI) {
                    if (!docInfo) throw new Error("Informações do documento indisponíveis — não foi possível resolver o número de entrega para ZBQI");
                    downloadResult = await downloadZBQI(config.apexParams(docInfo.deliveryNumber, docInfo.itemNumber));
                    fileName = `ZBQI_${docInfo.deliveryNumber}.pdf`;
                }

                if (downloadResult?.success && downloadResult.pdfData?.trim()) {
                    this._downloadPdfFile(downloadResult.pdfData, fileName);
                    downloadedCount++;
                } else {
                    throw new Error(downloadResult?.message || `Falha no download de ${config.label}`);
                }
            } catch (error) {
                const errorMsg = `${config.label}: ${error.message}`;
                errors.push(errorMsg);
                this._dispatchDocumentEvent("documentdownloaderror", {
                    documentType: DOCUMENT_TYPES.DOWNLOAD_ALL,
                    orderId: this.orderId,
                    shipmentItemId: this.shipmentItemId,
                    error: errorMsg,
                });
            }
        }

        if (downloadedCount > 0) {
            let message = `Download concluído! ${downloadedCount} de ${documentsToDownload.length} documentos baixados.`;
            if (errors.length > 0) message += ` Erros: ${errors.join(", ")}.`;
            this._showToast("Sucesso", message, "success");
        } else {
            const errorMessage = errors.length > 0 ? errors.join(", ") : "Nenhum documento foi baixado com sucesso.";
            this._handleError({ message: errorMessage }, DOCUMENT_TYPES.DOWNLOAD_ALL);
        }
    }

    _handleDownloadResult(downloadResult, fileName, label, openInTab) {
        if (downloadResult.success && downloadResult.pdfData?.trim()) {
            if (openInTab) {
                this._openPdfInNewTab(downloadResult.pdfData, fileName);
            } else {
                this._downloadPdfFile(downloadResult.pdfData, fileName);
            }
        } else {
            throw new Error(downloadResult.message || `Documento não encontrado no servidor ou erro ao abrir ${label}`);
        }
    }

    _handleXmlDownloadResult(downloadResult, fileName, label) {
        if (downloadResult.success && downloadResult.xmlData?.trim()) {
            this._downloadXmlFile(downloadResult.xmlData, fileName);
        } else {
            throw new Error(downloadResult.message || `Documento não encontrado no servidor ou erro ao obter ${label}`);
        }
    }

    _downloadXmlFile(xmlText, filename) {
        if (!xmlText?.trim()) { this._showToast("Erro", "Documento não encontrado", "error"); return; }
        try {
            const url = URL.createObjectURL(new Blob([xmlText], { type: "application/xml" }));
            this._createTemporaryLink(url, filename, true);
            setTimeout(() => URL.revokeObjectURL(url), 1000);
        } catch (error) {
            this._showToast("Erro", "Erro ao baixar XML: " + error.message, "error");
        }
    }

    _openPdfInNewTab(base64Data, filename) {
        if (!base64Data?.trim()) { this._showToast("Erro", "Documento não encontrado", "error"); return; }
        try {
            const url = URL.createObjectURL(this._base64ToBlob(base64Data, "application/pdf"));
            if (!window.open(url, "_blank")) this._createTemporaryLink(url, filename, false);
            setTimeout(() => URL.revokeObjectURL(url), 30000);
        } catch (error) {
            this._showToast("Erro", "Erro ao processar PDF: " + error.message, "error");
        }
    }

    _downloadPdfFile(base64Data, filename) {
        if (!base64Data?.trim()) { this._showToast("Erro", "Documento não encontrado", "error"); return; }
        try {
            const url = URL.createObjectURL(this._base64ToBlob(base64Data, "application/pdf"));
            this._createTemporaryLink(url, filename, true);
            setTimeout(() => URL.revokeObjectURL(url), 1000);
        } catch (error) {
            this._showToast("Erro", "Erro ao baixar PDF: " + error.message, "error");
        }
    }

    _createTemporaryLink(url, filename, download) {
        try {
            const link = document.createElement("a");
            link.href = url;
            if (download) {
                link.download = filename;
            } else {
                link.target = "_blank";
                link.rel = "noopener noreferrer";
                link.textContent = "Abrir PDF";
            }
            link.style.display = "none";
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        } catch (linkError) {
            console.error("PDF: Link approach also failed:", linkError);
            if (!download) this._showToast("Erro", "Não foi possível abrir o PDF. Por favor, tente novamente ou verifique as configurações do seu navegador.", "error");
        }
    }

    _base64ToBlob(base64, contentType) {
        const byteCharacters = atob(base64);
        const byteArray = new Uint8Array(byteCharacters.length);
        for (let i = 0; i < byteCharacters.length; i++) byteArray[i] = byteCharacters.charCodeAt(i);
        return new Blob([byteArray], { type: contentType });
    }

    _dispatchDocumentEvent(eventName, detail) {
        this.dispatchEvent(new CustomEvent(eventName, { detail, bubbles: true, composed: true }));
    }

    _extractErrorMessage(error) {
        if (error?.body?.message) return error.body.message;
        if (error?.body && typeof error.body === "string") return error.body;
        if (error?.message) return error.message;
        if (typeof error === "string") return error;
        return null;
    }

    _handleError(error, documentType) {
        const config = DOCUMENT_CONFIG[documentType];
        const errorMessage = this._extractErrorMessage(error)
            ?? `Erro ao processar o download de ${config ? config.label : "documento"}`;
        this._dispatchDocumentEvent("documentdownloaderror", {
            documentType,
            orderId: this.orderId,
            shipmentItemId: this.shipmentItemId,
            error: errorMessage,
        });
        this._showToast("Erro", errorMessage, "error");
    }

    _showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title || (variant === "error" ? "Erro" : "Sucesso"),
            message,
            variant,
            ...(variant === "error" && { mode: "dismissible" }),
        }));
    }
}