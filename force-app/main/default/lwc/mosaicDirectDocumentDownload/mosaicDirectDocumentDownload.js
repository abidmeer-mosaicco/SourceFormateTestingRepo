/* eslint-disable @lwc/lwc/no-unknown-wire-adapters */
/* eslint-disable @lwc/lwc/no-api-reassignments */
/* eslint-disable @lwc/lwc/valid-api */
import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getInvoiceNumber from "@salesforce/apex/MosaicDirectDocumentService.getInvoiceNumber";
import downloadInvoice from "@salesforce/apex/MosaicDirectDocumentService.downloadInvoice";
import getOrderIdFromOrderItem from "@salesforce/apex/MosaicDirectDocumentService.getOrderIdFromOrderItem";
import getDocumentInfo from "@salesforce/apex/MosaicDirectDocumentService.getDocumentInfo";
import downloadBOL from "@salesforce/apex/MosaicDirectDocumentService.downloadBOL";
import downloadCOA from "@salesforce/apex/MosaicDirectDocumentService.downloadCOA";
import downloadAllDocuments from "@salesforce/apex/MosaicDirectDocumentService.downloadAllDocuments";
import checkCOARestriction from "@salesforce/apex/MosaicDirectDocumentService.checkCOARestriction";

// Document type constants
const DOCUMENT_TYPES = {
  INVOICE: "invoice",
  BOL: "bol",
  COA: "coa",
  DOWNLOAD_ALL: "download_all"
};

// Separate HTML files are functional templates for parent components to use in datatables
// invoiceButton.html, bolButton.html, coaButton.html, downloadAllButton.html

export default class MosaicDirectDocumentDownload extends LightningElement {
  // Internal properties for data binding compatibility
  @api OrderId;
  @api ShipmentItemId;
  @api invoiceFounded = false;
  @api bolFounded = false;
  @api coaFounded = false;
  @track restrictionCheck = { isRestricted: false, hasChecked: false };
  boolRunOnce = false;

  // API properties with getters/setters for case-insensitive compatibility
  @api
  get orderId() {
    return this.OrderId;
  }
  set orderId(value) {
    this.OrderId = value;
  }

  @api
  get shipmentItemId() {
    return this.ShipmentItemId;
  }
  set shipmentItemId(value) {
    this.ShipmentItemId = value;
  }

  @api documentType = DOCUMENT_TYPES.INVOICE; // Type of document for this button instance

  async connectedCallback() {
    console.log("Component connected. orderId:", this.orderId, "shipmentItemId:", this.shipmentItemId, { invoiceFounded: this.invoiceFounded, bolFounded: this.bolFounded, coaFounded: this.coaFounded });
    if (this.boolRunOnce) return;
    this.boolRunOnce = true;
    await this._checkCOARestriction();
  }

  // Internal state
  isLoading = false;

  // Getters for template conditionals
  get isInvoiceButton() {
    return this.invoiceFounded && this.documentType === DOCUMENT_TYPES.INVOICE;
  }

  get isBOLButton() {
    return this.bolFounded && this.documentType === DOCUMENT_TYPES.BOL;
  }

  get isCOAButton() {
    return this.coaFounded && this.documentType === DOCUMENT_TYPES.COA && !this.isCOARestricted;
  }

  get isCOARestricted() {
    return this.restrictionCheck?.isRestricted;
  }

  get isDownloadAllButton() {
    return (this.invoiceFounded || this.bolFounded || this.coaFounded) && this.documentType === DOCUMENT_TYPES.DOWNLOAD_ALL;
  }

  // Icon getters for each button type
  get invoiceIconName() {
    return this.isLoading ? "utility:spinner" : "utility:preview";
  }

  get bolIconName() {
    return this.isLoading ? "utility:spinner" : "utility:preview";
  }

  get coaIconName() {
    return this.isLoading ? "utility:spinner" : "utility:preview";
  }

  get downloadAllIconName() {
    return this.isLoading ? "utility:spinner" : "utility:download";
  }

  // Specific click handlers for each button type
  async handleInvoiceClick() {
    await this._processDocumentRequest(DOCUMENT_TYPES.INVOICE);
  }

  async handleBOLClick() {
    await this._processDocumentRequest(DOCUMENT_TYPES.BOL);
  }

  async handleCOAClick() {
    await this._processDocumentRequest(DOCUMENT_TYPES.COA);
  }

  async handleDownloadAllClick() {
    await this._processDocumentRequest(DOCUMENT_TYPES.DOWNLOAD_ALL);
  }

  /**
   * Process document request and dispatch events
   */
  async _processDocumentRequest(documentType) {
    // Validate required IDs
    if (!this.orderId && !this.shipmentItemId) {
      this._dispatchDocumentEvent("documentdownloaderror", {
        documentType,
        orderId: this.orderId,
        shipmentItemId: this.shipmentItemId,
        error: "Record ID is required"
      });
      return;
    }

    // Dispatch start event
    this._dispatchDocumentEvent("documentdownloadstart", {
      documentType,
      orderId: this.orderId,
      shipmentItemId: this.shipmentItemId
    });

    try {
      this.isLoading = true;

      switch (documentType) {
        case DOCUMENT_TYPES.INVOICE:
          await this._handleInvoiceView();
          break;
        case DOCUMENT_TYPES.BOL:
          await this._handleBOLView();
          break;
        case DOCUMENT_TYPES.COA:
          await this._handleCOAView();
          break;
        case DOCUMENT_TYPES.DOWNLOAD_ALL:
          await this._handleDownloadAll();
          break;
        default:
          throw new Error(`Unsupported document type: ${documentType}`);
      }

      // Dispatch success event
      this._dispatchDocumentEvent("documentdownloadsuccess", {
        documentType,
        orderId: this.orderId,
        shipmentItemId: this.shipmentItemId
      });

    } catch (error) {
      // Dispatch error event
      this._dispatchDocumentEvent("documentdownloaderror", {
        documentType,
        orderId: this.orderId,
        shipmentItemId: this.shipmentItemId,
        error: error.message
      });

      this._handleError(error, documentType);
    } finally {
      this.isLoading = false;

      // Dispatch complete event
      this._dispatchDocumentEvent("documentdownloadcomplete", {
        documentType,
        orderId: this.orderId,
        shipmentItemId: this.shipmentItemId
      });
    }
  }

  /**
   * Dispatch custom events with bubble
   */
  _dispatchDocumentEvent(eventName, detail) {
    this.dispatchEvent(
      new CustomEvent(eventName, {
        detail,
        bubbles: true,
        composed: true
      })
    );
  }

  /**
   *  Handle Invoice document view - open in new tab
   */
  async _handleInvoiceView() {
    console.log("=== INVOICE VIEW STARTED ===");
    console.log("Component properties:", {
      orderId: this.orderId,
      shipmentItemId: this.shipmentItemId,
      documentType: this.documentType
    });

    if (!this.orderId) {
      console.log("INVOICE ERROR: Order ID is required");
      this._dispatchDocumentEvent("documentdownloaderror", {
        documentType: DOCUMENT_TYPES.INVOICE,
        orderId: this.orderId,
        shipmentItemId: this.shipmentItemId,
        error: "Order ID is required to view Invoice"
      });
      return;
    }

    // Validate Order ID format
    if (!this.orderId.startsWith("801")) {
      console.log("INVOICE ERROR: Invalid Order ID format");
      this._dispatchDocumentEvent("documentdownloaderror", {
        documentType: DOCUMENT_TYPES.INVOICE,
        orderId: this.orderId,
        shipmentItemId: this.shipmentItemId,
        error: 'Invalid Order ID format. Must start with "801"'
      });
      return;
    }

    // Get Invoice Number from Order
    console.log("INVOICE: Getting invoice number...");
    const invoiceResult = await getInvoiceNumber({ shipmentItemId: this.shipmentItemId });
    console.log("INVOICE: Invoice number result:", invoiceResult);

    if (!invoiceResult.success) {
      const errorMessage = invoiceResult.message || "Error retrieving invoice number";
      console.log("INVOICE ERROR: Failed to get invoice number:", errorMessage);
      this._dispatchDocumentEvent("documentdownloaderror", {
        documentType: DOCUMENT_TYPES.INVOICE,
        orderId: this.orderId,
        shipmentItemId: this.shipmentItemId,
        error: errorMessage
      });
      return;
    }

    const invoiceNumber = invoiceResult.invoiceNumber;
    const orderNumber = invoiceResult.orderNumber;
    console.log("INVOICE: Invoice number:", invoiceNumber);
    console.log("INVOICE: Order number:", orderNumber);

    // Validate invoice number
    if (!invoiceNumber || invoiceNumber.trim() === "") {
      console.log("INVOICE ERROR: No invoice number returned");
      this._dispatchDocumentEvent("documentdownloaderror", {
        documentType: DOCUMENT_TYPES.INVOICE,
        orderId: this.orderId,
        shipmentItemId: this.shipmentItemId,
        error: "Invoice number not found for this order"
      });
      return;
    }

    // Download Invoice PDF from SAP
    console.log("INVOICE: Downloading PDF from SAP...");
    const downloadResult = await downloadInvoice({ strBillingDocNumber: invoiceNumber });
    console.log("INVOICE: Download result:", downloadResult);

    if (downloadResult.success) {
      console.log("INVOICE: Download successful, opening PDF...");

      // Validate PDF data
      if (!downloadResult.pdfData || downloadResult.pdfData.trim() === "") {
        console.log("INVOICE ERROR: No PDF data in download result");
        this._dispatchDocumentEvent("documentdownloaderror", {
          documentType: DOCUMENT_TYPES.INVOICE,
          orderId: this.orderId,
          shipmentItemId: this.shipmentItemId,
          error: "Document not found on server"
        });
        return;
      }

      // Generate filename: {OrderNumber}_Invoice.pdf
      let fileName;
      if (orderNumber && orderNumber.trim() !== "") {
        fileName = `${orderNumber.trim()}_Invoice.pdf`;
      } else {
        fileName = `Invoice_${invoiceNumber}.pdf`;
      }

      console.log("INVOICE: Generated filename:", fileName);
      console.log("INVOICE: PDF data length:", downloadResult.pdfData.length);

      // Open PDF in new tab for viewing
      this._openPdfInNewTab(downloadResult.pdfData, fileName);

      console.log("=== INVOICE VIEW COMPLETED SUCCESSFULLY ===");
    } else {
      const errorMessage = downloadResult.message || "Error opening invoice";
      console.log("INVOICE ERROR: Download failed:", errorMessage);

      this._dispatchDocumentEvent("documentdownloaderror", {
        documentType: DOCUMENT_TYPES.INVOICE,
        orderId: this.orderId,
        shipmentItemId: this.shipmentItemId,
        error: errorMessage
      });
    }
  }

  /**
   *  Handle BOL document view - open in new tab
   */
  async _handleBOLView() {
    console.log("=== BOL VIEW STARTED ===");
    console.log("BOL - shipmentItemId:", this.shipmentItemId);
    console.log("BOL - Document Type:", this.documentType);

    if (!this.shipmentItemId) {
      console.log("BOL ERROR: ShipmentItem ID is required");
      this._dispatchDocumentEvent("documentdownloaderror", {
        documentType: DOCUMENT_TYPES.BOL,
        orderId: this.orderId,
        shipmentItemId: this.shipmentItemId,
        error: "ShipmentItem ID is required to view BOL"
      });
      return;
    }

    try {
      console.log("BOL: Getting document info...");
      // Get document info from ShipmentItem
      const docInfo = await getDocumentInfo({ shipmentItemId: this.shipmentItemId });
      console.log("BOL: Document info result:", docInfo);

      if (!docInfo.success) {
        console.log("BOL ERROR: Failed to get document info:", docInfo.message);
        this._dispatchDocumentEvent("documentdownloaderror", {
          documentType: DOCUMENT_TYPES.BOL,
          orderId: this.orderId,
          shipmentItemId: this.shipmentItemId,
          error: docInfo.message
        });
        return;
      }

      console.log("BOL: Downloading PDF from SAP...");
      // Download BOL PDF from SAP
      const downloadResult = await downloadBOL({ strBillingDocNumber: docInfo.deliveryNumber });
      console.log("BOL: Download result:", downloadResult);

      if (downloadResult.success && downloadResult.pdfData) {
        // Generate filename: BOL_{DeliveryNumber}.pdf
        const fileName = `BOL_${docInfo.deliveryNumber}.pdf`;
        console.log("BOL: Opening PDF in new tab:", fileName);

        // Open PDF in new tab for viewing
        this._openPdfInNewTab(downloadResult.pdfData, fileName);

        console.log("=== BOL VIEW COMPLETED SUCCESSFULLY ===");
      } else {
        const errorMessage = downloadResult.message || "Error opening BOL";
        console.log("BOL ERROR: Download failed:", errorMessage);
        this._dispatchDocumentEvent("documentdownloaderror", {
          documentType: DOCUMENT_TYPES.BOL,
          orderId: this.orderId,
          shipmentItemId: this.shipmentItemId,
          error: errorMessage
        });
      }
    } catch (error) {
      console.log("BOL ERROR: Exception occurred:", error);
      this._dispatchDocumentEvent("documentdownloaderror", {
        documentType: DOCUMENT_TYPES.BOL,
        orderId: this.orderId,
        shipmentItemId: this.shipmentItemId,
        error: "Exception during BOL viewing: " + error.message
      });
    }
  }

  /**
   *  Handle COA document view - open in new tab
   */
  async _handleCOAView() {
    if (!this.shipmentItemId) {
      this._dispatchDocumentEvent("documentdownloaderror", {
        documentType: DOCUMENT_TYPES.COA,
        orderId: this.orderId,
        shipmentItemId: this.shipmentItemId,
        error: "ShipmentItem ID is required to view COA"
      });
      return;
    }

    // Check if COA is restricted for Sulfuric Acid + Rail
    // const restrictionCheck = await this._checkCOARestriction();
    // if (restrictionCheck.isRestricted) {
    //   this._dispatchDocumentEvent("documentdownloaderror", {
    //     documentType: DOCUMENT_TYPES.COA,
    //     orderId: this.orderId,
    //     shipmentItemId: this.shipmentItemId,
    //     error: restrictionCheck.message
    //   });
    //   return;
    // }

    // Get document info from ShipmentItem
    const docInfo = await getDocumentInfo({ shipmentItemId: this.shipmentItemId });

    if (!docInfo.success) {
      this._dispatchDocumentEvent("documentdownloaderror", {
        documentType: DOCUMENT_TYPES.COA,
        orderId: this.orderId,
        shipmentItemId: this.shipmentItemId,
        error: docInfo.message
      });
      return;
    }

    // Download COA PDF from SAP
    const downloadResult = await downloadCOA({
      strBillingDocNumber: docInfo.deliveryNumber,
      strItemNumber: docInfo.itemNumber
    });

    if (downloadResult.success && downloadResult.pdfData) {
      // Generate filename: {OrderNumber}_{OrderItemNumber}_COA.pdf
      let fileName;
      if (docInfo.orderNumber && docInfo.orderItemNumber) {
        fileName = `${docInfo.orderNumber}_${docInfo.orderItemNumber}_COA.pdf`;
      } else {
        // Fallback to old format if orderNumber or orderItemNumber not available
        fileName = `COA_${docInfo.deliveryNumber}_${docInfo.itemNumber}.pdf`;
      }

      // Open PDF in new tab for viewing
      this._openPdfInNewTab(downloadResult.pdfData, fileName);
    } else {
      const errorMessage = downloadResult.message || "Error opening COA";
      this._dispatchDocumentEvent("documentdownloaderror", {
        documentType: DOCUMENT_TYPES.COA,
        orderId: this.orderId,
        shipmentItemId: this.shipmentItemId,
        error: errorMessage
      });
    }
  }

  /**
   *  Handle Download All documents
   */
  async _handleDownloadAll() {
    // Get Order Number first for filename generation
    let orderNumber = "Unknown";
    if (this.orderId) {
      try {
        const invoiceResult = await getInvoiceNumber({ shipmentItemId: this.shipmentItemId });
        if (invoiceResult.success && invoiceResult.orderNumber) {
          orderNumber = invoiceResult.orderNumber.trim();
        }
      } catch (error) {
        // Use default if can't get order number
      }
    }

    // Download documents individually to avoid uncommitted work issues
    let downloadedCount = 0;
    const totalDocuments = 3;
    const errors = [];

    // 1. Download Invoice
    if (this.orderId && this.invoiceFounded) {
      try {
        const invoiceNumberResult = await getInvoiceNumber({ shipmentItemId: this.shipmentItemId });
        if (invoiceNumberResult.success) {
          const invoiceDownloadResult = await downloadInvoice({ strBillingDocNumber: invoiceNumberResult.invoiceNumber });
          if (invoiceDownloadResult.success && invoiceDownloadResult.pdfData) {
            const fileName = `${orderNumber}_Invoice.pdf`;
            this._downloadPdfFile(invoiceDownloadResult.pdfData, fileName);
            downloadedCount++;
          } else {
            const errorMsg = "Invoice: " + (invoiceDownloadResult.message || "Download failed");
            errors.push(errorMsg);
            this._dispatchDocumentEvent("documentdownloaderror", {
              documentType: DOCUMENT_TYPES.DOWNLOAD_ALL,
              orderId: this.orderId,
              shipmentItemId: this.shipmentItemId,
              error: errorMsg
            });
          }
        } else {
          const errorMsg = "Invoice: " + (invoiceNumberResult.message || "Could not get invoice number");
          errors.push(errorMsg);
          this._dispatchDocumentEvent("documentdownloaderror", {
            documentType: DOCUMENT_TYPES.DOWNLOAD_ALL,
            orderId: this.orderId,
            shipmentItemId: this.shipmentItemId,
            error: errorMsg
          });
        }
      } catch (error) {
        const errorMsg = "Invoice: " + error.message;
        errors.push(errorMsg);
        this._dispatchDocumentEvent("documentdownloaderror", {
          documentType: DOCUMENT_TYPES.DOWNLOAD_ALL,
          orderId: this.orderId,
          shipmentItemId: this.shipmentItemId,
          error: errorMsg
        });
      }
    }

    // 2. Download BOL
    if (this.shipmentItemId && this.bolFounded) {
      try {
        const docInfo = await getDocumentInfo({ shipmentItemId: this.shipmentItemId });
        if (docInfo.success) {
          const bolDownloadResult = await downloadBOL({ strBillingDocNumber: docInfo.deliveryNumber });
          if (bolDownloadResult.success && bolDownloadResult.pdfData) {
            const fileName = `${orderNumber}_BOL.pdf`;
            this._downloadPdfFile(bolDownloadResult.pdfData, fileName);
            downloadedCount++;
          } else {
            const errorMsg = "BOL: " + (bolDownloadResult.message || "Download failed");
            errors.push(errorMsg);
            this._dispatchDocumentEvent("documentdownloaderror", {
              documentType: DOCUMENT_TYPES.DOWNLOAD_ALL,
              orderId: this.orderId,
              shipmentItemId: this.shipmentItemId,
              error: errorMsg
            });
          }
        } else {
          const errorMsg = "BOL: " + (docInfo.message || "Could not get document info");
          errors.push(errorMsg);
          this._dispatchDocumentEvent("documentdownloaderror", {
            documentType: DOCUMENT_TYPES.DOWNLOAD_ALL,
            orderId: this.orderId,
            shipmentItemId: this.shipmentItemId,
            error: errorMsg
          });
        }
      } catch (error) {
        const errorMsg = "BOL: " + error.message;
        errors.push(errorMsg);
        this._dispatchDocumentEvent("documentdownloaderror", {
          documentType: DOCUMENT_TYPES.DOWNLOAD_ALL,
          orderId: this.orderId,
          shipmentItemId: this.shipmentItemId,
          error: errorMsg
        });
      }
    }

    // 3. Download COA
    if (this.shipmentItemId && this.coaFounded) {
      try {
        // Check COA restriction first
        // const restrictionCheck = await this._checkCOARestriction();
        if (this.restrictionCheck.isRestricted) {
          // const errorMsg = "COA: " + restrictionCheck.message;
          // errors.push(errorMsg);
          // this._dispatchDocumentEvent("documentdownloaderror", {
          //   documentType: DOCUMENT_TYPES.DOWNLOAD_ALL,
          //   orderId: this.orderId,
          //   shipmentItemId: this.shipmentItemId,
          //   error: errorMsg
          // });
        } else {
          const docInfo = await getDocumentInfo({ shipmentItemId: this.shipmentItemId });
          if (docInfo.success) {
            const coaDownloadResult = await downloadCOA({
              strBillingDocNumber: docInfo.deliveryNumber,
              strItemNumber: docInfo.itemNumber
            });
            if (coaDownloadResult.success && coaDownloadResult.pdfData) {
              // Generate filename: {OrderNumber}_{OrderItemNumber}_COA.pdf
              let fileName;
              if (docInfo.orderNumber && docInfo.orderItemNumber) {
                fileName = `${docInfo.orderNumber}_${docInfo.orderItemNumber}_COA.pdf`;
              } else {
                // Fallback to old format
                fileName = `${orderNumber}_COA.pdf`;
              }
              this._downloadPdfFile(coaDownloadResult.pdfData, fileName);
              downloadedCount++;
            } else {
              const errorMsg = "COA: " + (coaDownloadResult.message || "Download failed");
              errors.push(errorMsg);
              this._dispatchDocumentEvent("documentdownloaderror", {
                documentType: DOCUMENT_TYPES.DOWNLOAD_ALL,
                orderId: this.orderId,
                shipmentItemId: this.shipmentItemId,
                error: errorMsg
              });
            }
          } else {
            const errorMsg = "COA: " + (docInfo.message || "Could not get document info");
            errors.push(errorMsg);
            this._dispatchDocumentEvent("documentdownloaderror", {
              documentType: DOCUMENT_TYPES.DOWNLOAD_ALL,
              orderId: this.orderId,
              shipmentItemId: this.shipmentItemId,
              error: errorMsg
            });
          }
        }
      } catch (error) {
        const errorMsg = "COA: " + error.message;
        errors.push(errorMsg);
        this._dispatchDocumentEvent("documentdownloaderror", {
          documentType: DOCUMENT_TYPES.DOWNLOAD_ALL,
          orderId: this.orderId,
          shipmentItemId: this.shipmentItemId,
          error: errorMsg
        });
      }
    }

    // Show results
    if (downloadedCount > 0) {
      let message = `Download All completed! ${downloadedCount} of ${totalDocuments} documents downloaded.`;
      if (errors.length > 0) {
        message += ` Errors: ${errors.join(", ")}`;
      }
      // Toast removed as per user request
      // this._showSuccess('Success', message);
    } else {
      const errorMessage = errors.length > 0 ? errors.join(", ") : "No documents were downloaded successfully.";
      // Send error event to parent
      this._dispatchDocumentEvent("documentdownloaderror", {
        documentType: DOCUMENT_TYPES.DOWNLOAD_ALL,
        orderId: this.orderId,
        shipmentItemId: this.shipmentItemId,
        error: errorMessage
      });
      // Keep local toast for now (user can remove if needed)
      this._showError("Error", errorMessage);
    }
  }

  /**
   *  Check if COA is restricted for Sulfuric Acid + Rail combination
   */
  async _checkCOARestriction() {
    if (this.restrictionCheck?.hasChecked) return;

    this.restrictionCheck = { isRestricted: false, hasChecked: true };

    try {
      if (!this.shipmentItemId) return;

      const restrictionResult = await checkCOARestriction({ shipmentItemId: this.shipmentItemId });

      // console.log({ restrictionResult });

      if (restrictionResult.isRestricted) {
        this.restrictionCheck = {
          isRestricted: true,
          hasChecked: true,
          message: "The product is Sulfuric Acid and the Transportation Mode is Rail, the COA is not available for download."
        };
      }
    } catch (error) {
      console.log({ error });
    }
  }

  /**
   *  Get Order ID from record based on object type
   */
  async _getOrderId() {
    // If orderId is directly available, use it
    if (this.orderId) {
      return this.orderId;
    }

    if (this.objectApiName === "Order") {
      return this.recordId;
    } else if (this.objectApiName === "ShipmentItem" || this.recordId.startsWith("0ob")) {
      // Get Order ID from ShipmentItem via Apex
      const orderId = await getOrderIdFromOrderItem({ orderItemId: this.recordId });

      if (!orderId) {
        this._showError("Error", "Unable to determine the Order ID from the ShipmentItem");
        return null;
      }
      return orderId;
    } else {
      // Assume it's an OrderItem ID
      const orderId = await getOrderIdFromOrderItem({ orderItemId: this.recordId });

      if (!orderId) {
        this._showError("Error", "Unable to determine the Order ID");
        return null;
      }
      return orderId;
    }
  }

  /**
   * @description Open PDF in new browser tab (Salesforce Lightning compatible)
   * @param {String} base64Data - Base64 encoded PDF data
   * @param {String} filename - Filename for the PDF
   */
  _openPdfInNewTab(base64Data, filename) {
    console.log("=== PDF VIEW STARTED ===");
    console.log("Filename:", filename);
    console.log("Base64 data length:", base64Data ? base64Data.length : "null");
    console.log("Base64 data preview:", base64Data ? base64Data.substring(0, 100) + "..." : "null");

    try {
      // Check if PDF data is empty or invalid
      if (!base64Data || base64Data.trim() === "") {
        console.log("PDF ERROR: No PDF data provided");
        this._showError("Error", "Document not found");
        return;
      }

      console.log("PDF: Converting base64 to blob...");

      // Convert base64 to blob
      const byteCharacters = atob(base64Data);
      console.log("PDF: Decoded byte characters length:", byteCharacters.length);

      const byteNumbers = new Array(byteCharacters.length);
      for (let i = 0; i < byteCharacters.length; i++) {
        byteNumbers[i] = byteCharacters.charCodeAt(i);
      }
      const byteArray = new Uint8Array(byteNumbers);
      console.log("PDF: Created byte array, length:", byteArray.length);

      const blob = new Blob([byteArray], { type: "application/pdf" });
      console.log("PDF: Created blob, size:", blob.size);

      // Create blob URL
      const url = URL.createObjectURL(blob);
      console.log("PDF: Created blob URL:", url);

      // Salesforce Lightning compatible approach for opening PDF in new tab
      console.log("PDF: Attempting to open in new tab...");

      // Try different approaches for Salesforce Lightning compatibility
      try {
        // Approach 1: Direct window.open with blob URL
        const newWindow = window.open(url, "_blank");

        if (!newWindow) {
          console.log("PDF: Direct window.open failed, trying alternative approach...");
          // Approach 2: Create temporary link and simulate click
          this._createTemporaryLinkForViewing(url, filename);
        } else {
          console.log("PDF: Successfully opened in new tab");
          // Toast removed as per user request
          // this._showSuccess('Success', 'PDF opened in new tab!');
        }
      } catch (windowError) {
        console.log("PDF: Window.open approach failed, using link approach:", windowError);
        // Fallback: Create temporary link
        this._createTemporaryLinkForViewing(url, filename);
      }

      // Clean up blob URL after delay
      setTimeout(() => {
        console.log("PDF: Cleaning up blob URL:", url);
        URL.revokeObjectURL(url);
      }, 30000); // Extended cleanup time for viewing

      console.log("=== PDF VIEW COMPLETED ===");
    } catch (error) {
      console.log("PDF ERROR: Exception occurred:", error);
      this._showError("Error", "Error processing PDF: " + error.message);
    }
  }

  /**
   * @description Create temporary link for PDF viewing when direct window.open fails
   * @param {String} url - Blob URL of the PDF
   * @param {String} filename - Filename for the PDF
   */
  _createTemporaryLinkForViewing(url, filename) {
    console.log("PDF: Creating temporary link for viewing...");

    try {
      // Create a temporary link element
      const link = document.createElement("a");
      link.href = url;
      link.target = "_blank";
      link.rel = "noopener noreferrer";
      link.style.display = "none";
      link.textContent = "Open PDF";

      // Add to DOM, click, and remove
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      console.log("PDF: Temporary link clicked for viewing");
      // Toast removed as per user request
      // this._showSuccess('Success', 'PDF opened in new tab!');
    } catch (linkError) {
      console.log("PDF ERROR: Link approach also failed:", linkError);
      // Final fallback: Try to open with data URL
      this._tryDataUrlApproach(base64Data, filename);
    }
  }

  /**
   * @description Try to open PDF using data URL as final fallback
   * @param {String} base64Data - Base64 encoded PDF data
   * @param {String} filename - Filename for the PDF
   */
  _tryDataUrlApproach(base64Data, filename) {
    console.log("PDF: Attempting data URL approach...");

    try {
      const dataUrl = `data:application/pdf;base64,${base64Data}`;
      const newWindow = window.open(dataUrl, "_blank");

      if (newWindow) {
        console.log("PDF: Data URL approach successful");
        // this._showSuccess('Success', 'PDF opened in new tab!');
      } else {
        console.log("PDF: All approaches failed");
        this._showError("Error", "Unable to open PDF. Please try again or check your browser settings.");
      }
    } catch (dataError) {
      console.log("PDF ERROR: Data URL approach failed:", dataError);
      this._showError("Error", "Error opening PDF: method not supported by browser.");
    }
  }

  /**
   * @description Download PDF file to user's device
   * @param {String} base64Data - Base64 encoded PDF data
   * @param {String} filename - Filename for download
   */
  _downloadPdfFile(base64Data, filename) {
    try {
      // Check if PDF data is empty or invalid
      if (!base64Data || base64Data.trim() === "") {
        this._showError("Error", "Document not found");
        return;
      }

      // Convert base64 to blob
      const byteCharacters = atob(base64Data);
      const byteNumbers = new Array(byteCharacters.length);
      for (let i = 0; i < byteCharacters.length; i++) {
        byteNumbers[i] = byteCharacters.charCodeAt(i);
      }
      const byteArray = new Uint8Array(byteNumbers);
      const blob = new Blob([byteArray], { type: "application/pdf" });

      // Create download link
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = filename;
      link.style.display = "none";

      // Trigger download
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      // Clean up blob URL
      setTimeout(() => URL.revokeObjectURL(url), 1000);
    } catch (error) {
      this._showError("Error", "Error downloading PDF: " + error.message);
    }
  }

  /**
   * @description Handle errors consistently
   * @param {Error} error - Error object
   * @param {String} documentType - Type of document being processed
   */
  _handleError(error, documentType) {
    const docConfig = DOCUMENT_CONFIG[documentType];
    const docLabel = docConfig ? docConfig.label : "document";
    let errorMessage = `Error processing the download of ${docLabel}`;

    if (error.body && error.body.message) {
      errorMessage = error.body.message;
    } else if (error.body && typeof error.body === "string") {
      errorMessage = error.body;
    } else if (error.message) {
      errorMessage = error.message;
    } else if (typeof error === "string") {
      errorMessage = error;
    }

    this._showError("Error", errorMessage);
  }

  /**
   * @description Show success toast message
   * @param {String} title - Toast title
   * @param {String} message - Success message
   */
  _showSuccess(title, message) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: title || "Success",
        message: message,
        variant: "success"
      })
    );
  }

  /**
   * @description Show info toast message
   * @param {String} title - Toast title
   * @param {String} message - Info message
   */
  _showInfo(title, message) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: title || "Info",
        message: message,
        variant: "info",
        mode: "dismissible"
      })
    );
  }

  /**
   * @description Show error toast message
   * @param {String} title - Toast title
   * @param {String} error - Error message or object
   */
  _showError(title, error) {
    // Ensure we always have a message to display
    let message = "An error occurred";

    if (typeof error === "string") {
      message = error;
    } else if (error?.body?.message) {
      message = error.body.message;
    } else if (error?.message) {
      message = error.message;
    } else if (error) {
      message = String(error);
    }

    this.dispatchEvent(
      new ShowToastEvent({
        title: title || "Error",
        message: message,
        variant: "error",
        mode: "dismissible"
      })
    );
  }
}