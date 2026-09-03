/**
* @description : This class will be used to maintain static variables that will be used in the classes for sales & service teams.
* @author Kailas Shimpi
* @storynumber GDASF-2511
* */
public class PMC_SS_ConstantClass {
    //Variable to cover the exception part
    @testVisible
    private Boolean boolTestSetup = false;    
    public final static string YES = 'Yes';
    public final static string NO = 'No';
    public final static String PUT = 'PUT';
    public final static String POST = 'POST'; 
    public final static String COMMENTS = 'Comments';
    public final static String CASETYPE_OTHER = 'Other';
    public final static String QUEUE = 'Queue';
    public final static String QUEUE_DEVNAME = 'PMC_SS_Quality';
    public final static String BILLINGQUEUE_DEVNAME = 'PMC_SS_Billing';  
    public final static String NATIONAL_DIRECTOR = 'National Director';   
    public final static String REGIONAL_DIRECTOR = 'Regional Director';   
    public final static String SEGMENT_MANAGER = 'Segment Manager';   
    public final static Integer THOUSAND = 1000; 
    public final static Integer ONEMILLION =1000000;
    public final static String DH_PROFILE = 'Digital Hub';
    public final static String SYSADMIN_PROFILE = 'System Administrator';
    public final static String SRVUSER_PROFILE = 'Service User';//added for GSMD-1096
    public final static String ONLINE_STATUS = 'Online';
    public final static String DRAFT_STATUS = 'Draft';
    public final static String TECHBULLETIN_RECORDTYPE = 'PMC_SS_TechnicalBulletinNotice';
    public final static String TECHBULLETIN_DEFAULTNEWS = 'PMC_SS_DefaultNewsAndAnnouncement';
    
    public final static string OPPORTUNITY_PROSPECTING_STAGE = 'Prospecting';
	public final static string OPPORTUNITY_ANALYSIS_STAGE = 'Analysis';
    public final static string OPPORTUNITY_PROPOSAL_STAGE = 'Proposal';
    public final static string OPPORTUNITY_FINALIZE_QUOTE_STAGE = 'Finalize Quote';
    public final static string OPPORTUNITY_CLOSED_WON_STAGE = 'Closed Won';
    public final static string OPPORTUNITY_CLOSED_LOST_STAGE = 'Closed Lost';   
    //Adding for GDASF-6734
    public final static String OPPORTUNITY_FORECAST_CATEGORY_PIPELINE = 'Pipeline';
    public final static String LEAD_STATUS_LOST = 'Lost';
    public final static String LEAD_STATUS_NEW = 'New';
    public final static String LEAD_STATUS_MARKETING_QUALIFIED = 'Marketing Qualified';
    public final static String LEAD_STATUS_SALES_ACCEPTED = 'Sales Accepted';
    public final static String LEAD_STATUS_SALES_CONTACTED = 'Sales Contacted';
    public final static String LEAD_STATUS_SALES_QUALIFIED = 'Sales Qualified';
    public final static String LEAD_STATUS_CONVERTED = 'Converted';

    public final static String DUPLICATE_LEAD_OPPORTUNITY_NAME = 'Opportunity from Lead';

     //Adding for GDASF-1941
    public final static String OTHER = 'Other';
    public final static String RE_OPEN = 'Re-Open';
    public final static String CLOSED = 'Closed';
    public final static String AUTOAPPROVED = 'Auto Approved';
    public final static String CLOSUREPENDING = 'Closure Pending';
    public final static String ESCALATED = 'Escalated';
    public final static String LOW = 'Low';
    public final static String MEDIUM = 'Medium';
    public final static String HIGH = 'High';
    public final static String TEST_SUBJECT = 'Test Subject';
    public final static String PMC_SS_CUSTOM_PUSH_NOTIFICATION = 'PMC_SS_CustomPushNotification';
    public final static long RE_OPEN_DATE_FORMULA = 28 * 9 * 3600000;
    public final static String DEFAULT_BUSINESS_HOUR_CONDITION = 'isDefault = True AND IsActive = True';
    public final static String INTERNAL = 'Internal';
    public final static String MDM_VERIFICATION = 'MDM Verification';
    public final static String MODE_OF_TRANSPORTATION = 'Mode of transportation';
    public final static String RAIL = 'Rail';
    public final static String NA_REGION = 'North America';
    public final static String BR_REGION = 'Brazil';
    public final static String USERLANGUAGE_PT= 'pt_BR';
    public final static String MDM_CASE_SUBJECT= 'Review Edit of';
    
    public final static String STATIC_URL= '/sfc/servlet.shepherd/version/download/';
    // Adding GLPA-1134 - Start
    public static final string MISKI_MAYO_MESA_DE_PARTES_PROFILE = 'Customer Community Plus User Miski Mayo Mesa de Partes';
    public static final string MESA_DE_PARTES_PROFILE = 'Mesa de Partes Profile';
    // Adding GLPA-1134 - End



	 
    //Adding for GDASF-8478
    public final static String ACCOUNT_ID_SEGMENTATION_CONDITION = '(Id IN: setId OR Id IN: setIdFromContact) AND PMC_SS_Segmentation__c != Null';
   
    //Adding for GDASF-7712
    public final static String SALES_AGREEMENT_STATUS_DRAFT = 'Draft';
    public final static String SALES_AGREEMENT_SCHEDULEFREQUENCY_WEEKLY = 'Weekly';
    public final static String SALES_AGREEMENT_SCHEDULEFREQUENCY_MONTHLY = 'Monthly';
    public final static String SALES_AGREEMENT_CURRENCYISOCODE_USD = 'USD';
    public final static String SALES_AGREEMENT_PRODUCTLEVEL_PRODUCT = 'Product';
    
    //Adding for GDASF-10431
     public final static String SALES_AGREEMENT_SCHEDULEFREQUENCY_YEARLY = 'Yearly';
     public final static String SALES_AGREEMENT_ACTUALSCALCULATIONMODE_MANUAL = 'Manual';

    
    //Adding for GDASF-8094
    public final static String RETAIL_USER_PSG_DEVELOPER_NAME = 'PMC_DH_Buyer_Permission_Set_Group';
    public final static String OPPORTUNITY_TYPE_INDIRECT_SALES = 'Indirect Sales';
    public final static String OPPORTUNITY_TYPE_DIRECT_SALES = 'Direct Sales';

    //Adding for GDASF-8667
    public final static String WEB = 'Web';

    //Adding for GDASF-6328
    public final static String  CASE_ORIGIN_EMAIL= 'Email';

    
    // Adding for GDASF-2182
    public final static String  ARTICLE_REQUEST= 'Article Request';

    //Adding for GDASF-7257
    public final static String OPPORTUNITY_SOURCE_WEB = 'Web';
    public final static String PRICE_CHECK_OPPORTUNITY_NAME_SUBSTRING = 'Price Check for ';
    
    //Adding for GDASF-2507
    public final static String DH_BUYER_PROFILE = 'Digital Hub Buyer';
    public final static String DH_SUPERBUYER_PROFILE = 'Digital Hub Super Buyer';
    
    //Adding for GDASF-2092
    public final static String TEMPLATE_NAME_LEAD_REVIEW = 'PMC_SS_RetailerLeadReviewEmailTemplate';
    public final static String EMAIL_EXCEPTION_MESSAGE = 'Send Email failed due to some error. Please Contact System Administrator.';

    //Adding for GDASF-2127
    public final static String PORTAL_USER_PROFILE = 'Digital';
    public final static String USER_ID_CODE = '005';
    public final static String NEW_LEAD = 'A new Lead';
    public final static String ASSIGNED_TO = 'is assigned to you.';
    public final static String TAKE_ACTION = 'Please take appropriate action on the Lead.';

    //Adding for GDASF-8960, GDASF-8962, GDASF-8963
    public final static String CANCEL = 'Cancel';
    public final static String REBILL = 'Rebill';
    public final static String CREDIT = 'Credit';
    public final static String DEBIT = 'Debit';
    public final static String ACTIONRETURN= 'Return';
    public final static String REVERSESHIPMENT = 'Reverse Shipment';
    public final static String FINAL_APPROVED = 'Final Approved';
    public final static String AUTO_APPROVED = 'Auto Approved';

    //Adding for GDASF-1065
    public static final String STRING_AGENT_ACCOUNT_RECORDTYPE_NAME = 'PMC_SS_Agent';
    
    //Adding for GDASF-10391
    public static final String NEW_LEADS_QUEUE = 'New Leads';
    
    //Adding for GDASF-11118
    public static final String CASE_TYPE_TRANSACTIONS = 'Transactions';
    public static final String ISSUE_REASON_AMENDMENT = 'Amendment';
    public static final String CASE_TYPE_TECHNICAL = 'Technical';
	public static final String CONTRACT_AMENDMENT_TYPE_DUE_DATE = 'Due Date';

    //Adding For GDASF-13190
    public static final String ISSUE_REASON_ARTICLE_REQ = 'Article Request';
    
    //Adding for GDASF-12754
    public static final String DH_BUYER_PROFILE_NAME = 'Digital Hub Buyer';
	public static final String DH_SUPER_BUYER_PROFILE_NAME = 'Digital Hub Super Buyer';
    
    //Adding for GDASF-11116
    public static final String UNAPPROVED_CREDIT_LIMIT = 'Unapproved Credit Limit';
    public static final String MOSAICS_FAILURE = 'Mosaic’s Failure';
    //Adding for GDASF-14663
    public static final String ENTITLEMENT_PROCESS_NAME = 'Case Entitlement Process';
    //Adding for GDASF-14672
    public static final String TEAM_MEMBER_ROLE_SDR = 'Sales Development Representative';
    public static final String TEAM_MEMBER_ACCESS_LEVEL_READ = 'Read';
    public static final String TEAM_MEMBER_ACCESS_LEVEL_EDIT = 'Edit';
    public static final String SDR_NA_SALES_TEAM_ROLE = 'NA Sales Team';
    public static final String SDR_SA_B2B_SALES_TEAM_ROLE = 'SA B2B Sales Team';
    public static final String SDR_SA_B2C_SALES_TEAM_ROLE = 'SA B2C Sales Team';
    //Adding for GDASF-16536
    public static final string INVOICE='Invoice';
    public static final string INVOICE_ADJUSTMENTS='Invoice Adjustments';
    //Adding for GDASF-20387
    public static final string MASTER_DATA_TEAM_QUEUE='PMC_SS_MasterDataTeam';
    public static final string STRING_INTERFACE_NAME='Service Now Interface';
    //Adding for GDASF-20100
    public static final string NA_MASTER_DATA_TEAM_QUEUE='PMC_SS_NAMasterDataTeam';
    public static final string SA_MASTER_DATA_TEAM_QUEUE='PMC_SS_SAMasterDataTeam';
    //adding for GDASF-21353
    public static final string WAITING_FOR_MASTER_DATA_MANAGEMENT='Waiting for Master Data Management';
    public static final string WAITING_FOR_PRODUCT_FORM_COMPLETION='Waiting for Product Form Completion';
    public static final string WAITING_FOR_PRODUCT_CREATION_ASSIGNMENT='Waiting for Product Routing Creation and Assignment';
    public static final string WAITING_FOR_PRODUCT_COSTING_SETUP='Waiting for Product Costing Setup';
    public static final string PRODUCT_REQUEST='Product Request';
    public static final string SA_GTM_QUEUE='PMC_SS_SAMasterDataGTM';
    public static final string KNOWLEDGE_CREATOR_QUEUE='PMC_SS_KnowledgeCreator';
    public static final string GTM_QUEUE='PMC_SS_GTMQueue';
    public static final string PRODUCT_QUEUE='PMC_SS_Product';
    public static final string REBATE_ISSUE_REASON='Rebate';
    public static final string INCORRECT_PRODUCT_ISSUE_REASON='Incorrect Product';
    
    
    //Adding for GDASF - 21937
    public static final string To_Address_India = 'india_productdatarequests@mosaicco.com';
    public static final string To_Address_China = 'china_productdatarequests@mosaicco.com';
    public static final string MASTER_DATA_QUEUE= 'PMC_SS_MasterDataTeam';
    
    //Adding for GDASF-15480
    public static final String STAT_BASELINE_NOTIFICATION_TITLE = 'Statistical Baseline Forecast has been updated. Please review your Current Sales Plan.';
  	public static final List<String> LSTIMAGETYPES = new List<String>{'PNG','JPEG','JPG','jpeg','png','jpg'};
    public static final Set<String> SSR_ROLES = new Set<String>{'NA Customer Service Lead','NA Sales Service Analyst (SSA)','NA Sales Service Representative (SSR)','NA Rebates','Commissions Analyst'};    
    
    //Adding for GSMD-4950
    public static final String FIRST_CONTACT = 'First Contact';
    public static final List<String> SLA_MILESTONES = new List<String>{'SLA - 1 day','SLA - 2 days','SLA - 2 hours','SLA - 3 days','SLA - 5 days','SLA - 7 days'};
    //Ending for GSMD-4950    
        
    //Adding for Rebate 
    private static final String GROWTH_TYPE = 'ZRS3'; //'Growth';
    /**
      * @description This is constructor for PMC_SS_ConstantClass.
     */
    public PMC_SS_ConstantClass()
    {
        if(Test.isRunningTest())
        {
             boolTestSetup =true;
        }
    } 
}