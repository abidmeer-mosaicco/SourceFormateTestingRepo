import { api } from "lwc";
import LightningDatatable from "lightning/datatable";
import documentDownloadTemplate from "./documentDownloadTemplate.html";
import documentDownloadInvoiceTemplate from "./documentDownloadInvoiceTemplate.html";
import documentDownloadAllTemplate from "./documentDownloadAllTemplate.html";
import documentDownloadCoaTemplate from "./documentDownloadCoaTemplate.html";
import documentDownloadBolTemplate from "./documentDownloadBolTemplate.html";
import documentDownloadContractTemplate from "./documentDownloadContractTemplate.html";
import documentDownloadQuoteContractTemplate from "./documentDownloadQuoteContractTemplate.html";
import documentDownloadNfeTemplate from "./documentDownloadNfeTemplate.html";
import documentDownloadZbqiTemplate from "./documentDownloadZbqiTemplate.html";
import documentDownloadSamAllTemplate from "./documentDownloadSamAllTemplate.html";
import documentDownloadXmlTemplate from "./documentDownloadXmlTemplate.html";
import protocolStatusPillTemplate from "./protocolStatusPill.html";

export default class MosaicDirectListDatatable extends LightningDatatable {
  static customTypes = {
    documentDownload: {
      template: documentDownloadTemplate,
      standardCellLayout: true,
      typeAttributes: ["orderId", "shipmentItemId"]
    },
    documentDownloadInvoice: {
      template: documentDownloadInvoiceTemplate,
      standardCellLayout: true,
      typeAttributes: ["orderId", "shipmentItemId", "invoiceFounded"],
    },
    documentDownloadAll: {
      template: documentDownloadAllTemplate,
      standardCellLayout: true,
      typeAttributes: ["orderId", "shipmentItemId", "invoiceFounded", "bolFounded", "coaFounded"]
    },
    documentDownloadCoa: {
      template: documentDownloadCoaTemplate,
      standardCellLayout: true,
      typeAttributes: ["orderId", "shipmentItemId", "coaFounded"]
    },
    documentDownloadContract: {
      template: documentDownloadContractTemplate,
      standardCellLayout: true,
      typeAttributes: ["contractDocumentId"]
    },
    documentDownloadQuoteContract: {
      template: documentDownloadQuoteContractTemplate,
      standardCellLayout: true,
      typeAttributes: ["downloadUrl", "fileName", "hasFile"]
    },
    documentDownloadBol: {
      template: documentDownloadBolTemplate,
      standardCellLayout: true,
      typeAttributes: ["orderId", "shipmentItemId", "bolFounded"]
    },
    documentDownloadNfe: {
      template: documentDownloadNfeTemplate,
      standardCellLayout: true,
      typeAttributes: ["shipmentItemId", "nfeFounded"]
    },
    documentDownloadZbqi: {
      template: documentDownloadZbqiTemplate,
      standardCellLayout: true,
      typeAttributes: ["shipmentItemId", "zbqiFounded"]
    },
    documentDownloadSamAll: {
      template: documentDownloadSamAllTemplate,
      standardCellLayout: true,
      typeAttributes: ["shipmentItemId", "nfeFounded", "zbqiFounded"]
    },
    documentDownloadXml: {
      template: documentDownloadXmlTemplate,
      standardCellLayout: true,
      typeAttributes: ["shipmentItemId", "xmlFounded"]
    },
    protocolStatusPill: {
      template: protocolStatusPillTemplate,
      standardCellLayout: true,
      typeAttributes: ["statusLabel", "pillClass"]
    }
  };

  constructor() {
    super();
  }

  _scrollContainer;
  _outerContainer;
  _leftBtn;
  _rightBtn;
  _resizeObserver;
  _totalSectors = 1;
  _currentSector = 0;
  _hoveredRowEl;
  _isOverButton = false;
  _revertTimer;
  _pinned = false;
  _rightBtnWidth = 0;
  _leftBtnWidth = 0;

  renderedCallback() {
    if (super.renderedCallback) {
      super.renderedCallback();
    }

    if (!this._scrollContainer) {
      this._scrollContainer = this.template.querySelector(".slds-scrollable_x");
      this._outerContainer = this.template.querySelector(".dt-outer-container");

      if (this._scrollContainer && this._outerContainer) {
        this._injectButtons();
        this._scrollContainer.addEventListener("scroll", this._handleManualScroll);
        this._scrollContainer.addEventListener("mouseover", this._handleRowHover);
        this._scrollContainer.addEventListener("mouseleave", this._handleRowLeave);
        window.addEventListener("scroll", this._handlePageScroll, { passive: true });
        window.addEventListener("resize", this._handlePageScroll);
        this._resizeObserver = new ResizeObserver(this._recalculateSectors);
        this._resizeObserver.observe(this._scrollContainer);
        this._recalculateSectors();
        this._handlePageScroll();
      } else {
        console.warn(
          "[mosaicDirectListDatatable] .slds-scrollable_x ou .dt-outer-container não encontrados. "
        );
      }
    } else if (this._leftBtn && !this._leftBtn.isConnected) {
      this._injectButtons();
      this._recalculateSectors();
    }
  }

  disconnectedCallback() {
    if (this._scrollContainer) {
      this._scrollContainer.removeEventListener("scroll", this._handleManualScroll);
      this._scrollContainer.removeEventListener("mouseover", this._handleRowHover);
      this._scrollContainer.removeEventListener("mouseleave", this._handleRowLeave);
    }
    window.removeEventListener("scroll", this._handlePageScroll);
    window.removeEventListener("resize", this._handlePageScroll);
    if (this._rafId) {
      window.cancelAnimationFrame(this._rafId);
      this._rafId = null;
    }
    this._clearRevertTimer();
    if (this._resizeObserver) {
      this._resizeObserver.disconnect();
    }
  }

  _injectButtons() {
    if (!this._leftBtn) {
      this._leftBtn = this._createButton("left", () => this.scrollToSector(-1));
    }
    if (!this._rightBtn) {
      this._rightBtn = this._createButton("right", () => this.scrollToSector(1));
    }
    this._outerContainer.appendChild(this._leftBtn);
    this._outerContainer.appendChild(this._rightBtn);
  }

  _createButton(side, onClick) {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.title = side === "left" ? "Rolar para a esquerda" : "Rolar para a direita";
    btn.textContent = side === "left" ? "‹" : "›";
    btn.style.cssText = `
      position: fixed;
      top: 50%;
      left: 0px;
      transform: translateY(-50%);
      transition: top 180ms ease;
      border-width: medium;
      border-style: none;
      border-color: currentcolor;
      border-image: none;
      border-radius: 8px;
      background: rgb(15, 110, 79);
      color: rgb(255, 255, 255);
      cursor: pointer;
      z-index: 20;
      box-shadow: rgba(0, 0, 0, 0.25) 0px 2px 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 35px;
      min-height: 70px;
      padding: 0px 15px 7px;
    `;
    btn.addEventListener("click", () => {
      if (this._hoveredRowEl) {
        this._pinned = true;
        this._clearRevertTimer();
      }
      onClick();
    });
    btn.addEventListener("mouseenter", () => {
      this._isOverButton = true;
      this._clearRevertTimer();
    });
    btn.addEventListener("mouseleave", () => {
      this._isOverButton = false;
      if (this._pinned) return;
      this._scheduleRevert();
    });
    return btn;
  }

  _recalculateSectors = () => {
    const el = this._scrollContainer;
    if (!el || el.clientWidth === 0) return;

    const maxScroll = el.scrollWidth - el.clientWidth;
    const prevSector = this._currentSector;
    const prevTotal = this._totalSectors;
    this._totalSectors = maxScroll > 1 ? Math.ceil(el.scrollWidth / el.clientWidth) : 1;

    if (this._currentSector > this._totalSectors - 1) {
      this._currentSector = Math.max(this._totalSectors - 1, 0);
    }
    if (prevSector !== this._currentSector || prevTotal !== this._totalSectors) {
      console.log("[MD_DEBUG][recalculateSectors] CHANGED", {
        scrollLeft: el.scrollLeft, clientWidth: el.clientWidth, scrollWidth: el.scrollWidth, maxScroll,
        prevSector, newSector: this._currentSector, prevTotal, newTotal: this._totalSectors
      });
    }
    this._updateButtonsVisibility();
    this._updateButtonsPosition();
    this._emitScrollState();
  };

  _handlePageScroll = () => {
    if (this._rafId) return;
    this._rafId = window.requestAnimationFrame(() => {
      this._rafId = null;
      this._updateButtonsPosition();
    });
  };

  _handleRowHover = (event) => {
    const row = event.target.closest("tbody tr");
    if (!row || row === this._hoveredRowEl) return;
    this._pinned = false;
    this._clearRevertTimer();
    this._hoveredRowEl = row;
    this._updateButtonsPosition();
  };

  _handleRowLeave = () => {
    if (!this._hoveredRowEl || this._pinned) return;
    this._scheduleRevert();
  };

  _scheduleRevert() {
    if (this._pinned) return;
    this._clearRevertTimer();
    this._revertTimer = setTimeout(() => {
      this._revertTimer = null;
      if (this._isOverButton) return;
      this._hoveredRowEl = null;
      this._updateButtonsPosition();
    }, 600);
  }

  _clearRevertTimer() {
    if (this._revertTimer) {
      clearTimeout(this._revertTimer);
      this._revertTimer = null;
    }
  }

  _updateButtonsPosition() {
    if (this._isOverButton) return;
    if (!this._outerContainer || (!this._leftBtn && !this._rightBtn)) return;

    const rect = this._outerContainer.getBoundingClientRect();
    const viewportWidth = window.innerWidth;
    const viewportHeight = window.innerHeight;
    const refBtn = this._leftBtn || this._rightBtn;
    const btnHeight = refBtn.offsetHeight || 48;
    const margin = 12;
    const minY = rect.top + btnHeight / 2 + margin;
    const maxY = rect.bottom - btnHeight / 2 - margin;
    const visible = rect.bottom > 0 && rect.top < viewportHeight && maxY >= minY;

    if (!visible) {
      // console.log("[MD_DEBUG][position] HIDDEN by vertical gate", { rectTop: rect.top, rectBottom: rect.bottom, viewportHeight, minY, maxY });
      if (this._leftBtn) this._leftBtn.style.visibility = "hidden";
      if (this._rightBtn) this._rightBtn.style.visibility = "hidden";
      return;
    }

    let desiredCenter = viewportHeight / 2;
    if (this._hoveredRowEl && this._hoveredRowEl.isConnected) {
      const rowRect = this._hoveredRowEl.getBoundingClientRect();
      desiredCenter = (rowRect.top + rowRect.bottom) / 2;
    }
    const targetY = Math.min(Math.max(desiredCenter, minY), maxY);

    if (this._leftBtn) {
      if (this._leftBtn.offsetWidth) {
        this._leftBtnWidth = this._leftBtn.offsetWidth;
      }
      const leftBtnWidth = this._leftBtnWidth || 0;
      const targetX = Math.min(Math.max(rect.left + 6, margin), viewportWidth - leftBtnWidth - margin);
      this._leftBtn.style.visibility = "visible";
      this._leftBtn.style.top = `${targetY}px`;
      this._leftBtn.style.left = `${targetX}px`;
    }
    if (this._rightBtn) {
      if (this._rightBtn.offsetWidth) {
        this._rightBtnWidth = this._rightBtn.offsetWidth;
      }
      const rightBtnWidth = this._rightBtnWidth || 0;
      const targetX = Math.min(Math.max(rect.right - rightBtnWidth - 6, margin), viewportWidth - rightBtnWidth - margin);
      this._rightBtn.style.visibility = "visible";
      this._rightBtn.style.top = `${targetY}px`;
      this._rightBtn.style.left = `${targetX}px`;
    }

    // console.log("[MD_DEBUG][position] applied", {
    //   currentSector: this._currentSector,
    //   totalSectors: this._totalSectors,
    //   leftDisplay: this._leftBtn && this._leftBtn.style.display,
    //   leftLeft: this._leftBtn && this._leftBtn.style.left,
    //   leftVisibility: this._leftBtn && this._leftBtn.style.visibility,
    //   rightDisplay: this._rightBtn && this._rightBtn.style.display,
    //   rightLeft: this._rightBtn && this._rightBtn.style.left,
    //   rightVisibility: this._rightBtn && this._rightBtn.style.visibility
    // });
  }

  _handleManualScroll = () => {
    const el = this._scrollContainer;
    if (!el || el.clientWidth === 0) return;

    const maxScroll = el.scrollWidth - el.clientWidth;
    const EDGE_TOLERANCE_PX = 4;

    if (el.scrollLeft <= EDGE_TOLERANCE_PX) {
      this._currentSector = 0;
    } else if (el.scrollLeft >= maxScroll - EDGE_TOLERANCE_PX) {
      this._currentSector = this._totalSectors - 1;
    } else {
      this._currentSector = Math.round(el.scrollLeft / el.clientWidth);
    }

    this._updateButtonsVisibility();
    this._updateButtonsPosition();
    this._emitScrollState();
  };

  _updateButtonsVisibility() {
    if (this._leftBtn) {
      this._leftBtn.style.display = this._currentSector > 0 ? "flex" : "none";
    }
    if (this._rightBtn) {
      this._rightBtn.style.display = this._currentSector < this._totalSectors - 1 ? "flex" : "none";
    }
  }

  _emitScrollState() {
    this.dispatchEvent(
      new CustomEvent("scrollstate", {
        detail: {
          currentSector: this._currentSector,
          totalSectors: this._totalSectors,
          canScrollLeft: this._currentSector > 0,
          canScrollRight: this._currentSector < this._totalSectors - 1
        }
      })
    );
  }

  @api
  scrollToSector(direction) {
    const el = this._scrollContainer;
    if (!el) return;

    const next = Math.min(Math.max(this._currentSector + direction, 0), this._totalSectors - 1);
    this._currentSector = next;
    const maxScroll = el.scrollWidth - el.clientWidth;
    const target = Math.min(next * el.clientWidth, maxScroll);
    el.scrollTo({ left: target, behavior: "smooth" });
    this._updateButtonsVisibility();
    this._updateButtonsPosition();
    this._emitScrollState();
  }
}