import LightningDatatable from "lightning/datatable";
import customIcon from './customIcon.html';
import comboboxColumn from "./comboboxColumn.html";
import staticColumn from "./staticColumn.html";

/**
 * Extended datatable to support custom cell types for quote update history:
 * - comboboxColumn: for editable sales office with picklist options
 * - CustomIcon: for status icons with dynamic styling
 *
 * This component is used in quoteUpdateSelector to display the quote with enhanced visuals and inline editing capabilities.
 * 
 * @author Sergio Umlauf
 * @storynumber GCPM-2771
 */
export default class QuoteUpdateDatatable extends LightningDatatable {
  static customTypes = {
    // See https://developer.salesforce.com/docs/platform/lwc/guide/data-table-custom-types-editable.html
    comboboxColumn: {
      template: staticColumn,
      editTemplate: comboboxColumn,
      standardCellLayout: true,
      typeAttributes: [
        "label",
        "placeholder",
        "options",
        "value",
        "context",
        "variant",
        "name"
      ]
    },
    CustomIcon: {
      template: customIcon,
      standardCellLayout: true,
      typeAttributes: ["iconName", "variant", "text", "textClass", "title", "showSpinner"]
    }
  };
}