import { LightningElement, track, api, wire } from 'lwc';
import pmc_brandingStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import { fireEvent, formatLabel } from "c/pmc_dh_utilityJs";
import { CurrentPageReference } from "lightning/navigation";
import { toastMessageHandler } from "c/pmc_dh_utilityJs";
import uploadDocuments from "@salesforce/apex/PMC_DH_CaseMgmtClass.saveTheChunkFile";

import pmc_quoteCheckoutFlow_proceed from "@salesforce/label/c.pmc_quoteCheckoutFlow_proceed";
import pmc_caseDetails_uploadADocument from "@salesforce/label/c.pmc_caseDetails_uploadADocument";
import pmc_caseDetails_uploadRequestedDocuments from "@salesforce/label/c.pmc_caseDetails_uploadRequestedDocuments";
import pmc_caseDetails_supportedFileTypes from "@salesforce/label/c.pmc_caseDetails_supportedFileTypes";
import pmc_caseDetails_uploadDocuments from "@salesforce/label/c.pmc_caseDetails_uploadDocuments";

/**
 * A custom LWC for uploading document on case details page.
 * @alias Pmc_dh_uploadCaseDocument
 * @extends LightningElement
 * @hideconstructor
 * @author Hemant
 * @example
 * <c-pmc_dh_upload-case-document></c-pmc_dh_upload-case-document>
 */

const RESPONSE_SUCCESS_MESSAGE = "000";

export default class Pmc_dh_uploadCaseDocument extends LightningElement {
    @api caseId;
    @track filesData = [];
    @track labels = {
        pmc_quoteCheckoutFlow_proceed,
        pmc_caseDetails_uploadADocument,
        pmc_caseDetails_uploadRequestedDocuments,
        pmc_caseDetails_supportedFileTypes,
        pmc_caseDetails_uploadDocuments
    };
    uploadIconUrl = `${pmc_brandingStaticResource}/icons/icon-upload.svg`;
    acceptedFormats = '.pdf, .docx, .xls, .xlsx, .png, .jpeg';
    isUploadDocumentModal = false;
    isProceedDisabled = true;
    isMouseOver = false;
    loadSpinner = false;
    isMultiple = true;
    error;

    /**
     * Calling pageref
     */
    @wire(CurrentPageReference) pageRef;

  /**
   * Lifecycle Hook
   */
    connectedCallback(){
        let acceptedFormats = this.acceptedFormats.replaceAll(".", "").toUpperCase();
        this.labels.pmc_caseDetails_supportedFileTypes = formatLabel(this.labels.pmc_caseDetails_supportedFileTypes, [acceptedFormats]);
    }

    /**
     * Upload Event dispatched from child
   * @function handleFileUpload
   * @param {Event} event 
     */
    handleFileUpload(event) {
        if (event.detail.filesData) {
            this.filesData = event.detail.filesData;
        }
        this.isProceedDisabled = false;

    }

    /**
     * Reset all the input fields of the new user form
   * @function clearForm
     */
    clearForm() {
        this.template.querySelector('c-pmc_dh_file-upload-element').resetFiles();
        this.filesData = [];
        this.isProceedDisabled = true;
    }

    /**
     * Saving the uploaded files
   * @function handleProceed
     */
    handleProceed() {
        this.filesData = this.filesData.map((file) => {
            let fileDetail = {
                strFileName: file.filename,
                strBase64Data: file.base64,
                parentId: this.caseId
            };
            return fileDetail;
        });
        this.loadSpinner = true;
        uploadDocuments({
            lstFileWrapper: this.filesData
        })
            .then((response) => {
        if (response && Object.keys(response).length) {
          if (JSON.parse(JSON.stringify(response)).strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(response)).strStatusMessage)
          }
                if (response.strStatusCode === RESPONSE_SUCCESS_MESSAGE) {
                    fireEvent(this.pageRef, "uploadedCaseDocument", this.filesData.length);
                    this.handleCloseUploadDocumentModal();
                }
        }
        this.loadSpinner = false;
            })
            .catch((error) => {
        toastMessageHandler();
                this.loadSpinner = false;
                this.error = error;
            });
    }

    /**
     * Modal open handler
   * @function openUploadDocumentModal
     */
    openUploadDocumentModal() {
        this.isUploadDocumentModal = !this.isUploadDocumentModal;
    }

    /**
     * Modal close handler
   * @function handleCloseUploadDocumentModal
     */
    handleCloseUploadDocumentModal() {
        this.isUploadDocumentModal = !this.isUploadDocumentModal;
        this.clearForm();
    }

    /**
     * Modal accessibility handler
   * @function handleIconKeyDown
   * @param {Event} event 
     */
    handleIconKeyDown(event) {
        if (event.keyCode === 13) {
            this.openUploadDocumentModal();
        }
    }

    /**
     * Mouse over Icon Handler
   * @function handleMouseEnter
     */
    handleMouseEnter() {
        this.isMouseOver = true;
    }

    /**
     * Mouse Leave Handler
   * @function handleMouseLeave
     */
    handleMouseLeave() {
        this.isMouseOver = false;
    }
}