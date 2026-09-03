import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import sresource from "@salesforce/resourceUrl/miskiMayoPDFViewer";
import { loadStyle } from "lightning/platformResourceLoader";
import { NavigationMixin } from 'lightning/navigation';

export default class MiskiMayoPDFViewerComponent extends NavigationMixin(LightningElement) {
  @track myopenModal = false;
  
  firstZoomIn = false;
  zoomLevel = 100;
  @api pdfUrl;
  
  @track dynamicWidth = 'width:30%';
  
  @api get openModal() {
    return this.myopenModal;
  }

  set openModal(value) {
    this.myopenModal = value;
    if (this.myopenModal === false) {
      this.dispatchEvent(
        new CustomEvent("close", {
          composed: true,
          bubbles: true,
          cancelable: true,
          detail: {}
        })
      );
    }
  }

  @track pdfData;
  @track showLoadingSpinner = false;
  @api showConsoleLogs = false;
  viewerUrlNew = true;
  @api modalTitle;
  hasInitialized = false; 
  currentWidth = 30;

  renderedCallback() {
    if (this.hasInitialized) {
      return;
    }
    this.hasInitialized = true;

    loadStyle(this, sresource + "/custom1.css");
  }

  get modalClass() {
    return this.openModal
      ? "slds-modal slds-modal_large slds-fade-in-open"
      : "slds-modal slds-modal_large";
  }

  onLoad() {
    let myiframe = this.template.querySelector("iframe");
    if (myiframe) {
      myiframe.contentWindow.postMessage(this.pdfUrl, "*");
    }
  }

  closeModal() {
    this.openModal = false;
    this.showLoadingSpinner = false;
  }

  showNotification(t, m, v) {
    if (this.showConsoleLogs) {
      console.log({
        log: "showNotification",
        title: t,
        message: m,
        variant: v
      });
    }

    const evt = new ShowToastEvent({
      title: t,
      message: m,
      variant: v
    });
    this.dispatchEvent(evt);
  }

  openModalNew() 
  {
    this.myopenModal = true;

    setTimeout(() => {
      window.addEventListener('click', this.setInitialStyles.bind(this));
      window.addEventListener('load', this.setInitialStyles.bind(this));
      window.addEventListener('resize', this.setInitialStyles.bind(this));
      window.addEventListener('DOMContentLoaded', this.setInitialStyles.bind(this));
    }, 3000);

    const wrapperDiv = this.template.querySelector('.wrapper');

    if (wrapperDiv && !this.widthInitialized)
    {
        wrapperDiv.style.width = this.currentWidth + '%';
        wrapperDiv.style.height = '100%';
        wrapperDiv.style.position = 'relative';
        this.widthInitialized = true;
    }

  }

    setInitialStyles() {
      const targetElement = this.template.querySelector('.wrapper');  
        
      if (targetElement){
          targetElement.style.height = '100%';
          targetElement.style.position = 'absolute';
          targetElement.style.width = this.currentWidth + '%';

          targetElement.style.left = '50%';
          targetElement.style.transform = 'translateX(-50%)';
      }
    }

    handleZoomOut() {
        const targetElement = this.template.querySelector('.wrapper');
        if (targetElement)
        {  
            if (this.currentWidth > 75)
            {
                this.currentWidth -= (5*5);
                targetElement.style.width = this.currentWidth + '%';
                targetElement.style.height= '69vh';
                this.firstZoomIn = true;
                this.myopenModal = true;
            }
            else
            {
                this.currentWidth -= 5;
                targetElement.style.width = this.currentWidth + '%';
                targetElement.style.height= '69vh';
                this.firstZoomIn = true;
                this.myopenModal = true;
            }
        }
  }

    handleZoomIn() {
      const targetElement = this.template.querySelector('.wrapper');
      if (targetElement)
      {
        if (this.currentWidth < 80)
        {
          this.currentWidth += 5;
          targetElement.style.width = this.currentWidth + '%';
          targetElement.style.height= '69vh';
          targetElement.style.height= '69vh';
        }
      }
  }

  printPDF() {
    const url = this.pdfUrl;
    this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: { url: url }
    });
  }

}