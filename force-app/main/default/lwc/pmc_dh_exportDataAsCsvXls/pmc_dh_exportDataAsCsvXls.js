import { LightningElement, track, api } from 'lwc';
import pmc_brandingStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import { getTodayDate } from "c/pmc_dh_utilityJs";

import pmc_modal_cancel from "@salesforce/label/c.pmc_modal_cancel";
import pmc_orderHistory_download from "@salesforce/label/c.pmc_orderHistory_download";
import pmc_quote_aceptQuoteText from "@salesforce/label/c.pmc_quote_aceptQuoteText";
import pmc_orderHistory_confirmDownload from "@salesforce/label/c.pmc_orderHistory_confirmDownload";
import pmc_orderHistory_confirmDownloadFile from "@salesforce/label/c.pmc_orderHistory_confirmDownloadFile";
import pmc_orderHistory_recordsLimit from "@salesforce/label/c.pmc_orderHistory_recordsLimit";
import pmc_orderHistory_recordsLimit2 from "@salesforce/label/c.pmc_orderHistory_recordsLimit2";
import pmc_orderHistory_downloadOrderHistory from "@salesforce/label/c.pmc_orderHistory_downloadOrderHistory";
import pmc_orderHistory_csvFileTitle from "@salesforce/label/c.pmc_orderHistory_csvFileTitle";

export default class pmc_dh_exportDataAsCsvXls extends LightningElement {
  @track labels = {
    pmc_modal_cancel,
    pmc_orderHistory_download,
    pmc_quote_aceptQuoteText,
    pmc_orderHistory_confirmDownload,
    pmc_orderHistory_confirmDownloadFile,
    pmc_orderHistory_recordsLimit,
    pmc_orderHistory_recordsLimit2
  }

  @api exportFileType = "csv";
  @api columnHeader = [];
  @api columnHeaderTitles = [];
  @api exportData = [];
  isOpenModal = false;
  isMouseOver = false;
  buttonUrl = `${pmc_brandingStaticResource}/icons/icon-xls.svg`;
  titleName = pmc_orderHistory_downloadOrderHistory;

  /**
   * Exports data as excel
   * @function exportDataAsExcel
   */
  exportDataAsExcel() {
    let that = this;
    let doc = '<table>';
    doc += '<style>';
    doc += 'table, th, td {';
    doc += '    border: 1px solid black;';
    doc += '    border-collapse: collapse;';
    doc += '    font-weight: normal';
    doc += '}';
    doc += '</style>';
    doc += '<tr>';
    this.columnHeaderTitles.forEach(element => {
      doc += '<th>' + element + '</th>'
    });
    doc += '</tr>';
    this.exportData.forEach(row => {
      doc += '\n';
      doc += '<tr>';
      that.columnHeader.forEach(column => {
        doc += '<th>' + row[column] + '</th>';
      });
      doc += '</tr>';
    });
    doc += '</table>';
    let element = 'data:application/vnd.ms-excel,' + encodeURIComponent(doc);
    let downloadElement = document.createElement('a');
    downloadElement.href = element;
    downloadElement.target = '_self';
    // use .csv as extension on below line if you want to export data as csv
    downloadElement.download = 'Contact Data.xls';
    document.body.appendChild(downloadElement);
    downloadElement.click();
  }

  /**
   * Exports data as csv
   * @function exportDataAsCsv
   */
  exportDataAsCsv() {
    let that = this;
    let doc = '';
    this.columnHeaderTitles.forEach(column => {
      doc += column + ','
    });
    doc += '\n';
    if (this.exportData.length > 0) {
      this.exportData.forEach(row => {
        that.columnHeader.forEach(column => {
          let columnData = "";
          if (row[column]) {
            columnData = String(row[column]).replaceAll(',', ' ');
            // columnData = String(row[column]).replaceAll(';', ',');
            columnData = (columnData[0] === '0' && columnData[1] === '0') ? ('="' + columnData + '"') : columnData;
          }
          doc += columnData + ',';
        });
        doc += '\n';
      });
    }
    let element = 'data:text/csv;charset=utf-8,%EF%BB%BF' + encodeURIComponent(doc);
    let downloadElement = document.createElement('a');
    downloadElement.href = element;
    downloadElement.target = '_self';
    // if you want to export data as csv, use .csv as extension on below line
    let todayDate = getTodayDate("DDMMYYYY");
    downloadElement.download = `${pmc_orderHistory_csvFileTitle}_${todayDate}.csv`;
    document.body.appendChild(downloadElement);
    downloadElement.click();
  }

  /** 
   * Modal open handler 
   * @function handleOpenModal
   */
  handleOpenModal() {
    this.isOpenModal = !this.isOpenModal;
  }

  /** 
   * Modal close handler 
   * @function handleCloseModal
   */
  handleCloseModal() {
    this.isOpenModal = !this.isOpenModal;
  }

  /** 
   * Modal accessibility handler 
   * @function handleIconKeyDown
   */
  handleIconKeyDown(event) {
    if (event.keyCode === 13) {
      this.handleOpenModal();
    }
  }

  /** 
   * Mouse over Icon Handler 
   * @function handleMouseEnter
   */
  handleMouseEnter() {
    this.isMouseOver = true;
  }

  /** 
   * Mouse Leave Handler 
   * @function handleMouseLeave
   */
  handleMouseLeave() {
    this.isMouseOver = false;
  }

  /** 
   * Download Handler 
   * @function downloadHandler
   */
  downloadHandler() {
    switch (this.exportFileType) {
      case 'csv': this.exportDataAsCsv(); break;
      case 'xlsx':
      case 'xls': this.exportDataAsExcel(); break;
      default: this.exportDataAsCsv(); break;
    }
    this.handleCloseModal();
  }
}