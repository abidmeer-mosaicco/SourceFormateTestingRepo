import { LightningElement, track } from 'lwc';
import createReq from '@salesforce/apex/CopadoAccessController.createCopadoAccessRequest';
import getRoles from '@salesforce/apex/CopadoAccessController.getCopadoRolePicklistValues';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CopadoAccessRequestComp extends LightningElement {
    @track envOptions = [];
    @track roleOptions = [];
    isSubmitting = false;

    fullName = ''; email = ''; salesforceUserName = '';
    projectName = ''; copadoRole = ''; reason = ''; managerEmail = '';

    connectedCallback() {
        Promise.all([getRoles()])
            .then(([roles]) => {
                this.roleOptions = (roles || []).map(v => ({ label: v, value: v }));
            })
            .catch(e => this.toast('Error', this.err(e), 'error'));
    }

    onChange = (e) => {
        const v = e.detail?.value ?? e.target.value;
        switch (e.target.label) {
            case 'Full Name *': this.fullName = v; break;
            case 'Work Email *': this.email = v; break;
            case 'Salesforce UserName': this.salesforceUserName = v; break;
            case 'Project Name': this.projectName = v; break;
            case 'Copado Role': this.copadoRole = v; break;
            case 'Reason *': this.reason = v; break;
            case 'Manager Email': this.managerEmail = v; break;
            default: break;
        }
    };

    async submit() {
        if (!this.reportValidity()) return;
        this.isSubmitting = true;
        try {
            await createReq({
                fullName: this.fullName, email: this.email, salesforceUserName: this.salesforceUserName,
                projectName: this.projectName, copadoRole: this.copadoRole,
                reason: this.reason, managerEmail: this.managerEmail
            });
            this.toast('Submitted', 'Request created and email sent to Copado team.', 'success');
            this.reset();
        } catch (e) {
            this.toast('Email failed', this.err(e), 'error');
        } finally {
            this.isSubmitting = false;
        }
    }

    reset() {
        this.fullName = this.email = this.salesforceUserName = this.projectName =
            this.copadoRole = this.reason = this.managerEmail = '';
    }

    reportValidity() {
        let ok = true;
        this.template.querySelectorAll('lightning-input, lightning-textarea, lightning-combobox')
            .forEach(c => { if (!c.checkValidity()) { c.reportValidity(); ok = false; } });
        return ok;
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    err(e) { return e?.body?.message || e?.message || 'Unexpected error'; }
}