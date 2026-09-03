import { LightningElement, track } from 'lwc';

export default class pmc_dh_exportDataAsCsv extends LightningElement {
  @track conatctData = [
    { Id: "id1", FirstName: "firstname1", LastName: "lastname1", Email: "email@email.com" },
    { Id: "id2", FirstName: "firstname2", LastName: "lastname2", Email: "email@emai2.com" },
    { Id: "id3", FirstName: "firstname3", LastName: "lastnamelastnamelastname3", Email: "email@emai3.com" },
    { Id: "id4", FirstName: "firstname4", LastName: "lastname4", Email: "email@emai4.com" },
    { Id: "id5", FirstName: "firstname5", LastName: "lastname5", Email: "email@emai5.com" },
  ]

  columnHeader = ['ID', 'FirstName', 'LastName', 'Email']

  // @wire(getAccountDataToExport)
  // wiredData({ error, data }) {
  //     if (data) {
  //         this.conatctData = data;
  //     } else if (error) {
  //         console.error('Error:', error);
  //     }
  // }

  exportContactDataExcel() {
    // Prepare a html table
    let doc = '<table>';
    // Add styles for the table
    doc += '<style>';
    doc += 'table, th, td {';
    doc += '    border: 1px solid black;';
    doc += '    border-collapse: collapse;';
    doc += '    font-weight: normal';
    doc += '}';
    doc += '</style>';
    // Add all the Table Headers
    doc += '<tr>';
    this.columnHeader.forEach(element => {
      doc += '<th>' + element + '</th>'
    });
    doc += '</tr>';
    // Add the data rows
    this.conatctData.forEach(record => {
      doc += '<tr>';
      doc += '<th>' + record.Id + '</th>';
      doc += '<th>' + record.FirstName + '</th>';
      doc += '<th>' + record.LastName + '</th>';
      doc += '<th>' + record.Email + '</th>';
      doc += '</tr>';
    });
    doc += '</table>';
    let element = 'data:application/vnd.ms-excel,' + encodeURIComponent(doc);
    // var element = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,' + encodeURIComponent(doc);
    // var element = 'application/application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,' + encodeURIComponent(doc);
    let downloadElement = document.createElement('a');
    downloadElement.href = element;
    downloadElement.target = '_self';
    // use .csv as extension on below line if you want to export data as csv
    downloadElement.download = 'Contact Data.xls';
    document.body.appendChild(downloadElement);
    downloadElement.click();
  }

  exportContactDataCsv() {
    let doc = '';
    // Add the data coloums
    this.columnHeader.forEach(column => {
      doc += column + ','
    });
    doc += '\n';
    // Add the data rows
    this.conatctData.forEach(row => {
      // doc += ”;
      doc += row.Id + ',';
      doc += row.FirstName + ',';
      doc += row.LastName + ',';
      doc += row.Email + ',';
      doc += '\n';
    });
    let element = 'data:text/csv;charset=utf-8,' + encodeURIComponent(doc);
    let downloadElement = document.createElement('a');
    downloadElement.href = element;
    downloadElement.target = '_self';
    // if you want to export data as csv, use .csv as extension on below line
    downloadElement.download = 'Contact Data.csv';
    document.body.appendChild(downloadElement);
    downloadElement.click();
  }

}