import { LightningElement } from "lwc";

export default class MosaicDirectPlaceOrderLauncher extends LightningElement {
  isOpen = false;

  openModal = () => {
    this.isOpen = true;
  };

  handleModalClose = () => {
    this.isOpen = false;
  };
}