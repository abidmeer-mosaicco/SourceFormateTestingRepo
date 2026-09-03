/**
* @description       : Wrapper for fetching Rebate Management
* @author            : @Krishan Jangir
* @Created on        : 11-02-2023
* @last modified by  : Rohan Undale
* @last modified date: 11-04-2023
**/
public class PMC_DH_RebateManagementWrapper{
        /**
     * * @description Sales Agreement Summary Wrapper
     * * @return PMC_DH_SalesAgreementSummaryWrapper
     * */
    @AuraEnabled
    public PMC_DH_SalesAgreementSummaryWrapper objSalesAgreementSummaryWrapper { get; set; }
    /**
     * * @description List of Individual data
     * * @return List<RebateData>
     * */
	@AuraEnabled
    public List<RebateData> lstIndividualData { get; set; }
    /**
     * * @description List of IPortfolio Data
     * * @return List<RebateData>
     * */
	@AuraEnabled
	public List<RebateData> lstPortfolioData { get; set; }
    /**
     * * @description List of Growth Data
     * * @return List<RebateData>
     * */
	@AuraEnabled
    public List<RebateData> lstGrowthData { get; set; }
    /**
     * * @description List of Growth Data
     * * @return List<RebateData>
     * */
	@AuraEnabled
    public List<RebateData> lstCultivar { get; set; }
    /**
     * * @description List of Growth Data
     * * @return List<RebateData>
     * */
	@AuraEnabled
    public List<RebateData> lstRawMaterials { get; set; }
    /**
     * * @description List of Growth Data
     * * @return List<RebateData>
     * */
	@AuraEnabled
    public List<RebateData> lstBlendedProducts { get; set; }
    /**
    * @description Status Code and message
    * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
    */
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    /*************************************************************************
    * @method Name  : Wrapper class Individual Data
    * @description  : Method to Individual Data details
    *****************************************************************************/
    public class RebateData{
        /**
         * * @description Product Name
         * * @return String
         * */    
        @AuraEnabled
        public String strProductName { get; set; }
        /**
         * * @description UOM
         * * @return String
         * */    
        @AuraEnabled
        public String strUOM { get; set; }
         /**
         * * @description Invoiced Qty
         * * @return Integer
         * */ 
        @AuraEnabled
        public Integer intInvoicedQty { get; set; }
        /**
         * * @description Tons Remaining for Next target
         * * @return Decimal
         * */    
        @AuraEnabled
        public Decimal decTonsRemForNextTarget { get; set; }
        /**
         * * @description Accumulated Rebates To Date
         * * @return Decimal
         * */ 
        @AuraEnabled
        public Decimal decAccumulatedRebatesToDate { get; set; }
        /**
         * * @description Tiers Data list
         * * @return List<PMC_DH_TiersDataWrapper>
         * */     
        @AuraEnabled
        public List<PMC_DH_TiersDataWrapper> lstTiers { get; set; }
    }

    /**
    * @description       : Wrapper for fetching Sales Agreement Summary
    * @author            : Rohan Undale
    * @Created on        : 11-04-2023
    **/
    public class PMC_DH_SalesAgreementSummaryWrapper{
        /**
         * * @description Rebate Name
         * * @return String
         * */
        @AuraEnabled
        public String strRebateProgramName { get; set; }
        /**
         * * @description Start Date
         * * @return Date
         * */
        @AuraEnabled
        public Date datStartDate { get; set; }
        /**
         * * @description End Date
         * * @return Date
         * */
        @AuraEnabled
        public Date datEndDate { get; set; }
        /**
         * * @description Sales Agreement Name
         * * @return String
         * */
        @AuraEnabled
        public String strSalesAgreementName { get; set; }
    }

    /**
    * @description       : Wrapper for Tiers data
    * @author            : Rohan Undale
    * @Created on        : 11-04-2023
    **/
    public class PMC_DH_TiersDataWrapper{
        /**
         ** @description Tier start limit
            ** @return Decimal
            **/
        @AuraEnabled
        public Decimal decTierStartLimit { get; set; }
        /**
         ** @description Individual Incentive
            ** @return Decimal
            **/
        @AuraEnabled
        public Decimal decIndividualIncentive { get; set; }
        /**
         ** @description Projected Incentive
            ** @return Decimal
            **/
        @AuraEnabled
        public Decimal decProjectedIncentive { get; set; }
    }
}