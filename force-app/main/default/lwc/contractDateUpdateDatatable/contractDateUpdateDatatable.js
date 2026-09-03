import LightningDatatable from 'lightning/datatable';
import customIcon from './customIcon.html';

export default class ContractDateUpdateDatatable  extends LightningDatatable {
    static customTypes = {
        CustomIcon: {
            template: customIcon,
            standardCellLayout: true,
            typeAttributes: ['iconName', 'variant', 'text', 'textClass', 'title', 'showSpinner'],
        },
    };
}