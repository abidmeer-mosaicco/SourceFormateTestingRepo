import { LightningElement, api } from 'lwc';

export default class Pmc_dh_breadcrumb extends LightningElement {
  icon = '>'
  @api crumbs = [];

  /**
   * Sends the id to parent
   * @function dispatchEventToParent
   * @param {event} event 
   */
  dispatchEventToParent(event) {
    if(event.target.dataset.customNavigation) {
      this.dispatchEvent(new CustomEvent('customnavigateev', {
        detail: {
          value: event.target.dataset.id
        }
      }))
    }
  }
}