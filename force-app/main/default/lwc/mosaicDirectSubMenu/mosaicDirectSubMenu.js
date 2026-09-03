import { LightningElement, wire } from "lwc";
import { publish, MessageContext } from "lightning/messageService";
import LIST_TARGET_CHANNEL from "@salesforce/messageChannel/MosaicListTargetChannel__c";

export default class MosaicDirectSubMenu extends LightningElement {
  @wire(MessageContext) messageContext;

  handleOrders() {
    publish(this.messageContext, LIST_TARGET_CHANNEL, { objectApiName: "ShipmentItem" });
  }
  handleQuotes() {
    publish(this.messageContext, LIST_TARGET_CHANNEL, { objectApiName: "SBQQ__Quote__c" });
  }
}