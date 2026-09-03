import { LightningElement, api, track, wire } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import FORM_FACTOR from '@salesforce/client/formFactor';

import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import LEAD_OBJECT from '@salesforce/schema/Lead';

import LEAD_CROPS_FIELD from '@salesforce/schema/Lead.PMC_SS_Crops__c';

export default class AppointmentIntakeForm extends LightningElement {
  @api serviceResourceName;
  @api workTypeName;
  @api appointmentTypeName;
  @api scheduleStart; // ISO
  @api scheduleEnd;   // ISO
  @api timeZone;

  @api sizeOptions;
  @api leadTypeOptions;  
  @api cropsOptions;

  @api leadFirstName;
  @api leadLastName;
  @api leadEmail;
  @api leadMobilePhone;
  @api leadCompany;
  @api leadSize;
  @api leadType;
  @api leadCrops = '';

  @api saSubject;
  @api saDescription;

  @track cropsValues = [];    
  @track mobileCropsBuffer = [];
  @track showCropsModal = false;
  @track cropsFilter = '';

  // --------- UI API: Object & Picklist Values ----------
  @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
  objectInfo;

  get leadRtId() {
    return this.objectInfo?.data?.defaultRecordTypeId;
  }

  @wire(getPicklistValues, { recordTypeId: '$leadRtId', fieldApiName: LEAD_CROPS_FIELD })
  cropsPL;

  get formFactor() { return FORM_FACTOR; }
  get isPhone() { return FORM_FACTOR === 'Small'; }
  get isTablet() { return FORM_FACTOR === 'Medium'; }
  get isDesktop() { return FORM_FACTOR === 'Large'; }
  get labelVariant() { return this.isPhone ? 'label-stacked' : 'label-inline'; }

  get resolvedSizeOptions() {
    return this.sizeOptions ?? [
      { label: '1-249', value: '1-249' },
      { label: '250-499', value: '250-499' },
      { label: '500-999', value: '500-999' },
      { label: '1,000-2,499', value: '1,000-2,499' },
      { label: '2,500+', value: '2,500+' }
    ];
  }

  get resolvedLeadTypeOptions() { 

    return this.leadTypeOptions ?? [
      { label: 'Grower', value: 'Grower' },
      { label: 'Agronomist', value: 'Agronomist' },
      { label: 'Crop Consultant', value: 'Crop Consultant' },
      { label: 'Retailer', value: 'Retailer' },
      { label: 'Student', value: 'Student' },
      { label: 'Other', value: 'Other' }
    ];
  }

  get resolvedCropsOptions() { 
    // prioridade: schema -> @api cropsOptions -> vazio 
    const fromSchema = this.cropsPL?.data?.values?.map(v => ({ label: v.label, value: v.value })); 
    return fromSchema ?? this.cropsOptions ?? []; 
  }

  // Se o Flow (ou edição) já trouxer uma string para leadCrops, sincroniza a UI
  connectedCallback() {
    if (this.leadCrops) {
      this.cropsValues = this.leadCrops.split(';').map(s => s.trim()).filter(Boolean);
    }
  }

  // --------- Datas em TZ ----------
  get startLocal() { return this.fmt(this.scheduleStart, this.timeZone); }
  get endLocal() { return this.fmt(this.scheduleEnd, this.timeZone); }
  fmt(dateish, tz) {
    if (!dateish) return '';
    const d = new Date(dateish);
    try {
      return new Intl.DateTimeFormat(undefined, {
        timeZone: tz, year: 'numeric', month: '2-digit', day: '2-digit',
        hour: '2-digit', minute: '2-digit'
      }).format(d);
    } catch {
      return d.toLocaleString();
    }
  }

  // --------- Handlers gerais ----------
  handleChange = (e) => {
    const prop = e.target.dataset.id;   // ex.: 'leadFirstName' ou 'saSubject'
    const val = e.target.value;
    this[prop] = val;
    this.dispatchEvent(new FlowAttributeChangeEvent(prop, val));
  };

  // Dual-list (desktop/tablet)
  handleDualListChange = (e) => {
    this.cropsValues = e.detail.value || [];
    this.emitLeadCropsString();
  };

  // --------- CROPS (MOBILE) ----------
  openCropsModal = () => {
    this.cropsFilter = '';
    this.mobileCropsBuffer = [...(this.cropsValues || [])];
    this.showCropsModal = true;
  };
  closeCropsModal = () => { this.showCropsModal = false; };
  confirmCropsModal = () => {
    this.cropsValues = [...this.mobileCropsBuffer];
    this.showCropsModal = false;
    this.emitLeadCropsString();
  };
  handleCropsFilter = (e) => { this.cropsFilter = (e.target.value || '').toLowerCase(); };
  get filteredCropsOptions() {
    const all = this.resolvedCropsOptions;
    if (!this.cropsFilter) return all;
    return all.filter(o => (o.label || '').toLowerCase().includes(this.cropsFilter));
  }
  handleCropsCheckboxChange = (e) => {
    this.mobileCropsBuffer = e.detail.value || [];
  };
  handleRemoveCrop = (e) => {
    const val = e.detail?.name ?? e.detail?.item?.name; // compat
    this.cropsValues = (this.cropsValues || []).filter(v => v !== val);
    this.emitLeadCropsString();
  };

  // --- value->label map + pills list (evita função no template) ---
  get cropsValueToLabel() {
    const map = {};
    (this.resolvedCropsOptions || []).forEach(o => { map[o.value] = o.label; });
    return map;
  }
  get cropsPills() {
    const v2l = this.cropsValueToLabel;
    return (this.cropsValues || []).map(v => ({ value: v, label: v2l[v] || v }));
  }

  // --------- Emite string "A;B;C" para o Flow ----------
  emitLeadCropsString() {
    const s = (this.cropsValues || []).join(';');
    this.leadCrops = s;
    this.dispatchEvent(new FlowAttributeChangeEvent('leadCrops', s));
  }

  @api messages = '';

  @api validate() {
    const inputs = this.template.querySelectorAll(
      'lightning-input, lightning-combobox, lightning-dual-listbox, lightning-textarea, lightning-checkbox-group'
    );

    let messages = [];

    // valida campos nativos required
    inputs.forEach(c => {
      c.setCustomValidity('');
      if (!c.checkValidity()) {
        const label = c.label || c.dataset.id || 'Field';
        messages.push(`${label} is required.`);
      }
      c.reportValidity();
    });

    // email
    const emailCmp = this.template.querySelector('[data-id="leadEmail"]');
    if (emailCmp) {
      const emailVal = (emailCmp.value || '').trim();
      if (emailVal && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailVal)) {
        emailCmp.setCustomValidity('Please enter a valid email address.');
        emailCmp.reportValidity();
        messages.push('Email must be a valid format (example@domain.com).');
      }
    }

    // phone
    const phoneCmp = this.template.querySelector('[data-id="leadMobilePhone"]');
    if (phoneCmp) {
      const raw = (phoneCmp.value || '').trim();
      if (raw) {
        const digits = raw.replace(/\D/g, '');
        if (digits.length < 8 || digits.length > 15) {
          phoneCmp.setCustomValidity('Please enter a valid phone number (8-15 digits).');
          phoneCmp.reportValidity();
          messages.push('Phone number must have between 8 and 15 digits.');
        }
      }
    }

    // envia para fora
    this.messages = messages.join('\n');
    console.log('Validation messages:', messages);

    // ⚡️ Sempre retorna true, Flow decide se libera
    return { isValid: true };
  }


}