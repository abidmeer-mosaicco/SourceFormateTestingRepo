import { LightningElement, api, wire } from "lwc";
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from "lightning/messageService";
import LIST_TARGET_CHANNEL from "@salesforce/messageChannel/MosaicListTargetChannel__c";

export default class MosaicDirectContainer extends LightningElement {
  @api pageSize = 50;

  // ---- PROPS configuráveis no Builder (UI "Orders" = ShipmentItem)
  @api orderManualFieldApiNames;
  @api orderManualFieldLabelNames;
  @api orderAccountNamePath; // ex.: PMC_CPQ_OrderProduct__r.Order.Account.Name
  @api orderSapNumberPath; // ex.: PMC_CPQ_OrderProduct__r.Order.Account.PMC_SS_SAPCustomerNumber__c
  @api orderDateFilterFieldName;
  @api orderEndDateFilterFieldName;
  @api orderBaseWhere;

  // ---- PROPS (Quotes)
  @api quoteManualFieldApiNames;
  @api quoteManualFieldLabelNames;
  @api quoteAccountNamePath; // opcional para Quote
  @api quoteSapNumberPath; // opcional para Quote
  @api quoteDateFilterFieldName;
  @api quoteEndDateFilterFieldName;
  @api quoteBaseWhere;

  // Aceita "Order" ou "ShipmentItem" para abrir na aba certa
  @api defaultObject = "Order";

  @wire(MessageContext) messageContext;

  showOrders = true; // mostra a grade ShipmentItem
  showQuotes = false;
  _sub;

  connectedCallback() {
    this._applyTarget(this.defaultObject);
    this._sub = subscribe(this.messageContext, LIST_TARGET_CHANNEL, (msg) => this.handleTarget(msg), { scope: APPLICATION_SCOPE });
  }

  disconnectedCallback() {
    if (this._sub) unsubscribe(this._sub);
    this._sub = null;
  }

  handleTarget(message) {
    const obj = (message && message.objectApiName) || "";
    if (!obj) return;
    this._applyTarget(obj);
  }

  _applyTarget(obj) {
    const low = (obj || "").toLowerCase();
    // "Orders" no UI => ShipmentItem por baixo
    this.showOrders = low === "order" || low === "shipmentitem";
    this.showQuotes = low === "sbqq__quote__c";
  }
}