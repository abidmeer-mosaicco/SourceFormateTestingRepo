import { LightningElement, api } from "lwc";
import hasDebug from '@salesforce/customPermission/MD_DEBUG';
import md_reportfilters_headertitle from "@salesforce/label/c.md_reportfilters_headertitle";
import md_reportfilters_advanced_filters from "@salesforce/label/c.md_reportfilters_advanced_filters";
import md_reportfilters_clear_btn from "@salesforce/label/c.md_reportfilters_clear_btn";
import md_reportfilters_apply_btn from "@salesforce/label/c.md_reportfilters_apply_btn";

const DEBUG = (label, ...args) => {
  if (!hasDebug) return;
  args.forEach(a => console.log(a));
};

export default class MosaicDirectInTransitFilters extends LightningElement {
  @api isVisible = false;
  @api showAdvanced = false;
  @api textFields = [];
  @api advancedFields = [];

  labels = {
    md_reportfilters_headertitle,
    md_reportfilters_advanced_filters,
    md_reportfilters_clear_btn,
    md_reportfilters_apply_btn
  };

  get showFilters() {
    return this.isVisible;
  }

  get hasTextFields() {
    return this.composedTextFields.length > 0;
  }

  get hasAdvancedFields() {
    return this.composedAdvancedFields.length > 0;
  }

  get advancedContainerClass() {
    return `md-advanced-container ${this.showAdvanced ? "md-advanced-open" : "md-advanced-closed"}`;
  }

  get composedTextFields() {
    return this._composeFields(this.textFields, false);
  }

  get composedAdvancedFields() {
    return this._composeFields(this.advancedFields, true);
  }

  get textFieldRows() {
    return this._chunkFields(this.composedTextFields, 4, "text");
  }

  get advancedFieldRows() {
    return this._chunkFields(this.composedAdvancedFields, 3, "advanced");
  }

  _composeFields(fields = [], isMultiValue) {
    return (fields || []).map((field, index) => {
      const isDate = field.type === "date";
      const isText = isMultiValue && field.type === "text";
      const isMultiSelect = isMultiValue && !isDate && !isText;
      const composedValue = isMultiSelect ? [...(Array.isArray(field.value) ? field.value : [])] : field.value || "";
      return {
        key: field.key || field.name || `field-${index}`,
        name: field.name || `field_${index}`,
        label: field.label || field.name || "",
        placeholder: field.placeholder || (isMultiSelect ? "Select" : ""),
        type: field.type || "text",
        isDate,
        isText,
        isMultiSelect,
        options: [...(field.options || [])],
        value: composedValue
      };
    });
  }

  _chunkFields(fields = [], chunkSize = 1, prefix = "row") {
    const rows = [];

    for (let index = 0; index < fields.length; index += chunkSize) {
      rows.push({
        key: `${prefix}-${index}`,
        fields: fields.slice(index, index + chunkSize)
      });
    }

    return rows;
  }

  handleTextFieldChange(event) {
    const fieldName = event.target.dataset.name;
    const value = (event.detail?.value ?? event.target.value ?? "").toString().trim();
    DEBUG('handleTextFieldChange', 'fieldName: ' + fieldName, 'value: ' + value);

    this.dispatchEvent(
      new CustomEvent("filterchange", {
        detail: {
          fieldName,
          section: "text",
          value,
          filters: this._buildFilters({ [fieldName]: value })
        }
      })
    );
  }

  handleToggleAdvanced() {
    this.dispatchEvent(new CustomEvent("toggleadvanced"));
  }

  handleAdvancedChange(event) {
    const fieldName = event.target?.dataset?.name || event.currentTarget?.dataset?.name;
    const rawValue = event.detail?.value ?? event.target?.value;
    const value = Array.isArray(rawValue) ? [...rawValue] : rawValue || "";
    DEBUG('handleAdvancedChange',
      'fieldName: ' + fieldName,
      'rawValue: ' + JSON.stringify(rawValue),
      'value: ' + JSON.stringify(value)
    );

    this.dispatchEvent(
      new CustomEvent("filterchange", {
        detail: {
          fieldName,
          section: "advanced",
          value,
          filters: this._buildFilters({ [fieldName]: value })
        }
      })
    );
  }

  handleApplyFilter() {
    this.dispatchEvent(
      new CustomEvent("applyfilters", {
        detail: this._buildFilters()
      })
    );
  }

  handleClearFilter() {
    this.dispatchEvent(
      new CustomEvent("clearfilters", {
        detail: this._buildClearedFilters()
      })
    );
  }

  _buildFilters(overrides = {}) {
    const textFilters = this.composedTextFields.reduce((accumulator, field) => {
      accumulator[field.name] = field.value;
      return accumulator;
    }, {});

    const advancedFilters = this.composedAdvancedFields.reduce((accumulator, field) => {
      accumulator[field.name] = field.isMultiSelect ? [...field.value] : field.value;
      return accumulator;
    }, {});

    return {
      ...textFilters,
      ...advancedFilters,
      ...overrides
    };
  }

  _buildClearedFilters() {
    const clearedTextFilters = this.composedTextFields.reduce((accumulator, field) => {
      accumulator[field.name] = "";
      return accumulator;
    }, {});

    const clearedAdvancedFilters = this.composedAdvancedFields.reduce((accumulator, field) => {
      accumulator[field.name] = field.isMultiSelect ? [] : "";
      return accumulator;
    }, {});

    return {
      ...clearedTextFilters,
      ...clearedAdvancedFilters
    };
  }
}