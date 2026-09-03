import { LightningElement, api } from "lwc";

export default class MosaicDirectPagination extends LightningElement {
  @api hasRecords = false;
  @api currentPage = 1;
  @api totalPages = 1;
  @api pageButtons = [];
  @api isPrevDisabled = false;
  @api isNextDisabled = false;
  @api isFirstPageActive = false;
  @api isLastPageActive = false;
  @api showLeftEllipsis = false;
  @api showRightEllipsis = false;
  @api showLastPage = false;

  handlePrevPage() {
    if (this.isPrevDisabled) return;
    this.dispatchPageChange(this.currentPage - 1);
  }

  handleNextPage() {
    if (this.isNextDisabled) return;
    this.dispatchPageChange(this.currentPage + 1);
  }

  handlePageClick(event) {
    const page = parseInt(event.currentTarget.dataset.page, 10);
    if (!isNaN(page) && page >= 1 && page <= this.totalPages && page !== this.currentPage) {
      this.dispatchPageChange(page);
    }
  }

  dispatchPageChange(page) {
    this.dispatchEvent(
      new CustomEvent("pagechange", {
        detail: { page }
      })
    );
  }
}