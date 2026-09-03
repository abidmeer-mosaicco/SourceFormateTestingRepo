import { LightningElement, track, api } from "lwc";

export default class FileUploadElement extends LightningElement {
    @api acceptedFormats = "";
    @api isMultiple;
    @api
    resetFiles() {
      this.uploadedFiles = [];
      this.filesData = [];
      this.invalidFormatFilesError = '';
      this.isWrongFormat = false;
    }
    @track uploadedFiles = [];
    @track filesData = [];
      
    isWrongFormat = false;
    loadSpinner = false;
    invalidFormatFilesError = '';
    acceptedFormatsErrorMessage = '';
  
    connectedCallback() {
      this.acceptedFormatsErrorMessage = this.acceptedFormats.replaceAll(".", "").toUpperCase();
    }
  
    handleChange(event) {
      this.handleFileUpload(event.target.files);
    }
  
    handleDrop(event) {
      event.preventDefault();
      event.stopPropagation();
      this.handleFileUpload(event.dataTransfer.files);
    }
  
    handleFileUpload(files) {
      this.invalidFormatFilesError = '';
      this.largeFiles = [];
      this.isWrongFormat = false;
      let that = this;
      let tempData = [];
      files = this.removeUnsupportedFiles(files);
      for (let i = 0; i < files.length; ++i) {
        let name = files[i].name;
        let extension = name.slice(name.lastIndexOf(".") + 1);
        if (this.uploadedFiles.includes(name)) {
          this.uploadedFiles.splice(this.uploadedFiles.indexOf(name), 1);
          this.filesData.splice(this.filesData.findIndex((el) => el.filename === name), 1);
        }
        this.uploadedFiles.push(name);
        const file = files[i];
        let reader = new FileReader();
        reader.readAsDataURL(file);
        this.loadSpinner = true;
        reader.onload = function (event) {
          var result = event.target.result;
          var base64 = result.split(",")[1];
          let fileData = {
            filename: name,
            filetype: extension,
            base64: base64
          };
          tempData.push(JSON.parse(JSON.stringify(fileData)));
          if (tempData.length === files.length) {
            that.filesData = [...that.filesData, ...tempData];
            that.dispatchEvent(
              new CustomEvent("uploadcomplete", {
                detail: {
                  filesData: JSON.parse(JSON.stringify(that.filesData))
                }
              })
            );
            that.loadSpinner = false;
            that.template.querySelector(`input`).value = null;
          }
        };
      }
    }
  
    removeUnsupportedFiles(files) {
      let filtered = [];
      for (let i = 0; i < files.length; ++i) {
        let name = files[i].name;
        let extension = name.slice(name.lastIndexOf(".") + 1);
        if (this.acceptedFormats.includes(extension)) {
          filtered.push(files[i]);
        }
        else {
          this.isWrongFormat = true;
          if (!this.invalidFormatFilesError) {
            this.invalidFormatFilesError = `${name}`;
          }
          else {
            this.invalidFormatFilesError = `${this.invalidFormatFilesError}, ${name}`;
          }
        }
      }
      if (this.isWrongFormat) {
        this.invalidFormatFilesError = `Following files could not be uploaded: ${this.invalidFormatFilesError}`;
      }
      return filtered;
    }
  
    handleDragOver(event) {
      event.preventDefault();
      event.stopPropagation();
    }
  
    handleDragEnter(event) {
      event.preventDefault();
      event.stopPropagation();
    }
  
    handleDragLeave(event) {
      event.preventDefault();
      event.stopPropagation();
    }
}