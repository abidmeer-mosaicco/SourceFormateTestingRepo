import { LightningElement, api, track } from "lwc";
import createOrderCarts from '@salesforce/apex/OrderCartService.createOrderCarts';
import * as DateHelper from './date-helper';

export default class MosaicDirectPlaceOrderModal extends LightningElement {
  @api open = false;

  // UOM vindo do parent (summary) — atribuído ao form.uom quando definido
  _uom = '';
  @api
  get uom() {
    return this._uom;
  }
  set uom(val) {
    this._uom = val || '';
    try {
      // sempre sobrescreve form.uom com o valor recebido do parent
      if (!this.form) this.form = { ...this.form };
      this.form = { ...this.form, uom: this._uom };
    } catch (e) {
      // silent
    }
  }

  @api originCity = "";
  @api originState = "";
  @api shipMethodFromContract = "";
  @api incotermFromContract = "";
  @api transportModeFromContract = "";
  @api allowShipToSelection = false;
  @api shipToOptionsFromContract = [];
  @api fixedShipToValue = "";
  @api shiptoId;
  @api selectedRecord;
  @api contractItem = "";
  @api contractDescription = "";
  @api subscriptionId = "";
  @api contract;
  @api contractId = "";
  @api account = "";
  @api quote = "";
  @api quoteLine = "";
  @api opportunity = "";
  @api availableQtyTons = 0;
  @api minQtyPerLoad;
  @api maxQtyPerLoad;
  @api paymentTerms = '';
  @api advanceBilling = '';
  @api incoterm2 = '';
  @api incoterm = '';
  @api exchangeRate = '';
  @api startDate = '';
  @api endDate = '';
  @api productLocation = '';
  @api unitOfMeasure = '';
  @api salesOffice = "";
  @api contractStartDate = "";
  @api contractEndDate = "";
  _initialized = false;

  minDate;
  maxDate;

  shipToSearchValue = '';
  allShipTos = [];

  displayShipToOptions = [];
  shipToInput = '';
  selectedShipTo = null;

  @track form = {
    origin: "",
    originDisplay: "",
    unitOfMeasure: "",
    shipTo: "",
    requestedDate: "",
    trucks: 1,
    quantityPerLoad: null,
    oneOrderPerTruck: false,
    orderNumber: "",
    incrementalPo: null,
    uom: ""
  };

  @track loads = [];
  groupKey = `ORDER-${Date.now()}`;

  get originDisplay() {
    const city = (this.originCity || "").trim();
    const state = (this.originState || "").trim().toUpperCase();
    if (city && state) return `${city}, ${state}`;
    if (city && !state) return city;
    if (!city && state) return state;
    return "Not available";
  }

  get shipMethodDisplay() {
    const v = (this.shipMethodFromContract || "").trim();
    return v || "Not specified";
  }

  get shipToOptions() {
    return (Array.isArray(this.displayShipToOptions) && this.displayShipToOptions.length > 0)
      ? this.displayShipToOptions
      : (Array.isArray(this.shipToOptionsFromContract) ? this.shipToOptionsFromContract : []);
  }

  get canEditShipTo() {
    const inc = (this.incotermFromContract || "").toUpperCase();
    const mot = (this.transportModeFromContract || "").toUpperCase();
    const rule = (inc === "FOB" || inc === "FCA") && mot === "TRUCK";
    this.allowShipToSelection = this.shipToOptions.length > 0;

    // console.log('RULE >>> ', rule);
    // console.log('inc >>> ', inc);
    // console.log('mot >>> ', mot);
    // console.log('allowShipToSelection >>> ', this.allowShipToSelection);
    // console.log('shipToOptions.length >>> ', this.shipToOptions.length);
    // console.log('fixedShipToValue >>> ', !this.fixedShipToValue);

    return this.allowShipToSelection && rule && this.shipToOptions.length > 0;// && !this.fixedShipToValue;
  }

  get shipToDisplay() {
    if (this.canEditShipTo) {
      const lbl = this.getShipToLabel(this.form.shipTo);
      return lbl || "Not available";
    }

    if (this.fixedShipToValue) {
      return this.getShipToLabel(this.fixedShipToValue) || this.fixedShipToValue;
    }

    if (this.shipToOptions.length === 1) {
      return this.shipToOptions[0].label || this.shipToOptions[0].value;
    }

    return "Not available";
  }

  get defaultQtyPerLoad() {
    const mot = (this.transportModeFromContract || "").toUpperCase();
    let total = 0;

    if (mot === "TRUCK") total = 25;
    if (mot === "RAIL") total = 100;
    if (mot === "BARGE") total = 1500;

    return total;
  }

  get trucksValid() {
    const n = Number(this.form.trucks);
    return Number.isInteger(n) && n > 0;
  }

  get quantityPerLoadValid() {
    const n = Number(this.form.quantityPerLoad);

    if (n <= 0) return false;
    if (this.minQtyPerLoad != null && n < Number(this.minQtyPerLoad)) return false;
    if (this.maxQtyPerLoad != null && n > Number(this.maxQtyPerLoad)) return false;
    if (this.availableQtyTons > 0 && this.trucksValid) {
      let total = n * Number(this.form.trucks);
      if (total > Number(this.availableQtyTons)) return false;
    }

    return true;
  }

  get requestedDateValid() {
    const selected = this.form.requestedDate;
    if (!selected) return false;

    const selDate = new Date(`${selected}T00:00:00`);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    if (selDate < today) return false;
    if (!DateHelper.isBusinessDay(selected, this.salesOffice)) return false;

    if (this.minDate) {
      const minDateObj = new Date(`${this.minDate}T00:00:00`);
      if (selDate < minDateObj) return false;
    }

    if (this.maxDate) {
      const maxDateObj = new Date(`${this.maxDate}T00:00:00`);
      if (selDate > maxDateObj) return false;
    }

    return true;
  }

  get isShipToValid() {
    if (this.canEditShipTo) {
      if (!this.form.shipTo) return false;
      return this.shipToOptions.some((o) => o.value === this.form.shipTo);
    }

    if (this.fixedShipToValue) return true;
    if (this.shipToOptions.length === 1) return true;

    return false;
  }

  get totalQuantity() {
    const t = Number(this.form.trucks) || 0;
    const q = Number(this.form.quantityPerLoad) || 0;
    return t * q;
  }

  get isShipToSearchValid() {
    if (!this.canEditShipTo) return true;
    if (!this.shipToSearchValue) return false;

    return this.displayShipToOptions.some(
      opt => opt.label.toLowerCase() === this.shipToSearchValue.toLowerCase()
    );
  }

  get saveDisabled() {
    const invalidShipToSearch = this.canEditShipTo && !this.isShipToSearchValid;

    const isDisabled = !(
      this.trucksValid &&
      this.quantityPerLoadValid &&
      this.isShipToValid &&
      this.requestedDateValid &&
      !invalidShipToSearch
    );

    console.log('Save Disabled Status:', {
      isDisabled,
      trucksValid: this.trucksValid,
      quantityPerLoadValid: this.quantityPerLoadValid,
      isShipToValid: this.isShipToValid,
      requestedDateValid: this.requestedDateValid,
      formData: { ...this.form }
    });

    return isDisabled;
  }

  connectedCallback() {
    console.log({ incoterm: this.incoterm || this.incotermFromContract })
    console.log({ salesOffice: this.salesOffice })
    console.log({ salesChannel: this.salesChannel })

    let effectiveIncoterm = this.incoterm || this.incotermFromContract || '';
    let leadTimeDays = DateHelper.getLeadTimeDays(
      this.salesOffice,
      effectiveIncoterm
    );

    let earliestByLeadTime = DateHelper.getEarliestShipmentDate(
      this.salesOffice,
      effectiveIncoterm
    );

    let contractStartBusiness = this.contractStartDate ? DateHelper.getFirstBusinessDayOnOrAfter(this.contractStartDate) : null;
    let effectiveMinDate = earliestByLeadTime;

    if (contractStartBusiness) {
      let contractStartDateObj = new Date(contractStartBusiness + 'T00:00:00');
      let earliestDateObj = new Date(earliestByLeadTime + 'T00:00:00');

      if (contractStartDateObj > earliestDateObj) {
        effectiveMinDate = contractStartBusiness;
      }
    }

    this.minDate = effectiveMinDate;
    this.maxDate = this.contractEndDate ? DateHelper.getLastBusinessDayOnOrBefore(this.contractEndDate) : null;

    console.log({ maxDate: this.maxDate })

    this.leadTimeDays = leadTimeDays;

    if (!this._initialized) {
      this.resetForm();
      this._initialized = true;
    }
    this.displayShipToOptions = this.shipToOptionsFromContract.slice();
    this.displayShipToOptions.sort((a, b) => a.label.localeCompare(b.label));
    this.rebuildLoads();
    this.emitChange("draft");
  }

  handleClose() {
    this.open = false;
    this.showShipToDropdown = false;
    this.dispatchEvent(new CustomEvent("close"));
  }

  handleInputChange(event) {
    let name = event.target.name || event.target?.dataset?.id;
    let value = event.target.type === "checkbox" ? event.detail.checked : event.detail.value;

    console.log({ name })
    console.log({ value })

    if (name === "trucks" || name === "quantityPerLoad") {
      let n = Number(value);

      if (isNaN(n)) {
        event.target.setCustomValidity("Enter a number.");
      } else if (!Number.isInteger(n)) {
        event.target.setCustomValidity("Enter a whole number.");
      } else if (n < 1) {
        event.target.setCustomValidity("Enter a positive whole number.");
      } else if (name === "quantityPerLoad" && this.minQtyPerLoad != null && n < Number(this.minQtyPerLoad)) {
        event.target.setCustomValidity(`Minimum per load is ${this.minQtyPerLoad} t.`);
      } else if (name === "quantityPerLoad" && this.maxQtyPerLoad != null && n > Number(this.maxQtyPerLoad)) {
        event.target.setCustomValidity(`Maximum per load is ${this.maxQtyPerLoad} t.`);
      } else {
        event.target.setCustomValidity('');
      }
      event.target.reportValidity();
    }

    if (name === "incrementalPo") {
      let n = Number(value);
      if (isNaN(n)) {
        event.target.setCustomValidity("Enter a number.");
      } else if (!Number.isInteger(n)) {
        event.target.setCustomValidity("Enter a whole number.");
      } else if (n < 0) {
        event.target.setCustomValidity("Enter a non-negative whole number.");
      } else {
        event.target.setCustomValidity('');
      }

      event.target.reportValidity();
    }

    if (name === "shipTo" && this.canEditShipTo) {
      if (!this.shipToOptions.some((o) => o.value === value)) {
        event.target.setCustomValidity("Select a valid Ship-to location.");
      } else {
        event.target.setCustomValidity('');
      }

      event.target.reportValidity();
    }

    if (name === "requestedDate") {
      let boolError = false;

      if (!value) {
        event.target.setCustomValidity("Shipment date is required.");
        boolError = true;
      }

      if (!DateHelper.isBusinessDay(value, this.salesOffice)) {
        event.target.setCustomValidity("Shipment date must be a business day (Monday to Friday).");
        boolError = true;
      }

      console.log({ contractEndDate: this.contractEndDate })

      if (new Date(value) > new Date(this.contractEndDate)) {
        event.target.setCustomValidity("Shipment date must be within the contract end date.");
        boolError = true;
      }

      if (!boolError) event.target.setCustomValidity('');

      event.target.reportValidity();
    }

    this.form = { ...this.form, [name]: value };

    if (["trucks", "quantityPerLoad", "orderNumber", "incrementalPo", "requestedDate"].includes(name)) {
      this.applyValidity();
      this.rebuildLoads();
    }

    this.emitChange("draft");
  }

  rebuildLoads() {
    const { trucks, quantityPerLoad, requestedDate, orderNumber, incrementalPo, shipTo } = this.form;

    let chosenShipTo;

    if (this.shipToOptions && this.shipToOptions.length > 0) {
      if (!this.form.shipTo) {
        const defaultShipTo = this.shipToOptions[0].value;
        this.form.shipTo = defaultShipTo;
      }
    }
    if (chosenShipTo == null) chosenShipTo = shipTo || (this.shipToOptions[0] && this.shipToOptions[0].value) || "";

    const origin = this.originDisplay;
    const shipMethod = this.shipMethodDisplay;
    const safeTrucks = Math.max(0, parseInt(trucks || 0, 10));
    const qpl = Number(quantityPerLoad || 0);
    const lines = [];

    let incrementValue = Number(incrementalPo);
    let hasValidIncrement = !isNaN(incrementValue) && incrementValue > 0;

    for (let i = 0; i < safeTrucks; i++) {
      let poInc = "";

      if (hasValidIncrement) {
        let calculatedIncrement = incrementValue * (i + 1);

        if (orderNumber && orderNumber.trim() !== '') {
          poInc = `${orderNumber}-${calculatedIncrement}`;
        } else {
          poInc = `-${calculatedIncrement}`;
        }
      } else {
        poInc = orderNumber || "";
      }

      if (poInc == '-') poInc = '';

      lines.push({
        groupKey: this.groupKey,
        loadIndex: i + 1,
        qty: qpl,
        requestedDate: requestedDate || null,
        shipMethod,
        shipTo: chosenShipTo,
        origin,
        display: `Load #${i + 1} • ${qpl}t • ${requestedDate || ""}`,
        clientRowId: `${this.groupKey}-${i + 1}`,
        orderNumber: poInc
      });
    }

    this.loads = lines;
    this.form = { ...this.form, origin, shipTo: chosenShipTo };
  }

  emitChange(action) {
    this.dispatchEvent(
      new CustomEvent("placeorderchange", {
        detail: {
          action,
          groupKey: this.groupKey,
          header: {
            ...this.form,
            originCity: this.originCity || "",
            originState: (this.originState || "").toUpperCase(),
            originDisplay: this.originDisplay,
            shipMethod: this.shipMethodDisplay,
            incoterm: this.incotermFromContract || "",
            transportMode: this.transportModeFromContract || "",
            shipToLabel: this.getShipToLabel(this.form.shipTo) || "",
            totalQuantity: this.totalQuantity
          },
          loads: this.loads.slice(),
          totalQty: this.totalQuantity,
          validation: {
            shipToValid: this.isShipToValid,
            trucksValid: this.trucksValid,
            quantityPerLoadValid: this.quantityPerLoadValid,
            requestedDateValid: this.requestedDateValid
          }
        },
        bubbles: true,
        composed: true
      })
    );
  }

  applyValidity() {
    let inputs = this.template.querySelectorAll('lightning-input, lightning-combobox');
    let hasError = false;

    inputs.forEach(input => {
      let fieldName = input.name || input.getAttribute('data-id');
      if (!fieldName) return;

      let msg = '';

      // console.log(`Validating field: ${fieldName}, value: ${this.form[fieldName]}`);

      if (fieldName === 'trucks') {
        let trucks = Number(this.form.trucks);
        if (!Number.isInteger(trucks) || trucks <= 0) {
          msg = "Enter a positive whole number.";
          hasError = true;
        }
      }

      if (fieldName === 'quantityPerLoad') {
        let qty = Number(this.form.quantityPerLoad);
        if (qty <= 0) {
          msg = "Enter a positive number (tons).";
          hasError = true;
        } else if (this.minQtyPerLoad != null && qty < Number(this.minQtyPerLoad)) {
          msg = `Minimum per load is ${this.minQtyPerLoad} t.`;
          hasError = true;
        } else if (this.maxQtyPerLoad != null && qty > Number(this.maxQtyPerLoad)) {
          msg = `Maximum per load is ${this.maxQtyPerLoad} t.`;
          hasError = true;
        } else if (this.availableQtyTons > 0 && this.trucksValid) {
          let total = qty * Number(this.form.trucks);
          if (total > Number(this.availableQtyTons)) {
            msg = `Total exceeds available (${this.availableQtyTons} t).`;
            hasError = true;
          }
        }
      }

      if (fieldName === 'requestedDate') {
        let selected = this.form.requestedDate;
        if (!selected) {
          msg = "Shipment date is required.";
          hasError = true;
        } else {
          let selDate = new Date(`${selected}T00:00:00`);
          let today = new Date();
          today.setHours(0, 0, 0, 0);

          if (selDate < today) {
            msg = "Shipment date cannot be in the past.";
            hasError = true;
          } else if (!DateHelper.isBusinessDay(selected, this.salesOffice)) {
            msg = "Shipment date must be a business day (Monday to Friday).";
            hasError = true;
          } else if (this.minDate) {
            let minDateObj = new Date(`${this.minDate}T00:00:00`);
            if (selDate < minDateObj) {
              let leadDays = DateHelper.getLeadTimeDays(this.salesOffice, this.salesChannel, this.incotermFromContract);
              msg = leadDays > 0
                ? `Shipment date must be at least ${leadDays} business days after today (on or after ${this.minDate}).`
                : `Shipment date must be on or after ${this.minDate}.`;
              hasError = true;
            }
          }

          if (!msg && this.maxDate) {
            let maxDateObj = new Date(`${this.maxDate}T00:00:00`);
            if (selDate > maxDateObj) {
              msg = `Shipment date must be on or before ${this.maxDate}.`;
              hasError = true;
            }
          }
        }
      }

      if (fieldName === 'shipTo') {
        if (this.canEditShipTo && !this.form.shipTo) {
          msg = "Ship-to location is required.";
          hasError = true;
        } else if (this.canEditShipTo && !this.shipToOptions.some(o => o.value === this.form.shipTo)) {
          msg = "Select a valid Ship-to location.";
          hasError = true;
        }
      }

      if (fieldName === 'incrementalPo') {
        let poValue = this.form.incrementalPo;
        if (poValue !== null && poValue !== undefined && poValue !== '') {
          let numValue = Number(poValue);
          if (!Number.isInteger(numValue) || numValue < 0) {
            msg = "Enter a non-negative whole number.";
            hasError = true;
          }
        }
      }

      input.setCustomValidity(msg);
      input.reportValidity();
    });

    console.log('Validation Summary:', {
      hasError,
      trucksValid: this.trucksValid,
      quantityPerLoadValid: this.quantityPerLoadValid,
      isShipToValid: this.isShipToValid,
      requestedDateValid: this.requestedDateValid,
      formData: { ...this.form }
    });

    return hasError;
  }

  handleSave() {
    let hasValidationErrors = this.applyValidity();

    console.log('handleSave - Validation Errors:', hasValidationErrors);
    console.log('handleSave - Save Disabled:', this.saveDisabled);

    if (hasValidationErrors || this.saveDisabled) {
      this.dispatchEvent(
        new CustomEvent("placeordererror", {
          detail: {
            reason: "Please check if all fields are filled in correctly!",
            validation: {
              shipToValid: this.isShipToValid,
              trucksValid: this.trucksValid,
              quantityPerLoadValid: this.quantityPerLoadValid,
              requestedDateValid: this.requestedDateValid
            }
          },
          bubbles: true,
          composed: true
        })
      );
      return;
    }

    dispatchEvent(new CustomEvent('loadingEvent'));

    const cartDto = this.buildCartDto();
    createOrderCarts({ cartsJson: JSON.stringify([cartDto]) }).then((results) => {
      const eventDetail = this.buildEventDetail(results);

      this.dispatchEvent(
        new CustomEvent("placeorderchange", {
          detail: eventDetail,
          bubbles: true,
          composed: true
        })
      );

      this.dispatchEvent(
        new CustomEvent("placesuccess", {
          detail: { results },
          bubbles: true,
          composed: true
        })
      );

      this.resetForm();
      this.rebuildLoads();
      this.handleClose();
    }).catch((error) => {
      console.error('Error creating order carts:', error);

      this.dispatchEvent(
        new CustomEvent("placeordererror", {
          detail: { error },
          bubbles: true,
          composed: true
        })
      );
    }).finally(() => dispatchEvent(new CustomEvent('loadingEvent')));
  }

  buildCartDto() {
    let { trucks, quantityPerLoad, requestedDate, orderNumber, incrementalPo, shipTo, oneOrderPerTruck } = this.form;

    // ALTERAÇÃO COPADO

    const safeTrucks = Math.max(0, Number(trucks) || 0);
    const qtyPerLoad = Number(quantityPerLoad) || 0;

    if (!orderNumber) orderNumber = this.contract?.contractPO || '';

    const cartDto = {
      poNumber: orderNumber,
      contractItem: this.contractItem || "",
      contractDescription: this.contractDescription || "",
      itemQtyAvailable: Number(this.availableQtyTons) || 0,
      contractId: this.contractId || "",
      account: this.account || "",
      quote: this.quote || "",
      opportunity: this.opportunity || "",
      paymentTerms: this.paymentTerms || "",
      startDate: this.startDate || "",
      incoterm: this.incoterm || this.incotermFromContract || "",
      productLocation: this.productLocation || "",
      unitOfMeasure: this.unitOfMeasure || "",
      oneOrderPerTruck: !!oneOrderPerTruck,
      transportMode: this.transportModeFromContract || "",
      trucks: safeTrucks,
      items: []
    };

    let chosenShipTo = "";
    let chosenShipToLabel = "";

    if (this.allowShipToSelection) {
      // determina criação das linhas com base em oneOrderPerTruck e trucks
      chosenShipTo = shipTo || (this.shipToOptions[0]?.value) || "";
      // chosenShipTo = (this.shipToOptions[0]?.value) || shipTo || "";
      chosenShipToLabel = this.getShipToLabel(chosenShipTo) || "";
    } else {
      chosenShipTo = this.shiptoId || '';
      chosenShipToLabel = shipTo;
    }

    const baseItem = {
      reqShipmentDate: requestedDate || null,
      orderQty: qtyPerLoad,
      shipMethod: this.shipMethodDisplay || "",
      transportMode: this.transportModeFromContract || "",
      origin: this.originDisplay || this.form.origin || "",
      shipToId: chosenShipTo,
      shipToName: chosenShipToLabel,
      shipTo: chosenShipTo,
      shiptoId: this.shiptoId || '',
      subscriptionId: this.subscriptionId || "",
      quoteLine: this.quoteLine || "",
      advanceBilling: this.advanceBilling || "",
      incoterm2: this.incoterm2 || "",
      incoterm: this.incoterm || this.incotermFromContract || "",
      productLocation: this.productLocation || "",
      unitOfMeasure: this.unitOfMeasure || "",
      exchangeRate: this.exchangeRate || "",
      uom: this.form.uom || "",
    };

    let incrementValue = Number(incrementalPo);
    let hasValidIncrement = !isNaN(incrementValue) && incrementValue > 0;

    if (oneOrderPerTruck) {
      // criar apenas UMA linha OrderCartItem usando os valores informados
      let orderPoValue = "";
      if (hasValidIncrement) {
        let calculatedIncrement = incrementValue;
        orderPoValue = orderNumber && orderNumber.trim() !== ''
          ? `${orderNumber}-${calculatedIncrement}`
          : `-${calculatedIncrement}`;
      } else {
        orderPoValue = orderNumber || "";
      }

      cartDto.items.push({ ...baseItem, orderNumber: orderPoValue });
    } else {
      // criar uma linha por carga (How many loads == trucks)
      for (let i = 0; i < safeTrucks; i++) {
        let orderPoValue = "";

        if (hasValidIncrement) {
          let calculatedIncrement = incrementValue * (i + 1);

          if (orderNumber && orderNumber.trim() !== '') {
            orderPoValue = `${orderNumber}-${calculatedIncrement}`;
          } else {
            orderPoValue = `-${calculatedIncrement}`;
          }
        } else {
          orderPoValue = orderNumber || "";
        }

        if (orderPoValue == '' || !orderPoValue) orderPoValue = this.contract?.contractPO || '';

        cartDto.items.push({
          ...baseItem,
          orderNumber: orderPoValue,
          orderPoNumber: orderPoValue,
          poNumber: orderPoValue,
        });
      }
    }

    return cartDto;
  }

  buildEventDetail(results) {
    const { trucks, quantityPerLoad, orderNumber, incrementalPo, shipTo, oneOrderPerTruck } = this.form;
    const safeTrucks = Math.max(0, Number(trucks) || 0);

    let chosenShipTo = "";
    let chosenShipToLabel = "";

    if (this.allowShipToSelection) {
      chosenShipTo = shipTo || (this.shipToOptions[0]?.value) || "";
      chosenShipToLabel = this.getShipToLabel(chosenShipTo) || "";
    } else {
      chosenShipTo = this.shiptoId || '';
      chosenShipToLabel = shipTo;
    }

    const baseHeader = {
      ...this.form,
      originCity: this.originCity || "",
      originState: (this.originState || "").toUpperCase(),
      originDisplay: this.originDisplay,
      shipMethod: this.shipMethodDisplay,
      incoterm: this.incotermFromContract || "",
      transportMode: this.transportModeFromContract || "",
      contractItem: this.contractItem,
      shipToLabel: chosenShipToLabel || "",
      totalQuantity: this.totalQuantity,
      subscription: this.subscriptionId
    };

    const resultsArray = Array.isArray(results) ? results : [];
    const items = [];

    let incrementValue = Number(incrementalPo);
    let hasValidIncrement = !isNaN(incrementValue) && incrementValue > 0;

    const generateOrderNumber = (index) => {
      if (hasValidIncrement) {
        let calculatedIncrement = incrementValue * (index + 1);
        let tmpOrderNumber = orderNumber || this.contract?.contractPO || "";

        return tmpOrderNumber && tmpOrderNumber.trim() !== ''
          ? `${tmpOrderNumber}-${calculatedIncrement}`
          : `-${calculatedIncrement}`;
      }

      return orderNumber || "";
    };

    // Se oneOrderPerTruck: vários carts (um por caminhão), 1 item por cart
    if (oneOrderPerTruck) {
      resultsArray.forEach((r, index) => {
        items.push({
          id: (r.itemIds?.[0]) || undefined,
          // expose the created OrderCart id so consumers can correlate placedOrders -> OrderCart
          orderCart: r.cartId || undefined,
          quantity: Number(quantityPerLoad) || 0,
          uom: this.form.uom || "",
          shipMethod: this.shipMethodDisplay || "",
          origin: this.form.origin || this.originDisplay || "",
          shipTo: chosenShipTo || "",
          shipToLabel: chosenShipToLabel || "",
          subscription: this.subscriptionId,
          orderNumber: generateOrderNumber(index) || this.contract?.contractPO || ""
        });
      });
    } else {
      // Caso padrão: 1 cart com N itens (N = trucks)
      const r0 = resultsArray[0] || { cartId: null, itemIds: [] };
      const itemIds = Array.isArray(r0.itemIds) ? r0.itemIds : [];

      for (let i = 0; i < safeTrucks; i++) {
        items.push({
          id: itemIds[i] || undefined,
          // single cart case: attach the cart id to each item as well
          orderCart: r0.cartId || undefined,
          quantity: Number(quantityPerLoad) || 0,
          uom: this.form.uom || "",
          shipMethod: this.shipMethodDisplay || "",
          origin: this.form.origin || this.originDisplay || "",
          shipTo: chosenShipTo || "",
          shipToLabel: chosenShipToLabel || "",
          orderNumber: generateOrderNumber(i) || this.contract?.contractPO || ""
        });
      }
    }

    return {
      action: "save",
      groupKey: this.groupKey,
      // expose all created cart ids when multiple were created (oneOrderPerTruck)
      header: {
        ...baseHeader,
        orderCartId: resultsArray[0]?.cartId || null,
        orderCartIds: resultsArray.map(r => r.cartId).filter(x => x)
      },
      loads: this.loads.slice(),
      items,
      totalQty: this.totalQuantity,
      validation: {
        shipToValid: this.isShipToValid,
        trucksValid: this.trucksValid,
        quantityPerLoadValid: this.quantityPerLoadValid,
        requestedDateValid: this.requestedDateValid
      }
    };
  }

  getShipToLabel(shipToId) {
    const match = this.shipToOptions.find(o => o.value === shipToId);
    return match ? match.label : '';
  }
  
  handleShipToSearchInput(event) {
    if (event.key !== 'Enter') { return; }
    //if (!event?.target) return;

    let value = event.target.value ?? '';
    this.shipToSearchValue = value;

    if (!value.trim()) {
      this.displayShipToOptions = this.shipToOptionsFromContract.slice();
      this.displayShipToOptions.sort((a, b) => a.label.localeCompare(b.label));
      this.showShipToDropdown = true;
      return;
    }

    let lower = value.toLowerCase();
    let filtered = this.shipToOptionsFromContract.filter(
      opt => opt?.label?.toLowerCase().includes(lower)
    );

    this.displayShipToOptions = filtered;
    this.showShipToDropdown = filtered.length > 0;
  }

  showShipToOptions() {
    console.log('showShipToOptions');

    // if (this.showShipToDropdown == true) return;
    // if (this.showShipToDropdown == false) this.showShipToDropdown = true;

    this.displayShipToOptions = this.shipToOptionsFromContract.slice();
    this.displayShipToOptions.sort((a, b) => a.label.localeCompare(b.label));
    this.showShipToDropdown = this.displayShipToOptions.length > 0;
  }

  handleShipToSelect(event) {
    const value = event.currentTarget.dataset.value;
    const selected = this.shipToOptions.find(o => o.value === value);
    if (!selected) return;

    this.shipToSearchValue = selected.label;
    this.selectedShipTo = selected.value;
    this.form = { ...this.form, shipTo: selected.value };
    this.showShipToDropdown = false;
  }

  resetForm() {
    let initialShipTo = "";
    this.allShipTos = this.shipToOptionsFromContract.slice();
    this.displayShipToOptions = this.allShipTos.slice();
    this.displayShipToOptions.sort((a, b) => a.label.localeCompare(b.label));

    if (this.fixedShipToValue) {
      initialShipTo = this.shiptoId || this.shipToOptions[0].value;
    } else if (this.shipToOptions.length === 1) {
      initialShipTo = this.shipToOptions[0].value;
    } else if (this.canEditShipTo && this.shipToOptions.length > 0) {
      initialShipTo = this.shipToOptions[0].value;
    }

    const initialDate = this.minDate || "";
    const initialQtyPerLoad = this.defaultQtyPerLoad || null;

    this.form = {
      origin: this.originDisplay,
      originDisplay: "",
      unitOfMeasure: "",
      shipTo: initialShipTo,
      requestedDate: initialDate,
      trucks: 1,
      quantityPerLoad: initialQtyPerLoad,
      oneOrderPerTruck: false,
      orderNumber: "",
      incrementalPo: null,
      uom: this._uom || ""
    };
    const label = this.getShipToLabel(initialShipTo);
    this.shipToSearchValue = label;

    console.log("Label:", label);

    Promise.resolve().then(() => {
      const input = this.template.querySelector('lightning-input[data-id="shipToSearch"]');
      if (input) {
        input.value = label;
      }
    });
  }
}