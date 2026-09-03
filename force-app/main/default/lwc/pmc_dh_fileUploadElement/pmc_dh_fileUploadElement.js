import { LightningElement, track, api } from "lwc";
import { formatLabel } from "c/pmc_dh_utilityJs";

import PMC_BrandingAssetsStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";

import pmc_fileUpload_dropFiles from "@salesforce/label/c.pmc_fileUpload_dropFiles";
import pmc_fileUpload_uploadDocument from "@salesforce/label/c.pmc_fileUpload_uploadDocument";
import pmc_fileUpload_errorMessage from "@salesforce/label/c.pmc_fileUpload_errorMessage";
import pmc_fileUpload_sizeErrMsg from "@salesforce/label/c.pmc_fileUpload_sizeErrMsg";
import pmc_fileUpload_nameErrMsg from "@salesforce/label/c.pmc_fileUpload_nameErrMsg";

const MIMES = [
  {
    type: 'jpeg',
    pattern: [0xFF, 0xD8, 0xFF],
    mask: [0xFF, 0xFF, 0xFF]
  },
  {
    type: 'jpg',
    pattern: [0xFF, 0xD8],
    mask: [0xFF, 0xFF]
  },
  {
    type: 'png',
    pattern: [0x89, 0x50, 0x4E, 0x47],
    mask: [0xFF, 0xFF, 0xFF, 0xFF]
  },
  {
    type: 'pdf',
    pattern: [0x25, 0x50, 0x44, 0x46, 0x2D],
    mask: [0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
  },
  {
    type: 'doc',
    pattern: [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1],
    mask: [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
  },
  {
    type: 'docx',
    pattern: [0x50, 0x4B, 0x03, 0x04],
    mask: [0xFF, 0xFF, 0xFF, 0xFF]
  },
  {
    type: 'xls',
    pattern: [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1],
    mask: [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
  },
  {
    type: 'xlsx',
    pattern: [0x50, 0x4B, 0x03, 0x04],
    mask: [0xFF, 0xFF, 0xFF, 0xFF]
  }
];

/**
 * A custom LWC for file upload element.
 * @alias Pmc_dh_fileUploadElement
 * @extends LightningElement
 * @hideconstructor
 * @author Hemant
 * @example
 * <c-pmc_dh_file-upload-element></c-pmc_dh_file-upload-element>
 */
export default class Pmc_dh_fileUploadElement extends LightningElement {
  @api type = "type1";
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
  @track mimes = [];
  @track templateSelector = {
    type1: true,
    type2: false,
  }

  @track labels = {
    pmc_fileUpload_dropFiles,
    pmc_fileUpload_uploadDocument
  };

  iterations = 0;
  erroredFiles = '';
  @track iconUrlObj = {
    file: `${PMC_BrandingAssetsStaticResource}/icons/icon-pages.svg`
  };

  isWrongFormat = false;
  loadSpinner = false;
  invalidFormatFilesError = '';
  acceptedFormatsErrorMessage = '';
  invalidFileNameErr = '';
  invalidFileSizeErr = '';
  
  /**
   * Lifecycle hook
   */
  connectedCallback() {
    this.acceptedFormatsErrorMessage = this.acceptedFormats.replaceAll(".", "").toUpperCase();
    if (this.type) {
      Object.keys(this.templateSelector).forEach(el => {
        this.templateSelector[el] = false;
      });
      this.templateSelector[this.type] = true;
    }
  }
  
  /**
   * On every file upload
   * @function handleChange
   * @param {Event} event 
   */
  handleChange(event) {
    this.handleFileUpload(event.target.files);
  }
  
  /**
   * On every file drag
   * @function handleDrop
   * @param {Event} event 
   */
  handleDrop(event) {
    event.preventDefault();
    event.stopPropagation();
    this.handleFileUpload(event.dataTransfer.files);
  }
  
  /**
  * Handle file upload
  * @function handleFileUpload
  * @param {Array} files 
  */
  handleFileUpload(files) {
    this.invalidFormatFilesError = '';
    this.invalidFileNameErr = '';
    this.invalidFileSizeErr = '';
    this.largeFiles = [];
    this.isWrongFormat = false;
    this.validateFileMIMEType(files);
  }

  /**
  * Upload the filtered files dispatch event to parent
  * @function uploadFilteredFiles
  * @param {Array} files 
  */
  uploadFilteredFiles(files) {
    let that = this;
    let tempData = [];
    for (let i = 0; i < files.length; ++i) {
      let name = files[i].name;
      let extension = name.slice(name.lastIndexOf(".") + 1);
      this.uploadedFiles.push({id: i, fileName: name});
      const file = files[i];
      that.loadSpinner = true;
      let reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = function (event) {
        let result = event.target.result;
        let base64 = result.split(",")[1];
        let fileData = {
          filename: name,
          filetype: extension,
          base64: base64
        };
        tempData.push(JSON.parse(JSON.stringify(fileData)));
        if (tempData.length === files.length) {
          that.filesData = JSON.parse(JSON.stringify(that.filesData.concat(tempData)));
          that.dispatchEvent(
            new CustomEvent("uploadcomplete", {
              detail: {
                filesData: JSON.parse(JSON.stringify(that.filesData))
              }
            })
          );
          that.loadSpinner = false;
          that.template.querySelector(`.${that.type} input `).value = null;
        }
      };
    }
  }

  /**
   * Remove a file if already uploaded
   * @function removeRepeatedFiles
   * @param {Array} files 
   */
  removeRepeatedFiles(files) {
    for (let i = 0; i < files.length; ++i) {
      let name = files[i].name;
      this.uploadedFiles.forEach((el) => {
        if (el.fileName === name) {
          this.uploadedFiles.splice(this.uploadedFiles.map((file) => file.fileName).indexOf(name), 1);
          this.filesData.splice(this.filesData.findIndex((item) => item.filename === name), 1);
        }
      });
    }
    this.validateFileName(files);
  }

  /**
   * Validate File names
   * @function validateFileName
   * @param {Array} files 
   */
  validateFileName(files) {
    let filtered = [];
    let erroredFilesStr = '';
    for (let i = 0; i < files.length; ++i) {
      let name = files[i].name;
      if (!(/^\w+.(jpg|png|jpeg|pdf|doc|docx|xls|xlsx)$/gm).test(name)) {
        this.isWrongFormat = true;
        if (!erroredFilesStr) {
          erroredFilesStr = `${name}`;
        }
        else {
          erroredFilesStr = `${erroredFilesStr}, ${name}`;
        }
      }
      else {
        filtered.push(files[i]);
      }
    }
    if (this.isWrongFormat && erroredFilesStr) {
      this.invalidFileNameErr = formatLabel(pmc_fileUpload_nameErrMsg,
        [
          erroredFilesStr
        ]);
    }

    this.validateFileSize(filtered);
  }

  /**
   * Validate File sizes
   * @function validateFileSize
   * @param {Array} files 
   */
  validateFileSize(files) {
    let filtered = [];
    let erroredFilesStr = '';
    for (let i = 0; i < files.length; ++i) {
      let fileSize = files[i].size;
      let name = files[i].name;
      if (fileSize > 5242880) {
        this.isWrongFormat = true;
        if (!erroredFilesStr) {
          erroredFilesStr = `${name}`;
        }
        else {
          erroredFilesStr = `${erroredFilesStr}, ${name}`;
        }
      }
      else {
        filtered.push(files[i]);
      }
    }
    if (this.isWrongFormat && erroredFilesStr) {
      this.invalidFileSizeErr = formatLabel(pmc_fileUpload_sizeErrMsg,
        [
          erroredFilesStr
        ]);
    }
    this.uploadFilteredFiles(filtered);
  }

  /**
   * Validate if MIMES match with extension specified for all files
   * @function validateFileMIMEType
   * @param {Array} files 
   */
  validateFileMIMEType(files) {
    this.loadSpinner = true;
    let that = this;
    that.iterations = 0;
    that.erroredFiles = '';
    let filtered = [];
    for (let i = 0; i < files.length; ++i) {
      let name = files[i].name;
      let extension = name.slice(name.lastIndexOf(".") + 1);
      let reader = new FileReader();
      reader.readAsArrayBuffer(files[i]);
      reader.onloadend = function (e) {
        if (e && e.target.readyState === FileReader.DONE && !e.target.error) {
          let bytes = new Uint8Array(e.target.result);
          let mime = MIMES?.find(
            (m) => m.type === extension);
          if (that.acceptedFormats.includes(extension) && !(mime && !that.checkIfBytesSatifiesMIMEType(bytes, mime))) {
            filtered.push(files[i]);
          }
          else {
            that.isWrongFormat = true;
            if (!that.erroredFiles) {
              that.erroredFiles = `${name}`;
            }
            else {
              that.erroredFiles = `${that.erroredFiles}, ${name}`;
            }
          }
          that.iterations = that.iterations + 1;
          if (that.iterations === files.length) {
            if (that.isWrongFormat) {
              that.invalidFormatFilesError = formatLabel(pmc_fileUpload_errorMessage,
                [
                  that.erroredFiles,
                  that.acceptedFormatsErrorMessage
                ]);
            }
            that.loadSpinner = false;
            that.removeRepeatedFiles(filtered);
          }
        }
      }
    }
    if (files.length === 0) {
      that.loadSpinner = false;
    }
  }

  /**
   * Validate if MIMES match with extension specified
   * @function validateFileMIMEType
   * @param {Array} bytes 
   * @param {Array} mime 
   */
  checkIfBytesSatifiesMIMEType(bytes, mime) {
    for (let i = 0, l = mime.mask.length; i < l; ++i) {
      let x = (bytes[i] & mime.mask[i]) - mime.pattern[i];
      if (x !== 0) {
        return false;
      }
    }
    return true;
  }

  /**
  * Prevent default behaviour
  * @function handleDragOver
  * @param {Event} event 
  */
  handleDragOver(event) {
    event.preventDefault();
    event.stopPropagation();
  }

  /**
   * Prevent default behaviour
   * @function handleDragEnter
   * @param {Event} event 
   */
  handleDragEnter(event) {
    event.preventDefault();
    event.stopPropagation();
  }

  /**
   * Prevent default behaviour
   * @function handleDragLeave
   * @param {Event} event 
   */
  handleDragLeave(event) {
    event.preventDefault();
    event.stopPropagation();
  }
}