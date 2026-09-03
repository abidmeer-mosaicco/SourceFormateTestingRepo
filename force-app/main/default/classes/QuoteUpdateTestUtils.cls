/**
 * @description This class provides utility methods to create test data for QuoteUpdate* test classes.
 * This class is not a test class itself and should not contain any assertions.
 * 
 * It is only responsible for setting up the necessary data for the tests, such as creating 
 * users, accounts, contacts, quotes, contracts, and related records.
 * 
 * @author Sergio Umlauf
 * @storynumber GCPM-2771
 */
public with sharing class QuoteUpdateTestUtils {
    public static final String ACCOUNT_SAP_ID = '20012345';
    public static final String QUOTE_TYPE = 'Quote';
    public static final String QUOTE_RECORD_SUB_TYPE = 'B2C - Fertilizer';
    public static final String QUOTE_STATUS = 'Accepted';
    public static final String SALES_AREA_COMBINATION = 'Mosaic Fertilizantes do B Domestic Common';
    public static final String SALES_OFFICE = 'BR MT SUL B2C';
    public static final String USER_FIRST_NAME = 'Test John';
    public static final String USER_LAST_NAME = 'Test Doe';
    public static final String USER_ALIAS = 'tDoe';
    public static final String CONTRACT_STATUS = 'Draft';
    public static final String SAP_ORIGINAL_CONTRACT = '0020067890';
    public static final String CONTRACT_DOC_STATUS = 'Accepted';
    public static final String APPROVAL_STATUS = 'Approved';

    /**
     * @description Creates a specified number of sales users with the 'Sales User' profile and returns the list of created users.
     * @param numberOfUsers - The number of sales users to create.
     * @return List of created User records.
     */
    public static List<User> createSalesUsers(Integer numberOfUsers) {
        // Create a test user
        String strSandboxName = UserInfo.getUserName().substringAfterLast('.');
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Sales User'];

        List<User> users = new List<User>();
        String email;
        for (Integer i = 0; i < numberOfUsers; i++) {
            email = String.join(USER_FIRST_NAME.toLowerCase().split(' '), '.') + i + '@mosaicco.com';
            UUID randomUuid = UUID.randomUUID();
            User user = new User();
            user.FirstName = USER_FIRST_NAME;
            user.LastName = USER_LAST_NAME + i;
            user.Alias = USER_ALIAS + i;
            user.Email = email;
            user.Username = email + '.' + strSandboxName + randomUuid.toString();
            user.LanguageLocaleKey = 'pt_BR';
            user.EmailEncodingKey = 'UTF-8';
            user.LocaleSidKey = 'pt_BR';
            user.TimeZoneSidKey = 'America/Sao_Paulo';
            user.FederationIdentifier = 'john.doe' + i + '@mosaicco.com';
            user.MobilePhone = '9999999999';
            user.PMC_CPQ_SalesRegion__c = 'Brazil';
            user.PMC_CPQ_SalesOffice__c = SALES_OFFICE;
            user.ProfileId = profiles[0].Id;
            user.IsActive = true;
            users.add(user);
        }
        insert users;
        return users;
    }

    /**
     * @description Creates a test account with the specified SAP ID and returns the created account.
     * @param sapId - The SAP ID to associate with the created account.
     * @return The created Account record.
     */
    public static Account createAccount() {
        // Create a test account
        Account account = new Account(
            Name = 'Test Account',
            Type = 'Sold-to',
            PMC_SS_AccountExternalID__c = ACCOUNT_SAP_ID,
            PMC_SS_SAPCustomerNumber__c = ACCOUNT_SAP_ID // This is required otherwise PMC_SS_AccountExternalID__c won't be set in "PMC SS Before Insert/Update Account Flow".
        );
        insert account;
        return account;
    }

    /**
     * @description Creates a test contact and returns the created contact.
     * @return The created Contact record.
     */
    public static Contact createContact() {
        // Create a test contact
        Contact testContact = new Contact(FirstName = 'Test Jane', LastName = 'Test Doe');
        insert testContact;
        return testContact;
    }

    /**
     * @description Creates a specified number of quotes with the given parameters and returns the list of created quotes.
     * @param numberOfQuotes - The number of quotes to create.
     * @param account - The Account record to associate with the quotes.
     * @param contact - The Contact record to associate with the quotes.
     * @param users - The list of User records to associate as Account Managers for the quotes.
     * @param quoteType - The SBQQ__Type__c value to set on the quotes.
     * @param quoteStatus - The SBQQ__Status__c value to set on the quotes.
     * @param salesAreaCombination - The sales area combination to set on the quotes.
     * @param salesOffice - The sales office to set on the quotes.
     * @param quoteRecordSubType - The quote record sub type to set on the quotes.
     * @param contractDocStatus - The contract document status to set on the quotes.
     * @param approvalStatus - The approval status to set on the quotes.
     * @param sapContractRef - The SAP contract reference to set on the quotes.
     * @return List of created SBQQ__Quote__c records.
     */
    public static List<SBQQ__Quote__c> createQuotes(
        Integer numberOfQuotes,
        Account account,
        Contact contact,
        List<User> users
    ) {
        // Create a few quotes
        Id recordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('PMC_CPQ_DomesticBR').getRecordTypeId();

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        for (Integer i = 0; i < numberOfQuotes; i++) {
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Account__c = account.Id,
                PMC_CPQ_PrimaryContact__c = contact.Id,
                SBQQ__Type__c = QUOTE_TYPE,
                SBQQ__Status__c = QUOTE_STATUS,
                RecordTypeId = recordTypeId,
                PMC_CPQ_SalesAreaCombination__c = SALES_AREA_COMBINATION,
                PMC_CPQ_SalesOffice__c = SALES_OFFICE,
                PMC_CPQ_AccountManager__c = users[i > 1 ? 1 : i].Id,
                PMC_CPQ_LegacyQuoteID__c = SAP_ORIGINAL_CONTRACT,
                PMC_CPQ_QuoteRecordSubType__c = QUOTE_RECORD_SUB_TYPE,
                PMC_CPQ_ContractStageName__c = CONTRACT_DOC_STATUS,
                PMC_CPQ_ContractStart__c = Date.today(),
                PMC_CPQ_ContractEnd__c = Date.today().addDays(30),
                ApprovalStatus__c = APPROVAL_STATUS,
                PMC_CPQ_SAPContractReference__c = generateRandomSAPContractNumber(),
                PMC_CPQ_Region__c = 'Brazil'
            );
            quotes.add(quote);
        }
        insert quotes;

        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        insert pbe;

        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        for (SBQQ__Quote__c quote : quotes) {
            SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Product__c = product.Id,
                SBQQ__PricebookEntryId__c = pbe.Id,
                SBQQ__Quantity__c = 1,
                SBQQ__NetPrice__c = 100,
                PMC_CPQ_EstFreightPrice__c = 10,
                PMC_CPQ_QuoteRecordType__c = 'Domestic SA',
                PMC_CPQ_QuoteRecordSubType__c = 'B2C - Fertilizer',
                PMC_CPQ_Incoterms1__c = 'CIF'
            );
            quoteLines.add(quoteLine);
        }
        insert quoteLines;

        return quotes;
    }

    /**
     * @description Creates a specified number of contracts associated with the given quotes and account, and returns the list of created contracts.
     * @param quotes - The list of SBQQ__Quote__c records to associate with the contracts.
     * @param account - The Account record to associate with the contracts.
     * @return List of created Contract records.
     */
    public static List<Contract> createContracts(List<SBQQ__Quote__c> quotes, Account account) {
        // Create a few contracts
        List<Contract> contracts = new List<Contract>();
        for (Integer i = 0; i < quotes.size(); i++) {
            Contract c = PMC_DH_TestDataFactoryClass.createContract(quotes[i].Id, account.Id);
            c.StartDate = Date.today().addDays(-10 + i);
            contracts.add(c);
        }
        // Update contracts to Activated status
        for (Contract c : contracts) {
            c.Status = 'Activated';
        }
        update contracts;
        return contracts;
    }

    /**
     * @description Creates a MassUpdateExecution__c record and a related MassUpdateExecutionLine__c record for the given contract, and returns the created MassUpdateExecution__c record.
     * @return The created MassUpdateExecution__c record.
     */
    public static MassUpdateExecution__c createMassUpdateExecution() {
        // Create a MassUpdateExecution record
        MassUpdateExecution__c exec = new MassUpdateExecution__c(Feature__c = 'QuoteUpdate', Status__c = 'Completed', QueryFilters__c = '{}');
        insert exec;
        return exec;
    }

    /**
     * @description Creates a MassUpdateExecutionLine__c record associated with the given MassUpdateExecution__c record and Contract record, and returns the created MassUpdateExecutionLine__c record.
     * @param exec - The MassUpdateExecution__c record to associate with the MassUpdateExecutionLine__c record.
     * @param contract - The Contract record to associate with the MassUpdateExecutionLine__c record.
     * @return The created MassUpdateExecutionLine__c record
     */
    public static MassUpdateExecutionLine__c createMassUpdateExecutionLine(MassUpdateExecution__c exec, Contract contract) {
        MassUpdateExecutionLine__c line = new MassUpdateExecutionLine__c(
            MassUpdateExecution__c = exec.Id,
            Contract__c = contract.Id,
            CreatedQuote__c = contract.SBQQ__Quote__c,
            Feature__c = 'QuoteUpdate',
            Status__c = 'Success'
        );
        insert line;
        return line;
    }

    private static String generateRandomSAPContractNumber() {
        Integer size = 8;
        Long minValue = (Long) Math.pow(10, size - 1);
        Long maxValue = (Long) Math.pow(10, size) - 1;
        Long randomNumber = minValue + (Long) (Math.random() * (maxValue - minValue + 1));
        String stringNumber = String.valueOf(randomNumber);
        String result = '00' + stringNumber;
        return result;
    }
}