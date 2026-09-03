import LightningDatatable from "lightning/datatable";
import picklistColumn from "./picklistColumn.html";
import staticColumn from "./staticColumn.html";

export default class ExtendedDatatable extends LightningDatatable {
  static customTypes = {
    picklistColumn: {
      template: staticColumn,
      editTemplate: picklistColumn,
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
    }
  };
}