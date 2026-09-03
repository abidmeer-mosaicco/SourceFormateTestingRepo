import { LightningElement, api } from 'lwc';

export default class Pmc_cpq_processingProgress extends LightningElement {
	@api open = false;
	@api totalRows = 0;
	@api approvalTotal = 0;
	@api sapTotal = 0;
	@api approvalProcessed = 0;
	@api sapProcessed = 0;
	@api isWorking = false;
	@api isSuccess = false;
	@api isError = false;
	@api isPartial = false;

	handleClose() {
		this.dispatchEvent(new CustomEvent('close'));
	}
}