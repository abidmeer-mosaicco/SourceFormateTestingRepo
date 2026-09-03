import { LightningElement, track } from 'lwc';
import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import { formatDate, registerListener, unregisterAllListeners, toastMessageHandler } from "c/pmc_dh_utilityJs";

import pmc_caseDetails_commentPlaceholder from "@salesforce/label/c.pmc_caseDetails_commentPlaceholder";
import pmc_caseDetails_caseDocuments from "@salesforce/label/c.pmc_caseDetails_caseDocuments";
import pmc_caseDetails_caseComments from "@salesforce/label/c.pmc_caseDetails_caseComments";
import pmc_caseDetails_send from "@salesforce/label/c.pmc_caseDetails_send";
import pmc_caseDetails_docDateAdded from "@salesforce/label/c.pmc_caseDetails_docDateAdded";
import pmc_caseDetails_docName from "@salesforce/label/c.pmc_caseDetails_docName";
import pmc_caseMgmt_caseNumber from "@salesforce/label/c.pmc_caseMgmt_caseNumber";
import pmc_caseDetails_caseCommentRequired from "@salesforce/label/c.pmc_caseDetails_caseCommentRequired";
import pmc_caseDetails_caseCommentText from "@salesforce/label/c.pmc_caseDetails_caseCommentText";

import getCaseDocumentAndCommentRecords from "@salesforce/apex/PMC_DH_CaseMgmtClass.getCaseDocumentAndCommentRecords";
import createComment from "@salesforce/apex/PMC_DH_CaseMgmtClass.createComment";

/**
 * A custom LWC to display case documents and comments in case Details screen
 * @alias Pmc_dh_caseHistory
 * @extends LightningElement
 * @hideconstructor
 * @author Manisha Singh
 *
 * @example
 * <c-pmc_dh_case-history></c-pmc_dh_case-history>
 */

export default class Pmc_dh_caseHistory extends LightningElement {
  pathName = window.location.pathname;
  lastIndexValue = this.pathName.lastIndexOf('/case/');
  caseId = this.pathName.substring(this.lastIndexValue + 1).split('/')[1];

  @track labels = {
    pmc_caseDetails_caseDocuments,
    pmc_caseMgmt_caseNumber,
    pmc_caseDetails_docDateAdded,
    pmc_caseDetails_docName,
    pmc_caseDetails_caseComments,
    pmc_caseDetails_commentPlaceholder,
    pmc_caseDetails_send,
    pmc_caseDetails_caseCommentRequired,
    pmc_caseDetails_caseCommentText
  }
  @track iconUrlObj = {
    download: `${PMC_BrandingAssetsStaticResource}/icons/icon-download.svg`
  }

  newComment = "";
  canAddComment = false;
  @track caseDocuments = [];
  @track caseComments = [];
  isSpinner = false;

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    this.getCaseDocumentAndCommentRecordsHandler();
    registerListener("uploadedCaseDocument", this.displayUploadedDocuments, this);
  }

  /**
   * Get Case documents and Comments
   * @function getCaseDocumentAndCommentRecordsHandler
   */
  getCaseDocumentAndCommentRecordsHandler() {
    this.isSpinner = true;
    getCaseDocumentAndCommentRecords({
      caseId: this.caseId
    }).then((response) => {
      if (response && Object.keys(response).length) {
        if (JSON.parse(JSON.stringify(response)).statusCodeMessage?.strStatusMessage) {
          toastMessageHandler(JSON.parse(JSON.stringify(response)).statusCodeMessage.strStatusMessage)
        }
        let data = JSON.parse(JSON.stringify(response));
        if (data) {
          this.canAddComment = data.boolEligibleToAddDocAndComments;
          this.caseDocuments = this.formatDocs(data.caseDocList);
          this.caseComments = data.caseCommentList;
        }
        this.scrollToBottom();
      }
      this.isSpinner = false;
    }).catch(() => {
      toastMessageHandler();
      this.isSpinner = false;
    })
  }

  /**
   * Formats the date added for case documents
   * @function formatDocs
   * @param {Array} data 
   */
  formatDocs(data) {
    return data.map(item => ({
      ...item,
      strDateAdded: formatDate(item.strDateAdded.split('T')[0]),
    }));
  }

  /** 
   * Submit the comment value entered by user 
   * @function handleDataChange
   * @param {event} event
   */
  handleDataChange(event) {
    if (event.target && event.detail.value.trim() !== "undefined") {
      this.newComment = event.detail.value.trim();
      if (!!event.detail.value && event.target.dataset.id === 'strCaseComment') {
        this.template.querySelector('[data-id="strCaseComment"]').errorMsg = [''];
      }
    }
  }

  /** 
   * Submit the comment value entered by user 
   * @function handleKeyDown
   * @param {event} event
   */
  handleKeyDown(event) {
    if (!!this.newComment && event.keyCode === 13) {
      event.preventDefault();
      this.createCommentHandler();
    }
  }

  /**
   * On Send button click event handler
   * @function handleComment
   */
  handleComment() {
    if (this.newComment) {
      this.createCommentHandler();
    }
  }

  /**
   * Submit a comment by user
   * @function createCommentHandler
   */
  createCommentHandler() {
    this.isSpinner = true;
    createComment({
      caseId: this.caseId, strComment: this.newComment
    }).then((responseString) => {
      if (responseString && Object.keys(responseString).length) {
        if (JSON.parse(JSON.stringify(responseString)).strStatusMessage) {
          toastMessageHandler(JSON.parse(JSON.stringify(responseString)).strStatusMessage)
        }
        const response = JSON.parse(JSON.stringify(responseString));
        if (response.strStatusCode === '000') {
          this.newComment = '';
          this.getCaseDocumentAndCommentRecordsHandler();
        }
      }
      this.isSpinner = false;
    }).catch(() => {
      toastMessageHandler();
      this.isSpinner = false;
    })
  }

  /**
   * Scroll to bottom
   * @function scrollToBottom
   */
  scrollToBottom() {
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setTimeout(() => {
      let containerChoosen = this.template.querySelector('.message-container');
      if (containerChoosen) {
        containerChoosen.scrollTop = containerChoosen.scrollHeight;
      }
    });
  }

  /**
   * Calls the document method again if a new document is uploaded
   * @function displayUploadedDocuments
   * @param {number} newUpload 
   */
  displayUploadedDocuments(newUpload) {
    if (newUpload) {
      this.getCaseDocumentAndCommentRecordsHandler();
    }
  }

  /**
   * Lifecycle Hook
   */
  disconnectedCallback() {
    unregisterAllListeners(this);
  }
}