import { LightningElement, api } from "lwc";
import hasDebug from "@salesforce/customPermission/MD_DEBUG";
import md_reportfilters_headertitle from "@salesforce/label/c.md_reportfilters_headertitle";
import md_reportfilters_advanced_filters from "@salesforce/label/c.md_reportfilters_advanced_filters";
import md_reportfilters_clear_btn from "@salesforce/label/c.md_reportfilters_clear_btn";
import md_reportfilters_apply_btn from "@salesforce/label/c.md_reportfilters_apply_btn";

const DEBUG = (...args) => {
  if (hasDebug) console.log("[Md_report]", ...args);
};

export default class Md_reportFilters extends LightningElement {
  @api isVisible = false;
  @api showAdvanced = false;
  @api primaryFields = [];
  @api advancedFields = [];
  @api hideAdvancedBtn = false;

  @api headerLabel;
  @api applyLabel;
  @api clearLabel;
  @api advancedLabel;

  get headerText() {
    return this.headerLabel || md_reportfilters_headertitle;
  }

  get advancedText() {
    return this.advancedLabel || md_reportfilters_advanced_filters;
  }

  get clearText() {
    return this.clearLabel || md_reportfilters_clear_btn;
  }

  get applyText() {
    return this.applyLabel || md_reportfilters_apply_btn;
  }

  get showFilters() {
    return this.isVisible;
  }

  get hasPrimaryFields() {
    return this.composedPrimaryFields.length > 0;
  }

  get hasAdvancedFields() {
    return this.composedAdvancedFields.length > 0;
  }

  get showAdvancedFilterButton() {
    return this.hasAdvancedFields && !this.hideAdvancedBtn;
  }

  get advancedContainerClass() {
    return `md-advanced-container ${this.showAdvanced ? "md-advanced-open" : "md-advanced-closed"}`;
  }

  get composedPrimaryFields() {
    return (this.primaryFields || []).map((field, index) => {
      const isDate = field.type === "date";
      const isPicklist = field.isPicklist === true;
      const composedValue = isPicklist ? [...(Array.isArray(field.value) ? field.value : [])] : field.value || "";

      return {
        key: field.key || field.name || `primary-${index}`,
        name: field.name || `primary_${index}`,
        label: field.label || "",
        placeholder: field.placeholder || (isPicklist ? "Select" : ""),
        type: field.type || "text",
        isDate,
        isPicklist,
        options: [...(field.options || [])],
        value: composedValue
      };
    });
  }

  get composedAdvancedFields() {
    return this._composeFields(this.advancedFields, true);
  }

  get primaryGridStyle() {
    const count = this.composedPrimaryFields.length || 1;
    return `grid-template-columns: repeat(${count}, 1fr);`;
  }

  get advancedFieldRows() {
    return this._chunkFields(this.composedAdvancedFields, 3, "advanced");
  }

  _composeFields(fields = [], isMultiValue) {
    let debugList = [];

    let finalFields = (fields || []).map((field, index) => {
      const isDate = field.type === "date";
      const multiValue = isMultiValue && !isDate;
      const composedValue = multiValue ? [...(Array.isArray(field.value) ? field.value : [])] : field.value || "";

      let item = {
        key: field.key || field.name || `field-${index}`,
        name: field.name || `field_${index}`,
        label: field.label || field.name || "",
        placeholder: field.placeholder || (multiValue ? "Select" : ""),
        type: field.type || "text",
        isDate,
        options: [...(field.options || [])],
        value: composedValue
      };

      if (hasDebug && isMultiValue) {
        debugList.push(
          `[MdReportFilters] _composeFields: Name: ${item.name} | Value: ${item.value} | IsArray: ${Array.isArray(item.value)} | MultiValue: ${item.multiValue} | ComposedValue: ${item.composedValue}`
        );
      }

      return item;
    });

    if (hasDebug && debugList.length > 0) {
      console.groupCollapsed("[MdReportFilters] _composeFields");

      for (let item of debugList) {
        DEBUG(item);
      }

      console.groupEnd();
    }

    return finalFields;
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
    DEBUG("handleTextFieldChange", "fieldName: " + fieldName, "value: " + value);

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

  handlePrimaryChange(event) {
    const fieldName = event.target?.dataset?.name || event.currentTarget?.dataset?.name;
    const rawValue = event.detail?.value ?? event.target?.value;
    const value = Array.isArray(rawValue) ? [...rawValue] : rawValue || "";

    this.dispatchEvent(
      new CustomEvent("filterchange", {
        detail: {
          fieldName,
          section: "primary",
          value,
          filters: this._buildFilters({ [fieldName]: value })
        }
      })
    );
  }

  handleAdvancedChange(event) {
    const fieldName = event.target?.dataset?.name || event.currentTarget?.dataset?.name;
    const rawValue = event.detail?.value ?? event.target?.value;
    const value = Array.isArray(rawValue) ? [...rawValue] : rawValue || "";
    DEBUG("handleAdvancedChange", "fieldName: " + fieldName, "rawValue: " + JSON.stringify(rawValue), "value: " + JSON.stringify(value));

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
    const primaryFilters = this.composedPrimaryFields.reduce((accumulator, field) => {
      accumulator[field.name] = field.isPicklist ? [...field.value] : field.value;
      return accumulator;
    }, {});

    const advancedFilters = this.composedAdvancedFields.reduce((accumulator, field) => {
      accumulator[field.name] = field.isDate ? field.value : [...field.value];
      return accumulator;
    }, {});

    return {
      ...primaryFilters,
      ...advancedFilters,
      ...overrides
    };
  }

  _buildClearedFilters() {
    const clearedPrimaryFilters = this.composedPrimaryFields.reduce((accumulator, field) => {
      accumulator[field.name] = field.isPicklist ? [] : "";
      return accumulator;
    }, {});

    const clearedAdvancedFilters = this.composedAdvancedFields.reduce((accumulator, field) => {
      accumulator[field.name] = field.isDate ? "" : [];
      return accumulator;
    }, {});

    return {
      ...clearedPrimaryFilters,
      ...clearedAdvancedFilters
    };
  }
}