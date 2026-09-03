import { LightningElement } from 'lwc';
import CopadoSalesforceLogo from '@salesforce/resourceUrl/CopadoSalesforceLogo';
import CopadoPlan from '@salesforce/resourceUrl/CopadoPlan';
import CopadoCreate from '@salesforce/resourceUrl/CopadoCreate';
import CopadoCommit from '@salesforce/resourceUrl/CopadoCommit';
import CopadoTest from '@salesforce/resourceUrl/CopadoTest';
import CopadoPromote from '@salesforce/resourceUrl/CopadoPromote';
import CopadoApprove from '@salesforce/resourceUrl/CopadoApprove';
import CopadoDeploy from '@salesforce/resourceUrl/CopadoDeploy';
import CopadoMonitor from '@salesforce/resourceUrl/CopadoMonitor';

export default class CopadoCircleFlowComp extends LightningElement {
    CopadoSalesforceLogo = CopadoSalesforceLogo;

    iconList = [];

    //display label with image
    connectedCallback() {
        const iconData = [
            { src: CopadoPlan, label: 'Plan' },
            { src: CopadoCreate, label: 'Create' },
            { src: CopadoCommit, label: 'Commit' },
            { src: CopadoTest, label: 'Test' },
            { src: CopadoPromote, label: 'Promote' },
            { src: CopadoApprove, label: 'Approve' },
            { src: CopadoDeploy, label: 'Deploy' },
            { src: CopadoMonitor, label: 'Monitor' }
        ];

        this.iconList = iconData.map((item, index) => ({
            id: index + 1,
            src: item.src,
            label: item.label,
            className: `orbit-icon icon-${index}`
        }));
    }

}