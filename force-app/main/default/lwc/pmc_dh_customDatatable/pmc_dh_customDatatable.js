import { LightningElement, api, track, wire } from "lwc";
import { SORT_DIRECTION, fireEvent } from "c/pmc_dh_utilityJs";
import { CurrentPageReference } from "lightning/navigation";

import pmc_sorting_ascSort from "@salesforce/label/c.pmc_sorting_ascSort";
import pmc_sorting_descSort from "@salesforce/label/c.pmc_sorting_descSort";
import pmc_datatable_rowActions from "@salesforce/label/c.pmc_datatable_rowActions";

/**
 * A custom LWC datatable.
 * @alias Pmc_dh_customDatatable
 * @extends LightningElement
 * @hideconstructor
 * @author Manisha Singh
 * @example
 * <c-pmc_dh_custom-datatable columns=[] table-data=[]></c-pmc_dh_custom-datatable>
 */

export default class Pmc_dh_customDatatable extends LightningElement {
  /**
   * @typedef Action
   * @type {object}
   * @property {string} label - action label name.
   * @property {string} value - action value.
   */
  /**
   * Type Attributes for 'action'
   * Refer 'lightning-button-menu' for below attributes
   * @typedef ActionAttributeHash
   * @type {object}
   * @property {string} variant - The variants to change the look of the button
   * @property {string} menuAlignment - Determines the alignment of the menu relative to the button
   * @property {string} iconName - The name of the icon to be used in the format 'utility:down'
   * @property {string} iconSize - The size of the icon
   * @property {string} tooltipTxt - Text to display when the user mouses over or focuses on the button
   * @property {Action[]} rowActions - Action items of row
   */

  /**
   * Type Attributes for 'badge'
   * Refer 'lightning-badge' for below attributes
   * @typedef BadgeAttributeHash
   * @type {object}
   * @property {string} variant - Classes for styling the badge
   * @property {string} iconName - The Lightning Design System name of the icon to be displayed inside the badge.
   * @property {string} position - The position for the icon.
   * @property {string} tooltipTxt - The alternative text used to describe the icon, as tooltip
   */
  /**
   * Cell Attributes for column
   * @typedef CellAttributeHash
   * @type {object}
   * @property {string} class - Style class for the column
   */
  /**
   * @typedef Column
   * @type {object}
   * @property {string} label - column label name.
   * @property {string} fieldName - column api field name.
   * @property {string} type - column type[Accepted values - text/phone/badge/action]
   * @property {string} dataType - column data type
   * @property {boolean} sortable - column sortable or not
   * @property {string} defaultSortDirection - column default sort direction
   * @property {CellAttributeHash} cellAttributes - column styles can be added inside class property
   * @property {BadgeAttributeHash|ActionAttributeHash} typeAttributes - column type attribues(varies acc to type)
   */
  /**
   * Used to display columns of the table
   * @type {Column[]}
   */
  @api
  get columns() {
    return this._columns;
  }
  set columns(value) {
    this._columns = JSON.parse(JSON.stringify(value));
  }

  /**
   * Records coming from salesforce object, used to display data in the table
   * @type {Object[]}
   */
  @api
  get tableData() {
    return this._tableData;
  }
  set tableData(value) {
    if (value) {
      this._tableData = value;
      this.updateRecords();
    }
  }

  @api defaultSortOrder;

  @api originalRecords;

  @wire(CurrentPageReference) pageRef;

  @track labels = {
    pmc_sorting_ascSort,
    pmc_sorting_descSort,
    pmc_datatable_rowActions
  };
  @track _tableData;

  /**
   * @typedef Record
   * @type {object}
   * @property {string} id
   * @property {object} data
   */
  /**
   * Used to display data inside the table
   * @type {Record[]}
   */
  @track records;

  @track _columns;

  sortBy;
  sortedDirection;

  /**
   * @function updateRecords
   * Sets 'records' property based on data payload coming from parent component
   */
  updateRecords() {
    this.records = [];
    this._tableData.forEach((data, dataIndex) => {
      let id = data.strRecId || data.Id;
      let rowData = {
        id: id,
        loopId: id + "_" + dataIndex,
        data: []
      };
      if (data?.isDisabled) {
        rowData.isDisabled = true;
      }
      this._columns.forEach((col) => {
        let columnData = {
          field: col.fieldName,
          value: data[col.fieldName]
        };
        columnData[`is${col.type}`] = true;
        columnData.cellAttributes = col.cellAttributes
          ? col.cellAttributes
          : {};
        columnData.typeAttributes = col.typeAttributes
          ? JSON.parse(JSON.stringify(col.typeAttributes))
          : null;
        if (
          col.type === "action" &&
          data.rowLevelActions &&
          data.rowLevelActions.length
        ) {
          columnData.typeAttributes.rowActions = data.rowLevelActions;
        }
        if (col.type === "badge" && data.badgeStyleClass) {
          columnData.cellAttributes.class = data.badgeStyleClass;
        }
        rowData.data.push(columnData);
      });
      this.records.push(rowData);
    });
  }

  /**
   * @function handleOnselect
   * On select of datatable row action handler
   * @param {Event} event
   */
  handleOnselect(event) {
    const rowActionEvent = new CustomEvent("rowactionselection", {
      detail: {
        value: event.detail.value,
        id: event.currentTarget.dataset.id
      }
    });
    this.dispatchEvent(rowActionEvent);
  }

  /**
   * @function handleOnclick
   * On click of a link row action handler
   * @param {Event} event
   */
  handleOnclick(event) {
    const rowLinkEvent = new CustomEvent("rowlinkclick", {
      detail: {
        id: event.currentTarget.dataset.id
      }
    });
    this.dispatchEvent(rowLinkEvent);
  }

  /**
   * @function handleDynamicLinkclick
   * On click of a dynamic link field
   * @param {Event} event
   */
  handleDynamicLinkclick(event) {
    const rowDynamicLinkEvent = new CustomEvent("dynamiclinkclick", {
      detail: {
        id: event.currentTarget.dataset.id
      }
    });
    this.dispatchEvent(rowDynamicLinkEvent);
  }

  /**
   * @function handleChangeCheckbox
   * On click of checkbox
   * @param {Event} event
   */
  handleChangeCheckbox(event) {
    const checkboxClickEvent = new CustomEvent("checkboxclick", {
      detail: {
        id: event.currentTarget.dataset.id,
      }
    });
    this.dispatchEvent(checkboxClickEvent);
  }

  /**
   * @function doSorting
   * - Sort data records
   * @param {Event} event
   */
  doSorting(event) {
    let colDataType = "string";
    this.sortBy = event.currentTarget.name;
    this._columns.forEach((col) => {
      if (col.fieldName === this.sortBy) {
        this.sortedDirection = col.isAscSort
          ? SORT_DIRECTION.ASC
          : SORT_DIRECTION.DESC;
        col.isAscSort = !col.isAscSort;
        colDataType = col.dataType ? col.dataType : colDataType;
        fireEvent(this.pageRef, "colSortEv", {
          sortBy:
            colDataType === "dateRange"
              ? col.dateSortField
              : colDataType === "datetime" && col.dateTimeSortField
                ? col.dateTimeSortField
                : this.sortBy,
          datatype: colDataType === "dateRange" ? "date" : colDataType,
          sortDirection: this.sortedDirection
        });
      } else {
        col.isAscSort =
          col.dataType === "date"
            ? false
            : this.defaultSortOrder === SORT_DIRECTION.ASC
              ? true
              : false;
      }
    });
  }
}