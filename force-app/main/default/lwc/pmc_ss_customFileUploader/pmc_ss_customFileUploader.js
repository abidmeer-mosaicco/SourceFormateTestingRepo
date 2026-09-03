import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Pmc_ss_customFileUploader extends LightningElement {
    @api recordid;
    @api title;
    @track fileData;

    openfileUpload(event) {
        const file = event.target.files[0]
        var reader = new FileReader()
        reader.onload = () => {
            var base64 = reader.result.split(',')[1]
            this.fileData = {
                'filename': file.name,
                'base64': base64,
                'recordId': this.recordid
            }
            const fileUploaded = new CustomEvent('fileuploaded', {detail:  this.fileData  });
            this.dispatchEvent(fileUploaded);
        }
        reader.readAsDataURL(file)
    }
    @api checkValidity() {
        let isChildValidated = true;
        let inputFields = this.template.querySelectorAll('.Required');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isChildValidated = false;
            }
            
        });
        return isChildValidated;
}
}