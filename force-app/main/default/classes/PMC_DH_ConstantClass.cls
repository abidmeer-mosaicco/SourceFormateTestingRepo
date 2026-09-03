/**
* @description       : Constant Class for Mosaic Direct Site
* @author            : Mosaic Direct | Dev Team
* @group             : Digital Hub
* @last modified on  : 04-25-2024
* @last modified by  : Hemant Giri Goswami | hegoswami@deloitte.com
**/

public class PMC_DH_ConstantClass {
    
    //Variable to cover the exception part
    @testVisible
    private Boolean boolDHTestSetup = false;

    // Navigation
    public final static String NAVIGATION='DH_Header_Menus1';
    public final static String CART_CUSTOM_PERMISSION='Cart';
    public final static String NAVIGATION_TYPE='Navigation Menu';
    public final static String ACCOUNT_SUBMENU='My Account SubMenu';
    public final static String ACCOUNT_SUBMENUS='DH_Account_Sub_Header_Menus';
    public final static String STOREFRONT_CATEGORIES_MENUNAME='Storefront Categories';
    //public final static String USER_FOOTER_MENU = 'DH_Footer_Menus1'; // not referenced in any class
    public final static String ACC_TAB='My Accounts Tab';
    public final static String CATALOG_NAME='Mosaic Direct Catalog';
    public final static String PRODUCTS_ES='Productos';
    public final static String PRODUCTS_PT_BR='Produtos';


    // technical configurations
    public final static String PRODUCT_TYPE = 'Product'; //  technical configuration
    public final static Double PRODUCT_QUANTITY = 25.00; // technical configuration
    public final static String EDIT_ADDRESS_PERMISSION='DH_Edit_Address'; // technical configuration
    public final static String PMC_DH_SOURCE_SUPERBUYER='Digital Hub - Super Buyer'; //technical configuration
    public final static String GMT_FORMAT='yyyy-MM-dd HH:mm:ss';// technical configuration
    public final static String RELATIVE_URL =  '/sfc/servlet.shepherd/version/download/'; // technical config
    public final static String PRICE_SUMM='PMC_DH_PriceSummaryCountry'; // technical config
    public final static String TASK_SUBJECT = 'New Shipping Address Created from Digital Hub'; // technical config
    public final static String START_TIME = 'T00:00:00+0000'; //technical configuration
    public final static String END_TIME = 'T23:59:59+0000'; // technical configuration
    //public final static String CART_ERROR='Error!'; // technical config // not referenced in any class
    public final static String QUOTE_INAC_MDT='PMC_DH_QuoteInactivationDuration'; // technical config
    public final static long ONE_DAY_IN_SECONDS = 86400; // technical config
    // added by Nikhilesh for GDASF-13298
    public final static String TEMPLATE_NAME_QUOTEREVIEW = 'PMC_DH_YourQuoteRequestIsInReview'; // technical config
    public final static String TEMPLATE_NAME_QUOTEUPDATE = 'PMC_DH_YourQuotePriceQuantityHasBeenUpdated'; // technical config
    public final static String TEMPLATE_NAME_QUOTEACCEPTED = 'PMC_DH_YourQuoteHasBeenAccepted'; // technical config
    //public final static String CONTENT_TYPE='application/pdf'; //technical config // not referenced in any class
    public final static String ORDER_RELATIVE_PATH = 'order/'; // technical config
    public final static String ORDER_NUMBER = '?orderNumber='; // technical config
    public final static String ORDER_ID = '&orderId='; // technical config
    public final static String CONFIG_ORD_LIMIT='PMC_DH_LimitForOrderWidget'; // technical config
    public final static String PRODUCT_API_FIELDS='PRODUCT_API_FIELDS';
    public final static String STANDARD_ORDER_TYPE_CODE = 'ZOR'; // technical config
    public final static String PLP_IMAGE='Product List Image'; // technical config
    public final static String PDP_IMAGE='Product Detail Images'; // technical config
    public final static String DEFAULT_IMAGE='Default Product Image'; // technical config
    public final static String DELIMITER='-';
    public final static String CONFIG_LIMIT_QUOTES='LimitForRecentQuotesWidget'; // technical config
    public final static String CONFIG_LIMIT_CONTR='LimitForActiveContractWidget'; // technical config
    public final static String URL_CONTR='ContractUrl'; // technical configs
    public final static String ORDER_TYPE_CODES='ORDER_TYPE_CODES';
    public final static String MOT_FOR_CPT='MOT_FOR_CPT';
    //duplicate constants
    public final static String CASE_CLOSED='Closed';
   // public final static String CUSTOMER_STATUS = 'Open'; //duplicate for open || SSM not using this
    public final static String OPEN = 'Open'; //duplicate for open
    //public final static String  CASE_ORIGIN_EMAIL= 'Email'; // duplicate for email // not referenced in any class
    public final static String USER_NOTIFICATION_PREFERENCE_EMAIL='Email'; // duplicate for email 
    public final static string CONTRACTNUM=' DOC-'; // duplicate for DOC-'
    public final static String DOC_TAG='DOC-'; // duplicate for Doc-
    public final static String REQUEST='Request'; // duplicate for 'Request'
    public final static String QUOTE_STATUS_REQUEST='Request'; // duplicate 'Request'
    public final static String STATUS='Request'; // duplicate for 'Request'
    public final static String ORDER_STATUS_DRAFT = 'Draft'; // duplicate 'Draft'
    public final static String DRAFT='Draft'; // duplicate for 'Draft'
    public final static string RTD='RTD'; // technical config
    public final static string RFQ='RFQ'; // technical config


    // logical implementation 
    public final static String LST_QUOTE_FIELDS='LST_QUOTE_FIELDS';
    // tracking fields
    public final static String LST_QUOTELINE_FIELDS='LST_QUOTELINE_FIELDS';
    public final static String LST_QUOTELINE_FIELDS_NA='LST_QUOTELINE_FIELDS_NA';

    // public final static List<String> STATUS_QUOTEINACTIVE=new List<String>{'Rejected','Expired'}; // not an correct way to handle 
    //public final static List<String> QUOTE_ACTIVESTATUS=new List<String>{'Accepted','Draft','Request','Approved','Presented'}; // not an correct way to handle 
    public final static String CASE_COMMENT_PROFILES='CASE_COMMENT_PROFILES'; 
    public final static String ACTION_PENDING_CONTRACT_PROFILES='ACTION_PENDING_CONTRACT_PROFILES';
    public final static String QUOTE_PROFILES='QUOTE_PROFILES';
    public final static String QUOTE_LINE_HISTORY_FIELDS='QUOTE_LINE_HISTORY_FIELDS';

    
    // can be considered for renaming 
    // general rule of using constant - if my value is General then my constant would be GENERAL='General'; 
    //Avoid using MY_GENERAL,STATUS_GENERAL and same value in such constant leads to duplications
    
    public final static String PRODUCTS_MENUNAME='Products';
    public final static String ACCOUNT_TEAMMEMBERACC='Account Manager'; 
    public final static String ACCOUNT_TEAMMEMBERSSR='Sales Support Representative'; 
    public final static String USER_PROFILE_DH_SUPER_BUYER ='Digital Hub Super Buyer';
    public final static String ACCOUNT_TYPE ='Ship-to';
    //public final static String ACCOUNT_MDM_SYNC_STATUS='Pending'; // can be renamed // not referenced in any class
    public final static String PRODUCT_SUGGESTION_VALUE='aspire';
    public final static String TEST_EXCEPTION_MESSAGE = 'Test Error thrown from PMC_DH_RequestForQuoteController class';
    public final static String TEST_COMMUNITYID = 'ABCD1234'; 
    public final static String PROFILE_NAME='Digital Hub Super Buyer'; // can be removed
    public final static String PMC_DH_APPNAME='Digital Hub'; // can be renamed as digital hub
    public final static String CASE_REOPEN_STATUS='Re-Open'; // can be renamed
    public final static String CLOSED='Closed';
    public final static String MULTIPLE_STR='Multiple'; // can be renamed 
    public final static String SUCCESS_STATUS_CODE='000'; // can be renamed
    public final static String FAILURE_STATUS_CODE='001';  // can be renamed 
    public final static String ERROR_STATUS_CODE='111';
    public final static String TECHNICAL_ERR_STATUS_CODE='100'; // can be renamed
    public final static String ACCOUNT_INACTIVE_STATUS='Inactive'; // can be renamed
    public final static String ADDRESS_DETAIL='AddressDetail';
    public final static String ALL='All';
    public final static String NEW_LEAD='New'; // can be renamed
    public final static String STATUS_FAILURE='Failure';
    public final static String EXCEPTION_TEST = 'Exception Test';
    public final static String ADDRESS_DELETE = 'DeleteAddress';
    public final static String TASK_PRIOROTY = 'Normal'; // can be renamed
    public final static String CASE_ORIGIN = 'Web';
    public final static String REJECTED='Rejected';
    public final static String PRESENTED='Presented';
    public final static String ADMIN_NAME='Mosaic'; // can be renamed
    public final static String BUYER_PERSONA='Digital Hub Buyer'; // can be renamed
    //public final static String EXTERNAL_USER='Digital Hub System Admin'; // not referenced in any class
    //public final static String SYSTEM_ADMIN='System Administrator'; // not referenced in any class
    public final static String PRODLOC='Product Location';
    public final static String SHIPTO='Ship to'; // added as this field is refernced in conversation-history on Quotedetail page
    public final static String BLANK_STRING='';
    public final static String ORDER_STATUS_PLACED = 'Placed'; // can be renamed
    //public final static String ORDER_TYPE = 'Sales Order'; // not referenced in any class
    public final static String ORDER_SALES_CHANNEL = 'Mosaic Direct'; // can be renamed 
    public final static String FINANCE_MANAGER = 'Digital Hub Finance Manager'; // can be renamed 
    public final static String LOGISTIC_MANAGER = 'Digital Hub Logistics Manager'; // can be renamed 
    public final static String CONTRACT_MANAGER = 'Digital Hub Contract Manager'; /// can be renamed 
    public final static String ORDER_SUMMARY_STATUS = 'Requested'; // can be renamed
    public final static String SAP='SAP';
    //public final static String SHIPPINGTYPE_CPQ='01'; // can be renamed // not referenced in any class
    //public final static String ORDER_REASON='005'; // can be renamed  // not referenced in any class
    public final static String STN='STN'; 
    public final static String ORDER_CONFIRMED='Confirmed'; // can be renamed
    public final static String BRAZIL='Brazil';
    public final static String LEAD_LOST='Lost'; // can be renamed
    public final static String LEAD_REJECT='LeadRejection'; 
    public final static String ACCESS_DENIED='Access Denied';
    public final static String ACTIVE_STATUS='Active'; // can be renamed
    public final static String TASK_SUBJECT_FOR_CONTRACT='Request For Contract Signature'; // can be renamed 
    public final static String TASK_SUBJECT_FOR_ORDER='Request For Call Price'; // can be renamed
    public final static String USER_NOTIFICATION_PREFERENCE_TEXT='Text'; // can be renamed
    public final static String USER_NOTIFICATION_PREFERENCE_WHATSAPP='Whatsapp'; // can be renamed
    public final static String EDIT='Edit';
    public final static String CONTRACT_ACTIVE='Activated';// can be renamed
    public final static String LEGAL_BASIS_QUOTES = 'Quotes'; // can be renamed
    public final static String DATA_USE_PURPOSE_QUOTEREVIEW = 'Ready for Review'; // can be renamed
    public final static String DATA_USE_PURPOSE_QUOTEUPDATE = 'Change in Price/Quantity'; // can be renamed
    public final static String DATA_USE_PURPOSE_QUOTEACCEPTED = 'Accepted by Account Manager'; // can be renamed
    //public final static String DOWNLOAD_ACT='Download'; // can be renamed // not referenced in any class
    //public final static String VIEW_ACT='View'; // can be renamed // not referenced in any class
    public final static String OPPORTUNITY_LOST='OpportunityLost';
    // public final static String MULTIPLE_CONTRACT='Multiple Contracts';
    public final static String SALES_QUALIFIED='Sales Qualified';
    public final static String CLOSED_LOST='Closed Lost';
    public final static String PARTIALLY_SHIPPED='Partially Shipped';  //referenced in homepage for order widget.
    public final static String IN_PROGRESS='In Progress';  //GDASF-21480, referenced in homepage for order widget.
    public final static String STANDARD_ORDER_TYPE = 'Standard Sales Order';  // redundant
    public final static String BOL='BOL';
    public final static String COA='COA';
    public final static String INV='INV';
    public final static String NFE='NFE';
    public final static String UNITEDSTATES='United States';
    public final static String LEAD_MNG='LeadManagement';
    public final static String RETAILER='Retailer';
    public final static String DH_REQUEST='DH Request';
    public final static String END_USR='End-Users';
    public final static String COOPERATIVE_CHNL='Cooperative';
    public final static String SOLD_TO='Sold-To';
    //public final static String DISTRIB='Distributor'; // not referenced in any class
    public final static String SELF_CONSMPT_X='X';
    public final static String IN_ANALYSIS = 'In Analysis';
    public final static String VALIDATED = 'Validated';
    public final static String PRODUCTUPDATE='ProductUpdate';
    public final static String RETAILERS_CHNL='Retailers'; // not referenced in any class
    public final static String CADENCE = 'Cadence';
    public final static String NEW_USER = 'NewUser';
    public final static String USER_INFO = 'UserInfo';
    public final static String ACCEPTED_QUOTE='Accepted';
    public final static String LABEL_HEADER='PMC_DH_'; // not ideal implementations
    public final static String DOMESTIC_NA='Domestic NA';
    public final static String DOMESTIC_SA='Domestic SA';
    public final static String FPD = 'FPD';
    public final static String STATUS_EXPIRED = 'Expired';
    public final static String REJECTION_REASON_OTHERS = 'Other';
    public final static String CANADA='Canada';

    public final static String ORDER_CREATION_SUCCESS_MODULE = 'OrderCreation';
    public final static String FETCH_ORDERS_SUCCESS_MODULE = 'OrderListView';
	public final static String FIXED_DATE = 'Fixed Date';//Added as part of GDASF-19809
    public final static String PREPAYMENT = 'Prepayment';//Added as part of GDASF-19809
    public final static String RECENT_QUOTES_SUCCESS_MODULE = 'GetQuotesSuccess';
    public final static String ACTIVE_CONTRACTS_SUCCESS_MODULE = 'GetContractsSuccess';
    public final static String ORDERS_SUCCESS_MODULE = 'GetOrdersSuccess';
    public final static String RECENT_UPDATES_SUCCESS_MODULE = 'GetRecentUpdates';
    public final static String CART_VALIDATE_SUCCESS_MODULE = 'ValidateCart';
    public final static String DUPLICATE_ACCOUNT_MODULE= 'DuplicateAccount';
    public final static String UPDATED='Updated';
    public final static String ACCESS_DENIED_CODE='999';
    public final static String GETQUOTE_ACESSDENIED='GetQuoteAccessDenied';
    public final static String GETCONTRACT_ACESSDENIED='GetContractAccessDenied';
    public final static String GETORDER_ACESSDENIED='GetOrderAccessDenied';
    public final static String QUOTE_SOBJECT_TYPE='SBQQ__Quote__c';
    public final static String INV_MDT='Invoice'; // getting used in orderlinedetailController to get the mdt record
    
    /**
* @description This is constructor for PMC_DH_ConstantClass.
*/
    public PMC_DH_ConstantClass()
    {
        if(Test.isRunningTest())
        {
            boolDHTestSetup =true;
        }
    } 
    
    
    
}