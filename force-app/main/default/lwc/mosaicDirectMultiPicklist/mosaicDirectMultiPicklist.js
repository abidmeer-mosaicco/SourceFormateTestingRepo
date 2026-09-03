import { LightningElement, api, track } from "lwc";

export default class MosaicDirectMultiPicklist extends LightningElement {
  @api label = "";
  @api placeholder = "Select";

  _options = [];
  _value = [];

  @track isOpen = false;
  @track searchTerm = "";
  @track panelStyle = "";

  _boundDocClick;
  _boundViewportChange;

  @api
  get options() {
    return this._options;
  }

  set options(value) {
    this._options = Array.isArray(value) ? value : [];
  }

  @api
  get value() {
    return this._value;
  }

  set value(value) {
    this._value = Array.isArray(value) ? [...value] : [];
  }

  connectedCallback() {
    this._boundDocClick = this.handleDocumentClick.bind(this);
    this._boundViewportChange = this.handleViewportChange.bind(this);
    document.addEventListener("click", this._boundDocClick);
    window.addEventListener("resize", this._boundViewportChange);
    window.addEventListener("scroll", this._boundViewportChange, true);
  }

  disconnectedCallback() {
    document.removeEventListener("click", this._boundDocClick);
    window.removeEventListener("resize", this._boundViewportChange);
    window.removeEventListener("scroll", this._boundViewportChange, true);
  }

  get displayValue() {
    if (!this._value.length) return this.placeholder;
    if (this._value.length === 1) return this._value[0];
    return `${this._value.length} selected`;
  }

  get filteredOptions() {
    const term = (this.searchTerm || "").toLowerCase();
    const options = this._options || [];

    return options
      .filter((option) => {
        const label = String(option?.label || option?.value || "").toLowerCase();
        return !term || label.includes(term);
      })
      .map((option) => ({
        ...option,
        checked: this._value.includes(option.value)
      }));
  }

  handleToggleDropdown(event) {
    event.stopPropagation();
    this.isOpen = !this.isOpen;
    if (this.isOpen) {
      this.updatePanelPosition();
    }
  }

  handleDocumentClick(event) {
    if (!this.isOpen) return;

    const path = typeof event.composedPath === "function" ? event.composedPath() : [];
    const clickedInside = path.includes(this.template.host) || this.template.contains(event.target);

    if (!clickedInside) {
      this.isOpen = false;
    }
  }

  handleViewportChange() {
    if (!this.isOpen) return;
    this.updatePanelPosition();
  }

  updatePanelPosition() {
    const trigger = this.template.querySelector(".md-multi-trigger");
    if (!trigger) return;

    const rect = trigger.getBoundingClientRect();
    const gap = 4;
    const bottom = Math.max(0, window.innerHeight - rect.top + gap);
    const left = Math.max(0, rect.left);
    const width = Math.max(160, rect.width);

    this.panelStyle = `position: fixed; left: ${left}px; width: ${width}px; bottom: ${bottom}px; z-index: 9999;`;
  }

  handleSearchChange(event) {
    this.searchTerm = (event.target.value || "").trim();
    event.stopPropagation();
  }

  handleOptionChange(event) {
    const optionValue = event.target.dataset.value;
    const checked = event.target.checked;

    let next = [...this._value];
    if (checked) {
      if (!next.includes(optionValue)) next.push(optionValue);
    } else {
      next = next.filter((item) => item !== optionValue);
    }

    this._value = next;
    this.dispatchEvent(
      new CustomEvent("change", {
        detail: { value: [...this._value] }
      })
    );
  }
}