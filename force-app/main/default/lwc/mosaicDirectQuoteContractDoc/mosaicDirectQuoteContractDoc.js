import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import downloadContractFile from "@salesforce/apex/md_reportContractController.downloadContractFile";

const NO_FILE_MESSAGE = "There is no Sales Contract PDF file available for download.";

export default class MosaicDirectQuoteContractDoc extends LightningElement {
    @api downloadUrl;
    @api fileName;
    @api hasFile = false;

    get isDisabled() {
        return !this.hasFile || !this.downloadUrl;
    }

    get buttonTitle() {
        return this.hasFile ? "Download Sales Contract" : NO_FILE_MESSAGE;
    }

    // Extract ContentVersionId from the shepherd URL pattern
    // e.g. /sfc/servlet.shepherd/version/download/068Su00000HMBavIAH
    get _contentVersionId() {
        if (!this.downloadUrl) return null;
        const match = this.downloadUrl.match(/\/download\/([a-zA-Z0-9]{15,18})/);
        return match ? match[1] : null;
    }

    async handleClick() {
        if (this.isDisabled) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Sales Contract",
                    message: NO_FILE_MESSAGE,
                    variant: "warning"
                })
            );
            return;
        }

        const cvId = this._contentVersionId;
        if (!cvId) {
            this.dispatchEvent(new ShowToastEvent({ title: "Error", message: "Invalid download URL.", variant: "error" }));
            return;
        }

        try {
            const data = await downloadContractFile({ contentVersionId: cvId });
            // Decode base64 → Uint8Array → Blob → same-origin object URL → download
            const binary = atob(data.base64);
            const bytes = new Uint8Array(binary.length);
            for (let i = 0; i < binary.length; i++) {
                bytes[i] = binary.charCodeAt(i);
            }
            const blob = new Blob([bytes], { type: data.mimeType || "application/pdf" });
            const blobUrl = URL.createObjectURL(blob);
            const a = document.createElement("a");
            a.href = blobUrl;
            a.download = data.fileName || this.fileName || "contract.pdf";
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(blobUrl);
        } catch (err) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Download Error",
                    message: "Could not download the file. Please try again.",
                    variant: "error"
                })
            );
        }
    }
}