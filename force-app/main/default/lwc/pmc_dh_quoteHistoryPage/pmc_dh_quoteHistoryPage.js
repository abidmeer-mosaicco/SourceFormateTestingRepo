import { LightningElement, track } from 'lwc';
import basePath from "@salesforce/community/basePath";

import pmc_quoteHistory_requestedQuotes from "@salesforce/label/c.pmc_quoteHistory_requestedQuotes";
import pmc_breadcrumb_homepage from "@salesforce/label/c.pmc_breadcrumb_homepage";

/**
 * A custom LWC to display quote history page.
 * @alias Pmc_dh_quoteHistoryPage
 * @extends LightningElement
 * @hideconstructor
 * @author Vanshika
 *
 * @example
 * <c-pmc_dh_quote-history-page></c-pmc_dh_quote-history-page>
 */

export default class Pmc_dh_quoteHistoryPage extends LightningElement {
  @track labels = {
    pmc_quoteHistory_requestedQuotes
  }

  crumbs = [
    { label: pmc_breadcrumb_homepage, url: `${basePath}/`, isActive: false },
    { label: pmc_quoteHistory_requestedQuotes, url: "", isActive: true },
  ];
}