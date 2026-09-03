import { LightningElement, track, wire } from "lwc";
import basePath from "@salesforce/community/basePath";
import { CurrentPageReference } from "lightning/navigation";
import pmc_brandingStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import getTimeline from "@salesforce/apex/PMC_DH_CaseMgmtClass.getTimeline";
// import getCaseDocument from "@salesforce/apex/PMC_DH_CaseMgmtClass.getCaseDocumentAndCommentRecords";
import isEligibleToUploadDoc from "@salesforce/apex/PMC_DH_CaseUtil.isEligibleToUploadDoc";

import { formatLabel, toastMessageHandler } from "c/pmc_dh_utilityJs";

import pmc_breadcrumb_homepage from "@salesforce/label/c.pmc_breadcrumb_homepage";
import pmc_breadcrumb_support from "@salesforce/label/c.pmc_breadcrumb_support";
import pmc_breadcrumb_caseDetail from "@salesforce/label/c.pmc_breadcrumb_caseDetail";
import pmc_caseDetails_msg from "@salesforce/label/c.pmc_caseDetails_msg";

const supportPageUrl = "/support";
const CASE = "Case";

/**
 * A custom LWC for displaying case details breadcrumbs
 * @alias Pmc_dh_caseDetail
 * @extends LightningElement
 * @hideconstructor
 * @author Manisha Singh
 *
 * @example
 * <c-pmc_dh_case-detail></c-pmc_dh_case-detail>
 */

export default class Pmc_dh_caseDetail extends LightningElement {
  caseStr = "";
  showReopenCaseOption = false;
  showUploadDocumentWidget = false;
  buttonUrl = `${pmc_brandingStaticResource}/icons/icon-reopen.svg`;

  @track labels = {
    pmc_breadcrumb_homepage,
    pmc_breadcrumb_support,
    pmc_breadcrumb_caseDetail,
    pmc_caseDetails_msg
  };

  @track crumbs = [
    {
      label: this.labels.pmc_breadcrumb_homepage,
      url: `${basePath}/`,
      isActive: false
    },
    {
      label: this.labels.pmc_breadcrumb_support,
      url: `${basePath}${supportPageUrl}`,
      isActive: false
    },
    { label: "", url: "", isActive: true }
  ];
  caseId;
  error;

  /**
   * Fetches caseId
   */
  @wire(CurrentPageReference)
  currentPageReference;
  // @wire(CurrentPageReference)
  // getStateParameters(currentPageReference) {
  //   if (currentPageReference && currentPageReference?.attributes?.objectApiName === CASE) {
  //     this.labels.pmc_breadcrumb_caseDetail = formatLabel(
  //       this.labels.pmc_breadcrumb_caseDetail,
  //       [currentPageReference.state?.caseNumber || ""]
  //     );
  //     this.caseStr = this.labels.pmc_breadcrumb_caseDetail;
  //     this.caseId = currentPageReference.attributes.recordId ? currentPageReference.attributes.recordId : '';
  //     this.reopenCase(this.caseId);
  //     this.fetchCaseDocument(this.caseId);
  //     this.crumbs = this.crumbs.map((e, i) => {
  //       if (i === 2) {
  //         e.label = this.caseStr;
  //       }
  //       return e;
  //     });
  //   }
  // }

  connectedCallback() {
    if (
      this.currentPageReference &&
      this.currentPageReference?.attributes?.objectApiName === CASE
    ) {
      this.labels.pmc_breadcrumb_caseDetail = formatLabel(
        this.labels.pmc_breadcrumb_caseDetail,
        [this.currentPageReference.state?.caseNumber || ""]
      );
      this.caseStr = this.labels.pmc_breadcrumb_caseDetail;
      this.caseId = this.currentPageReference.attributes.recordId
        ? this.currentPageReference.attributes.recordId
        : "";
      if (this.caseId) {
        this.reopenCase(this.caseId);
        this.fetchCaseDocument(this.caseId);
      }
      this.crumbs = this.crumbs.map((e, i) => {
        if (i === 2) {
          e.label = this.caseStr;
        }
        return e;
      });
    }
  }

  /**
   * Method to find if the closed case is eligible to be opened
   * @function reopenCase
   * @param {string} caseId
   */
  reopenCase(caseId) {
    getTimeline({ strCaseId: caseId })
      .then((res) => {
        // if (res && Object.keys(res).length) {
        //   if (JSON.parse(JSON.stringify(res)).strStatusMessage) {
        //     toastMessageHandler(
        //       JSON.parse(JSON.stringify(res)).strStatusMessage
        //     );
        //   }
          this.showReopenCaseOption = JSON.parse(JSON.stringify(res));
      //   }
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
      });
  }

  /**
   * Method to find if uploading document is allowed
   * @function fetchCaseDocument
   * @param {string} caseId
   */
  fetchCaseDocument(caseId) {
    isEligibleToUploadDoc({ caseId: caseId })
      .then((response) => {
        this.showUploadDocumentWidget = response;
        //if (response && Object.keys(response).length) {
          // if (
          //   JSON.parse(JSON.stringify(response)).statusCodeMessage
          //     ?.strStatusMessage
          // ) {
          //   toastMessageHandler(
          //     JSON.parse(JSON.stringify(response)).statusCodeMessage
          //       .strStatusMessage
          //   );
          // }
        //   if (response.boolEligibleToAddDocAndComments) {
        //     this.showUploadDocumentWidget = true;
        //   }
        // }
      })
      .catch((error) => {
        toastMessageHandler();
        this.error = error;
      });
  }
}