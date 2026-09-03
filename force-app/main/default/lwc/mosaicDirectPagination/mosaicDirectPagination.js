import { LightningElement, api } from "lwc";

export default class MosaicDirectPagination extends LightningElement {
  @api hasRecords = false;
  @api currentPage = 1;
  @api totalPages = 1;
  @api pageButtons = [];

  get isPrevDisabled() { return this.currentPage <= 1; }
  get isNextDisabled() { return this.currentPage >= this.totalPages; }
  get isFirstPageActive() { return this.currentPage === 1; }
  get isLastPageActive() { return this.currentPage === this.totalPages; }
  get showLastPage() { return this.totalPages > 1; }
  get showLeftEllipsis() { return this.currentPage > 4; }
  get showRightEllipsis() { return this.currentPage < this.totalPages - 3; }

  handlePrevPage() {
    if (this.isPrevDisabled) return;
    this._dispatchPageChange(this.currentPage - 1);
  }

  handleNextPage() {
    if (this.isNextDisabled) return;
    this._dispatchPageChange(this.currentPage + 1);
  }

  handlePageClick(event) {
    const page = parseInt(event.currentTarget.dataset.page, 10);
    if (!isNaN(page) && page >= 1 && page <= this.totalPages && page !== this.currentPage) {
      this._dispatchPageChange(page);
    }
  }

  _dispatchPageChange(page) {
    this.dispatchEvent(new CustomEvent("pagechange", { detail: { page } }));
  }
}