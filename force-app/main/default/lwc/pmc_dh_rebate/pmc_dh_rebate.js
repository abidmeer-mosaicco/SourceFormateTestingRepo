import { LightningElement, track } from "lwc";
import pmc_brandingStaticResource from "@salesforce/resourceUrl/pmc_brandingStaticResource";
import pmc_rebates_rebateProgramSummary from "@salesforce/label/c.pmc_rebates_rebateProgramSummary";
import pmc_rebates_rebateProgramName from "@salesforce/label/c.pmc_rebates_rebateProgramName";
import pmc_rebates_validityPeriod from "@salesforce/label/c.pmc_rebates_validityPeriod";
import pmc_rebates_salesAgreement from "@salesforce/label/c.pmc_rebates_salesAgreement";
import pmc_rebates_rebateProgram from "@salesforce/label/c.pmc_rebates_rebateProgram";
import pmc_addresses_apply from "@salesforce/label/c.pmc_addresses_apply";
import pmc_addresses_clear from "@salesforce/label/c.pmc_addresses_clear";
import pmc_rebates_individual from "@salesforce/label/c.pmc_rebates_individual";
import pmc_rebates_portfolio from "@salesforce/label/c.pmc_rebates_portfolio";
import pmc_rebates_growth from "@salesforce/label/c.pmc_rebates_growth";
import pmc_contractDetails_products from "@salesforce/label/c.pmc_contractDetails_products";
import pmc_rebates_invoicedQty from "@salesforce/label/c.pmc_rebates_invoicedQty";
import pmc_rebates_remainingForNextTarget from "@salesforce/label/c.pmc_rebates_remainingForNextTarget";
import pmc_rebates_accumulatedRebatesToDate from "@salesforce/label/c.pmc_rebates_accumulatedRebatesToDate";
import pmc_rebates_tiers from "@salesforce/label/c.pmc_rebates_tiers";
import pmc_rebates_individualIncentives from "@salesforce/label/c.pmc_rebates_individualIncentives";
import pmc_rebates_portfolioIncentives from "@salesforce/label/c.pmc_rebates_portfolioIncentives";
import pmc_rebates_growthIncentives from "@salesforce/label/c.pmc_rebates_growthIncentives";
import pmc_rebates_projectedIncentives from "@salesforce/label/c.pmc_rebates_projectedIncentives";
import pmc_rebates_cultivar from "@salesforce/label/c.pmc_rebates_cultivar";
import pmc_rebates_rawMaterials from "@salesforce/label/c.pmc_rebates_rawMaterials";
import pmc_rebates_blendedProducts from "@salesforce/label/c.pmc_rebates_blendedProducts";
import pmc_rebates_goToCultivar from "@salesforce/label/c.pmc_rebates_goToCultivar";
import pmc_rebates_cultivarMsg from "@salesforce/label/c.pmc_rebates_cultivarMsg";
import pmc_rebates_rebatesProgram from "@salesforce/label/c.pmc_rebates_rebatesProgram";
import PMC_DH_CultivarRebatesBR from "@salesforce/label/c.PMC_DH_CultivarRebatesBR";
import { formatLabel, formatDate, isBrazilRegion, toastMessageHandler } from "c/pmc_dh_utilityJs";
import getRebateDetails from "@salesforce/apex/PMC_DH_RebateManagementController.getRebateDetails";
import getListOfRebateProgramOptions from "@salesforce/apex/PMC_DH_RebateManagementController.getListOfRebateProgramOptions";

/**
 * A custom LWC to display Rebates.
 * @alias Pmc_dh_rebate
 * @extends LightningElement
 * @hideconstructor
 * @author Venkata Sai Mouli, Agastya
 * @example
 * <c-pmc_dh_rebate></c-pmc_dh_rebate>
 */

const tiersHeightPerRow = 34;

export default class Pmc_dh_rebate extends LightningElement {
  iconUrl = `${pmc_brandingStaticResource}/icons/icon-info.svg`;
  @track labels = {
    pmc_rebates_rebateProgramSummary,
    pmc_rebates_rebateProgramName,
    pmc_rebates_validityPeriod,
    pmc_rebates_salesAgreement,
    pmc_rebates_rebateProgram,
    pmc_addresses_apply,
    pmc_addresses_clear,
    pmc_contractDetails_products,
    pmc_rebates_invoicedQty,
    pmc_rebates_remainingForNextTarget,
    pmc_rebates_accumulatedRebatesToDate,
    pmc_rebates_tiers,
    pmc_rebates_individualIncentives,
    pmc_rebates_portfolioIncentives,
    pmc_rebates_growthIncentives,
    pmc_rebates_projectedIncentives,
    pmc_rebates_goToCultivar,
    pmc_rebates_cultivarMsg,
    pmc_rebates_rebatesProgram,
    PMC_DH_CultivarRebatesBR,
    northAmericaTabs: [
      {
        tabName: pmc_rebates_individual,
        tabClass: "menu-list individual dynamic-border",
        tabArrayName: "lstIndividualData"
      },
      {
        tabName: pmc_rebates_portfolio,
        tabClass: "menu-list portfolio",
        tabArrayName: "lstPortfolioData"
      },
      {
        tabName: pmc_rebates_growth,
        tabClass: "menu-list growth",
        tabArrayName: "lstGrowthData"
      }
    ],
    brazilTabs: [
      {
        tabName: pmc_rebates_cultivar,
        tabClass: "menu-list cultivar dynamic-border",
        tabArrayName: "lstCultivar"
      },
      {
        tabName: pmc_rebates_rawMaterials,
        tabClass: "menu-list rawMaterials",
        tabArrayName: "lstRawMaterials"
      },
      {
        tabName: pmc_rebates_blendedProducts,
        tabClass: "menu-list blendedProducts",
        tabArrayName: "lstBlendedProducts"
      }
    ]
  };
  rebatesProgramOptions = [];
  selectedRebatesProgram = "";

  @track rebatesData = {};

  @track filteredData = [];
  @track activeTabData = [];
  recordsPerPage = 4;
  isIndividualTab = false;
  isPortfolioTab = false;
  isGrowthTab = false;

  isCultivar = false;
  rawMaterials = false;
  blendedProducts = false;

  showTonsRemaining = false;
  showAccumulatedRebates = false;
  isBrazil = false;
  tabsDisplayed = [];

  validityPeriod = "";
  effAccId = "";
  highlightedTab = "";
  isSpinner = true;
  pageLoaded = false;

  /**
   * Lifecycle Hook
   */
  connectedCallback() {
    this.isBrazil = isBrazilRegion();
    if (sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID")) {
      this.effAccId = localStorage.getItem("EFFECTIVE_ACCOUNT_ID") ? localStorage.getItem("EFFECTIVE_ACCOUNT_ID") : sessionStorage.getItem("EFFECTIVE_ACCOUNT_ID");
    }

    const promise1 = new Promise((resolve, reject) => {
      getListOfRebateProgramOptions({
        strEffectiveAccId: this.effAccId
      })
        .then((response) => {
          if (response && Object.keys(response).length) {
            if (JSON.parse(JSON.stringify(response)).statusCodeMessage?.strStatusMessage) {
              toastMessageHandler(JSON.parse(JSON.stringify(response)).statusCodeMessage.strStatusMessage)
            }
            if (response.lstRebateProgramOptions && response.lstRebateProgramOptions.length) {
              this.rebatesProgramOptions = response.lstRebateProgramOptions;
              this.selectedRebatesProgram = this.rebatesProgramOptions[0].value;
            }
          }
          resolve();
        }).catch((error) => {
          reject(error)
        });
    })

    const promise2 = new Promise((resolve, reject) => {
      try {
        this.getRebatesData();
        resolve();
      } catch (error) {
        reject(error);
      }
    })

    const allPromise = Promise.all([promise1, promise2]);
    allPromise.then(() => {
      this.isSpinner = false;
      this.pageLoaded = true;
    })
      .catch(() => {
        toastMessageHandler();
        this.isSpinner = false;
        this.pageLoaded = true;
      });
  }

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    this.highlightTab();
    if (this.activeTabData) {
      this.activeTabData.forEach((item, index) => {
        item.heightClassRow = `dynamic-height${index}`;
        item.dynamicHeight = item.lstTiers ? (item.lstTiers.length * tiersHeightPerRow) : 0;
        this.template.querySelectorAll(`[data-id="${item.heightClassRow}"]`).forEach(element => {
          element.style.height = `${item.dynamicHeight}px`;
        })
      })
    }
  }

  /**
   * Fetches rebates data
   * @function getRebatesData
   */
  getRebatesData() {
    getRebateDetails({
      strRebateProgramId: this.selectedRebatesProgram,
      strEffectiveAccId: this.effAccId
    })
      .then((response) => {
        if (response && Object.keys(response).length) {
          if (JSON.parse(JSON.stringify(response)).statusCodeMessage?.strStatusMessage) {
            toastMessageHandler(JSON.parse(JSON.stringify(response)).statusCodeMessage.strStatusMessage)
          }
          this.rebatesData = response;
          this.validityPeriod = `${this.rebatesData.objSalesAgreementSummaryWrapper?.datStartDate} - ${this.rebatesData.objSalesAgreementSummaryWrapper?.datEndDate}`;
          let validityDates = this.validityPeriod.split(" - ");
          let formattedDates = [];
          validityDates.forEach((item) => {
            formattedDates.push(formatDate(item));
          });
          this.validityPeriod = formattedDates.join(" - ");
          this.tabsDisplayed = [];
          let dispTabs = this.isBrazil
            ? this.labels.brazilTabs
            : this.labels.northAmericaTabs;
          dispTabs.forEach((displayTab) => {
            if (
              displayTab.tabArrayName === "lstCultivar" ||
              this.rebatesData[displayTab.tabArrayName]
            ) {
              this.tabsDisplayed.push(displayTab);
            }
          });
          this.highlightedTab = this.tabsDisplayed[0].tabName;
          this.tabChangeHandler({}, this.highlightedTab);
          this.isSpinner = false;
          this.pageLoaded = true;
        }
        else {
          this.tabsDisplayed = [];
          let dispTabs = this.isBrazil
            ? this.labels.brazilTabs
            : this.labels.northAmericaTabs;
          dispTabs.forEach((displayTab) => {
            if (
              displayTab.tabArrayName === "lstCultivar") {
              this.tabsDisplayed.push(displayTab);
            }
          });
          this.highlightedTab = this.tabsDisplayed[0].tabName;
          this.tabChangeHandler({}, this.highlightedTab);
          this.isSpinner = false;
          this.pageLoaded = true;
        }
      })
      .catch(() => {
        toastMessageHandler();
        this.isSpinner = false;
        this.pageLoaded = true;
      });
  }

  /**
   * Fetch the Concatenated Remaining for Next Target Heading
   * @function fetchUOM
   * @param {Array} actData 
   */
  fetchUOM(actData) {
    if (actData[0]?.invoicedQty) {
      return;
    }
    actData.forEach((item) => {
      item.invoicedQty = item.strUOM
        ? formatLabel(this.labels.pmc_rebates_invoicedQty, [item.strUOM])
        : formatLabel(this.labels.pmc_rebates_invoicedQty, [""]);
    });
  }

  /**
   * Called when user selects a Rebate Program from the dropdown
   * @function handleRebateProgramChange
   * @param {Event} event 
   */
  handleRebateProgramChange(event) {
    this.selectedRebatesProgram = event.detail.value;
  }

  /**
   * Called when user clicks on apply button
   * @function applyHandler
   */
  applyHandler() {
    this.isSpinner = true;
    this.getRebatesData();
  }

  /**
   * Called when user clicks on clear button
   * @function clearHandler
   */
  clearHandler() {
    this.isSpinner = true;
    if(this.rebatesProgramOptions && this.rebatesProgramOptions.length){
      this.selectedRebatesProgram = this.rebatesProgramOptions[0].value;
    }
    this.getRebatesData();
  }

  /**
   * Called when user changes the tab
   * @function tabChangeHandler
   * @param {Event} event
   * @param {string} displayedTab 
   */
  tabChangeHandler(event, displayedTab) {
    this.highlightedTab = displayedTab
      ? displayedTab
      : event.currentTarget.dataset.name;
    if (this.isBrazil) {
      if (this.highlightedTab === pmc_rebates_cultivar) {
        this.isCultivar = true;
        this.rawMaterials = false;
        this.blendedProducts = false;
        this.activeTabData = [];
      } else if (this.highlightedTab === pmc_rebates_rawMaterials) {
        this.isCultivar = false;
        this.rawMaterials = true;
        this.blendedProducts = false;
        this.activeTabData = [];
      } else if (this.highlightedTab === pmc_rebates_blendedProducts) {
        this.isCultivar = false;
        this.rawMaterials = false;
        this.blendedProducts = true;
        this.activeTabData = [];
      }
    } else {
      if (this.highlightedTab === pmc_rebates_individual) {
        this.isIndividualTab = true;
        this.isPortfolioTab = false;
        this.isGrowthTab = false;
        this.activeTabData = this.rebatesData.lstIndividualData;
      } else if (this.highlightedTab === pmc_rebates_portfolio) {
        this.isIndividualTab = false;
        this.isPortfolioTab = true;
        this.isGrowthTab = false;
        this.activeTabData = this.rebatesData.lstPortfolioData;
      } else if (this.highlightedTab === pmc_rebates_growth) {
        this.isIndividualTab = false;
        this.isPortfolioTab = false;
        this.isGrowthTab = true;
        this.activeTabData = this.rebatesData.lstGrowthData;
      }
    }
    this.tabChanged();
    this.highlightTab();
  }

  /**
   * Highlight the selected tab
   * @function highlightTab
   */
  highlightTab() {
    if (this.isBrazil) {
      let cultivarSelector = this.template.querySelector(".cultivar");
      let rawMaterialsSelector = this.template.querySelector(".rawMaterials");
      let blendedProductsSelector =
        this.template.querySelector(".blendedProducts");
      if (this.isCultivar) {
        cultivarSelector?.classList.add("dynamic-border");
        rawMaterialsSelector?.classList.remove("dynamic-border");
        blendedProductsSelector?.classList.remove("dynamic-border");
      } else if (this.rawMaterials) {
        cultivarSelector?.classList.remove("dynamic-border");
        rawMaterialsSelector?.classList.add("dynamic-border");
        blendedProductsSelector?.classList.remove("dynamic-border");
      } else if (this.blendedProducts) {
        cultivarSelector?.classList.remove("dynamic-border");
        rawMaterialsSelector?.classList.remove("dynamic-border");
        blendedProductsSelector?.classList.add("dynamic-border");
      }
    } else {
      let individualSelector = this.template.querySelector(".individual");
      let portfolioSelector = this.template.querySelector(".portfolio");
      let growthSelector = this.template.querySelector(".growth");
      if (this.isIndividualTab) {
        individualSelector?.classList.add("dynamic-border");
        portfolioSelector?.classList.remove("dynamic-border");
        growthSelector?.classList.remove("dynamic-border");
      } else if (this.isPortfolioTab) {
        individualSelector?.classList.remove("dynamic-border");
        portfolioSelector?.classList.add("dynamic-border");
        growthSelector?.classList.remove("dynamic-border");
      } else if (this.isGrowthTab) {
        individualSelector?.classList.remove("dynamic-border");
        portfolioSelector?.classList.remove("dynamic-border");
        growthSelector?.classList.add("dynamic-border");
      }
    }
  }

  /**
   * Fetch the data related to current open tab
   * @function tabChanged
   */
  tabChanged() {
    this.showTonsRemaining = this.isIndividualTab;
    this.showAccumulatedRebates = !this.isPortfolioTab;
    this.template
      .querySelector("c-pmc_dh_pagination")
      ?.setDataOnSearch(this.activeTabData);
    this.fetchUOM(this.activeTabData);
  }

  /**
   * Updating filtered data to display only current page details
   * @function updatePaginatedData
   * @param {Event} event 
   */
  updatePaginatedData(event) {
    this.filteredData = event.detail;
  }
}