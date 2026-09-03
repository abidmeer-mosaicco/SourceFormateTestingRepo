/**
 * @description This class will be used to insert any test data to be used in test class execution.
 * All the object related record value assignment will happen here.
 * @author Kailas Shimpi
 * @storynumber GPSSM-1224
 */

 public with sharing class PMC_TestUtilityClass {

    //This is a constant variable that stored developer name of Master record type for objects
    public static final string STRING_MASTER_RECORD_TYPE_NAME = 'Master';

    /**
    * @description This method will be use to create User records for test class execution.
    * @param intCountToInsert - No of records that we would like to create.
    * @return This method will return count of user records requested for insertion.
    */
    public static List<User> createUser(Integer intCountToInsert) {
        //get the sandbox name to append it to the user name
        String strSandboxName = UserInfo.getUserName().substringAfterLast('.');
        User objUser;
        List<User> lstUsersToInsert = new List<User>();
        //Iterate over the intCountToInsert to create user records
        for(Integer intCount = 0; intCount < intCountToInsert; intCount++) {
            UUID randomUuid = UUID.randomUUID();
            objUser = new User();
            objUser.FirstName = 'Test John';
            objUser.LastName = 'Test Doe '+intCount;
            objUser.Alias = 'tDoe'+intCount;
            objUser.Email='john.doe'+intCount+'@mosaicco.com';
            objUser.Username = objUser.Email+'.'+strSandboxName+randomUuid.toString();
            objUser.LanguageLocaleKey='en_US';
            objUser.EmailEncodingKey='UTF-8';
            objUser.LocaleSidKey='en_US';
            objUser.TimeZoneSidKey='America/Los_Angeles';
            objUser.FederationIdentifier='john.doe'+intCount+'@mosaicco.com';
			objUser.MobilePhone='9999999999';
            objUser.PMC_CPQ_SalesRegion__c='Global';
            lstUsersToInsert.add(objUser);
        }
        if(!lstUsersToInsert.isEmpty() && Schema.sObjectType.User.isCreateable()) {
            Database.insert(lstUsersToInsert, false);
            return lstUsersToInsert;
        }
        return null;
    }
    
    /**
    * @description This method will be use to create Account records for test class execution.
    * @param strAccountName - Account Name that will be passed as a parameter.
    * @param strRecordType - Record type name.
    * @return This method will return count of account records requested for insertion.
    */
     public static Account createAccount(String strAccountName, String strRecordType) {
         //This variable is used to assign the master record type if strRecordType is blank
         String recordTypeDevName = !String.isBlank(strRecordType) ? strRecordType : STRING_MASTER_RECORD_TYPE_NAME;
         
         Id recordTypeId = Schema.SObjectType.Account.getrecordtypeinfosbydevelopername().get(recordTypeDevName).getRecordTypeId();
         
         Account objAccount = new Account();
         objAccount.Name = strAccountName;
         objAccount.phone = '123-123-1234';
         objAccount.BillingCity='abc';
         objAccount.BillingStreet ='xyz';
         
         objAccount.RecordTypeId = recordTypeId;
         
        if(Schema.sObjectType.Account.isCreateable()) {
            insert objAccount;
            return objAccount;
        }
         return null;
     }
    
    /**
    * @description This method will be use to create Contact records for test class execution.
    * @param intCountToInsert - No of records that we would like to create.
    * @param strRecordType - Record type name.
    * @return This method will return count of contact records requested for insertion.
    */
    public static List<Contact> createContact(Integer intCountToInsert, String strRecordType) {
        /**
         * THIS CODE TO BE USED ONLY WHEN RECORDTYPES ARE DEFINED
         * //This variable is used to assign the master record type if strRecordType is blank
        String recordTypeDevName = !String.isBlank(strRecordType) ? strRecordType : STRING_MASTER_RECORD_TYPE_NAME;
        Id recordTypeId = Schema.SObjectType.Contact.getrecordtypeinfosbydevelopername().get(recordTypeDevName).getRecordTypeId();
         */

        Contact objContact;
        List<Contact> lstContactsToInsert = new List<Contact>();
        
        //Iterate over the intCountToInsert to create contact records
        for(Integer intCount = 0; intCount < intCountToInsert; intCount++) {
            objContact = new Contact();
            objContact.FirstName = 'test Jane';
            objContact.LastName = 'test Doe'+intCount;
            //objContact.PMC_SS_Status__c = 'Active';
            lstContactsToInsert.add(objContact);
        }
        if(!lstContactsToInsert.isEmpty() && Schema.sObjectType.Contact.isCreateable() ) {
            Database.insert(lstContactsToInsert, false);
            return lstContactsToInsert;
        }
        return null;
    }
    
    
    /**
    * @description This method will be use to create Lead records for test class execution.
    * @param intCountToInsert - No of records that we would like to create.
    * @param strRecordType - Record type name.
    * @return This method will return count of lead records requested for insertion.
    */
    public static List<Lead> createLead(Integer intCountToInsert, String strRecordType) {
        /**
         * THIS CODE TO BE USED ONLY WHEN RECORDTYPES ARE DEFINED
         * //This variable is used to assign the master record type if strRecordType is blank
        String recordTypeDevName = !String.isBlank(strRecordType) ? strRecordType : STRING_MASTER_RECORD_TYPE_NAME;
        Id recordTypeId = Schema.SObjectType.Lead.getrecordtypeinfosbydevelopername().get(recordTypeDevName).getRecordTypeId();
         */

        Lead objLead;
        List<Lead> lstLeadsToInsert = new List<Lead>();
        
        //Iterate over the intCountToInsert to create lead records
        for(Integer intCount = 0; intCount < intCountToInsert; intCount++) {
            objLead = new Lead();
            objLead.FirstName = 'test John';
            objLead.LastName = 'test Doe'+intCount;
            objLead.Company = 'test Mosaic Company';
            objLead.PMC_SS_AcceptedByRetailer__c = 'Accepted';
            objLead.PMC_SS_RetailerName__c = 'test David';
            objLead.PMC_SS_LeadType__c = 'Teacher';
            
            lstLeadsToInsert.add(objLead);
        }
        if(!lstLeadsToInsert.isEmpty() && Schema.sObjectType.Lead.isCreateable()) {
            Database.insert(lstLeadsToInsert, false);
            return lstLeadsToInsert;
        }
        return null;
    }
    
    /**
    * @description This method will be use to create Opportunity records for test class execution.
    * @param intCountToInsert - No of records that we would like to create.
    * @param strRecordType - Record type name.
    * @return This method will return count of opportunity records requested for insertion.
    */
    public static List<Opportunity> createOpportunity(Integer intCountToInsert, String strRecordType) {
        /**
         * THIS CODE TO BE USED ONLY WHEN RECORDTYPES ARE DEFINED
         * //This variable is used to assign the master record type if strRecordType is blank
        String recordTypeDevName = !String.isBlank(strRecordType) ? strRecordType : STRING_MASTER_RECORD_TYPE_NAME;
        Id recordTypeId = Schema.SObjectType.Opportunity.getrecordtypeinfosbydevelopername().get(recordTypeDevName).getRecordTypeId();
         */

        Opportunity objOpportunity;
        List<Opportunity> lstOpportunitiesToInsert = new List<Opportunity>();
        List<Account> lstAccount = [Select Id,Name from Account where RecordType.DeveloperName='PMC_SS_Prospect'];
        if(lstAccount.isempty()){
           Account objAccount = createAccount('The Mosaic Company 1', 'PMC_SS_Prospect');
           lstAccount.add(objAccount);
        }
        
        //Iterate over the intCountToInsert to create opportunity records
        for(Integer intCount = 0; intCount < intCountToInsert; intCount++) {
            objOpportunity = new Opportunity();
            objOpportunity.Name = 'test Opportunity Name'+intCount;
            objOpportunity.AccountId = lstAccount[0].id;
            objOpportunity.CloseDate = System.today();
            objOpportunity.StageName = 'Prospecting';
            objOpportunity.ForecastCategoryName = 'Pipeline';

            lstOpportunitiesToInsert.add(objOpportunity);
        }
        
        if(!lstOpportunitiesToInsert.isEmpty() && Schema.sObjectType.Opportunity.isCreateable() ) {
            Database.insert(lstOpportunitiesToInsert, true);
            return lstOpportunitiesToInsert;
        }
        return null;
    }
    
    /**
    * @description This method will be use to create Opportunity contact roles for test class execution.
    * @param lstContacts - List of Contacts for creating the contact roles.
    * @param lstOpportunities - List of Opportunities for which Contact Roles records are to be created.
    * @return This method will return opportunity contact roles records.
    */
    public static List<OpportunityContactRole> createOpportunityContactRoles(List<Contact> lstContacts, List<Opportunity> lstOpportunities) {
        OpportunityContactRole objOppContactRole;
        List<OpportunityContactRole> lstContactRolesToInsert = new List<OpportunityContactRole>();

        //Iterate over the lstContacts to create opportunity contact roles records
        for(Contact objContact: lstContacts) {
            objOppContactRole = new OpportunityContactRole();
            objOppContactRole.ContactId = objContact.id;
            objOppContactRole.OpportunityId = lstOpportunities[0].id;
            lstContactRolesToInsert.add(objOppContactRole);
        }
        if(!lstContactRolesToInsert.isEmpty() && Schema.sObjectType.OpportunityContactRole.isCreateable()) {
            Database.insert(lstContactRolesToInsert, false);
            return lstContactRolesToInsert;
        }
        return null;
    }
    
    /**
    * @description This method will be use to create Opportunity Team Members for test class execution.
    * @param lstUser - List of Users for creating the opportunity team member .
    * @param lstOpportunities - List of Opportunities for which Team Member records are to be created.
    * @return This method will return opportunity Team Member records.
    */
    public static List<OpportunityTeamMember> createOpportunityTeamMember(List<User> lstUser, List<Opportunity> lstOpportunities) {
        OpportunityTeamMember objTeamMember; 
        List<OpportunityTeamMember> lstOppTeamMembers = new List<OpportunityTeamMember>{};

        //Iterate over the Users to add as opportunity team member.
        for(User objUser: lstUser) {
        	objTeamMember = new OpportunityTeamMember();
        	objTeamMember.UserId = objUser.Id;
        	objTeamMember.OpportunityId = lstOpportunities[0].id;
        	objTeamMember.TeamMemberRole = 'Account Manager';
        	lstOppTeamMembers.add(objTeamMember);
    	}
        if(!lstOppTeamMembers.isEmpty() && Schema.sObjectType.OpportunityTeamMember.isCreateable()) {
            Database.insert(lstOppTeamMembers, false);
            return lstOppTeamMembers;
        }
        return null;
    }
    
    /**
    * @description This method will be use to create Product records for test class execution.
    * @param intCountToInsert - Number of records that we would like to create.
    * @param strRecordType - Record type name.
    * @return This method will return count of Product records requested for insertion.
    */
    public static List<Product2> createProduct(Integer intCountToInsert, String strRecordType) {
        //This variable is used to assign the master record type if strRecordType is blank
        String recordTypeDevName = !String.isBlank(strRecordType) ? strRecordType : STRING_MASTER_RECORD_TYPE_NAME;

        Id recordTypeId = Schema.SObjectType.Product2.getrecordtypeinfosbydevelopername().get(recordTypeDevName).getRecordTypeId();

        Product2 objProduct;
        List<Product2> lstProductsToInsert = new List<Product2>();
        
        //Iterate over the intCountToInsert to create Product records
        for(Integer intCount = 0; intCount < intCountToInsert; intCount++) {
            objProduct = new Product2();
            objProduct.Name ='Test Product'+intCount;
            objProduct.isActive = true;
            objProduct.RecordTypeId = recordTypeId;
            objProduct.PMC_CPQ_SAPProductCode__c='0000BBBBB121'+intCount;
            lstProductsToInsert.add(objProduct);
        }
        if(!lstProductsToInsert.isEmpty() && Schema.sObjectType.Product2.isCreateable()) {
            Database.insert(lstProductsToInsert, false);
            return lstProductsToInsert;
        }
        return null;
    }

    /**
    * @description This method will be use to create Price Book Entry records for test class execution.
    * @param lstProducts - List of products for which price book entry is to be created.
    * @param idPriceBook - Id of the Price book.
    * @return This method will return list of Price Book Entry records requested for insertion.
    */
    public static List<PricebookEntry> createPriceBookEntry(List<Product2> lstProducts, Id idPriceBook) {
        PricebookEntry objPriceBookEntry;
        List<PricebookEntry> lstPriceBookEntry = new List<PricebookEntry>{};

        //Iterate over the Products to add in price book entry.
        for(Product2 objProduct: lstProducts) {
        	objPriceBookEntry = new PricebookEntry();
            objPriceBookEntry.Pricebook2Id = idPriceBook;
            objPriceBookEntry.Product2Id = objProduct.Id;
            objPriceBookEntry.UnitPrice = 100.00;
            objPriceBookEntry.IsActive = true;
        	lstPriceBookEntry.add(objPriceBookEntry);
    	}
        if(!lstPriceBookEntry.isEmpty() && Schema.sObjectType.PricebookEntry.isCreateable()) {
            Database.insert(lstPriceBookEntry, false);
            return lstPriceBookEntry;
        }
        return null;
    }
    
    /**
    * @description This method will be use to create Opportunity line item records for test class execution.
    * @param lstPriceBookEntry - List of Price book entries.
    * @param lstOpportunities - List of Opportunities for which Opportunity line item records are to be created.
    * @return This method will return list of Opportunity line item records requested for insertion.
    */
    public static List<OpportunityLineItem> createOpportunityLineItem(List<PricebookEntry> lstPriceBookEntry, List<Opportunity> lstOpportunities) {
        OpportunityLineItem objOpportunityLineItem;
        List<OpportunityLineItem> lstOpportunityLineItem = new List<OpportunityLineItem>{};

        //Iterate over the Price Book Entry to create Opportunity Line Item.
        for(PriceBookEntry objPriceBookEntry: lstPriceBookEntry) {
            objOpportunityLineItem = new OpportunityLineItem();
            objOpportunityLineItem.OpportunityId = lstOpportunities[0].Id;
            objOpportunityLineItem.PricebookEntryId = objPriceBookEntry.Id;
            objOpportunityLineItem.Quantity = 5;
            objOpportunityLineItem.TotalPrice = objOpportunityLineItem.Quantity * objPriceBookEntry.UnitPrice;
            lstOpportunityLineItem.add(objOpportunityLineItem);
        }
        if(!lstOpportunityLineItem.isEmpty() && Schema.sObjectType.OpportunityLineItem.isCreateable()) {
            Database.insert(lstOpportunityLineItem, false);
            return lstOpportunityLineItem;
        }
        return null;
    }
    
    /**
    * @description This method will be use to create Contracts for test class execution.
    * @param lstAccounts - List of Accounts to associate with the contracts.
    * @param lstOpportunities - List of Opportunities for which contracts records are to be created.
    * @return This method will return contract records.
    */
    public static List<Contract> createContract(List<Account> lstAccounts, List<Opportunity> lstOpportunities) {
        Contract objContract;
        List<Contract> lstContractsToInsert = new List<Contract>();

        //Iterate over the lstAccounts to associate the account with the contract.
        for(Account objAccount: lstAccounts) {
            objContract = new Contract();
            objContract.AccountId = objAccount.id;
            objContract.SBQQ__Opportunity__c = lstOpportunities[0].id;
            objContract.StartDate = Date.today()-31;
            objContract.EndDate = Date.today();
            objContract.Status='Draft';
            lstContractsToInsert.add(objContract);
        }
        
        
        if(!lstContractsToInsert.isEmpty() && Schema.sObjectType.Contract.isCreateable()) {
            Database.insert(lstContractsToInsert, false);
            return lstContractsToInsert;
        }
        return null;
    }
    
    /**
    * @description This method will be use to create Quotes for test class execution.
    * @param intCountToInsert - Number of records that we would like to create.
    * @param lstOpportunities - List of Opportunities for which contracts records are to be created.
    * @return This method will return quotes records.
    */
    public static List<Quote> createQuotes(Integer intCountToInsert, List<Opportunity> lstOpportunities) {
        Quote objQuote;
        List<Quote> lstQuotesToInsert = new List<Quote>();
        
        //Iterate over the intCountToInsert to create Product records
        for(Integer intCount = 0; intCount < intCountToInsert; intCount++) {
            objQuote = new Quote();
            objQuote.Name ='Test Quote'+intCount;
            objQuote.OpportunityId = lstOpportunities[0].id;
            lstQuotesToInsert.add(objQuote);
        }
        if(!lstQuotesToInsert.isEmpty() && Schema.sObjectType.Quote.isCreateable()) {
            Database.insert(lstQuotesToInsert, false);
            return lstQuotesToInsert;
        }
        return null;
    }
     
    /**
    * @description This method will be use to create Orders for test class execution.
    * @param intCountToInsert - Number of records that we would like to create.
    * @param lstAccounts - List of Accounts for which Order records are to be created.
    * @return lstOrdersToInsert - This method will return orders records.
    */
    public static List<Order> createOrders(Integer intCountToInsert, List<Account> lstAccounts) {
        Order objOrder;
        List<Order> lstOrdersToInsert = new List<Order>();
        for(Integer intCount = 0; intCount < intCountToInsert; intCount++) {
            objOrder = new Order();
            objOrder.Name ='Test Order '+intCount;
            objOrder.AccountId = lstAccounts[0].id;
            objOrder.EffectiveDate = System.today();
            objOrder.Status = 'Draft';
            lstOrdersToInsert.add(objOrder);
        }
        if(!lstOrdersToInsert.isEmpty() && Schema.sObjectType.Order.isCreateable()) {
            Database.insert(lstOrdersToInsert, true);
            return lstOrdersToInsert;
        }
        return null;
    }
    /**
    * @description This method will be use to create Order Products for test class execution.
    * @param intCountToInsert - Number of records that we would like to create.
    * @param lstOrders - List of which Order records.
    * @return lstOrderProductsToInsert - This will return list of products.
    */
    public static List<OrderItem> createOrderProducts(Integer intCountToInsert, List<Order> lstOrders) {
        OrderItem objOrderProducts;
        List<OrderItem> lstOrderProductsToInsert = new List<OrderItem>();
        for(Integer intCount = 0; intCount < intCountToInsert; intCount++) {
            objOrderProducts = new OrderItem();
            List<Product2> lstProducts = PMC_TestUtilityClass.createProduct(1,'PMC_CPQ_NA');
            objOrderProducts.Product2Id = lstProducts[0].id;
            objOrderProducts.OrderId = lstOrders[0].id;
            objOrderProducts.Quantity = 2;
            objOrderProducts.PMC_CPQ_ListPrice__c = 190;
            objOrderProducts.UnitPrice = 0;
            objOrderProducts.PMC_CPQ_FinalAgreedPrice__c = 1;
            lstOrderProductsToInsert.add(objOrderProducts);
        }
        //insert objOrderProducts;
        if(!lstOrderProductsToInsert.isEmpty() && Schema.sObjectType.OrderItem.isCreateable()) {
            Database.insert(lstOrderProductsToInsert, false);
            return lstOrderProductsToInsert;
        }
        return null;
    }

    /**
    * @description This method will be use to create Quotes for test class execution.
    * @param intCountToInsert - Number of records that we would like to create.
    * @param lstOpportunities - List of Opportunities to be associated with the quote.
    * @param lstContacts - List of Contacts for which needs to be linked to as primary to the quote.
    * @return This method will return cpq quotes records.
    */
    public static List<SBQQ__Quote__c> createCPQQuotes(Integer intCountToInsert, List<Opportunity> lstOpportunities, List<Contact> lstContacts) {
        SBQQ__Quote__c objQuote;
        Date dateStartDate = System.today();
        dateStartDate = dateStartDate.addDays(3);
    	Date dateEndDate = dateStartDate.addDays(35);
        List<SBQQ__Quote__c> lstCPQQuotesToInsert = new List<SBQQ__Quote__c>();
        
        //Iterate over the intCountToInsert to create CPQ records
        for(Integer intCount = 0; intCount < intCountToInsert; intCount++) {
            objQuote = new SBQQ__Quote__c();
            objQuote.SBQQ__Opportunity2__c = lstOpportunities[intCount].id;
            objQuote.PMC_CPQ_ContractStart__c = dateStartDate;
            objQuote.PMC_CPQ_ContractEnd__c = dateEndDate;
            objQuote.PMC_CPQ_PrimaryContact__c = lstContacts[intCount].id;
            objQuote.PMC_CPQ_CustomCreatedDate__c = System.now();
            lstCPQQuotesToInsert.add(objQuote);
        }
        if(!lstCPQQuotesToInsert.isEmpty() && Schema.sObjectType.SBQQ__Quote__c.isCreateable()) {
            Database.insert(lstCPQQuotesToInsert, false);
            
            return lstCPQQuotesToInsert;
        }
        return null;
    }
    /**
    * @description This method will be use to create Sales Area records for test class execution.
    * @param intCountToInsert - No of records that we would like to create.
    * @param strRecordType - Record type name.
    * @return This method will return count of Sales Area records requested for insertion.
    */
    public static List<PMC_SS_SalesArea__c> createSalesArea(Integer intCountToInsert, String strRecordType) {
        /**
         * THIS CODE TO BE USED ONLY WHEN RECORDTYPES ARE DEFINED
         * //This variable is used to assign the master record type if strRecordType is blank
        String recordTypeDevName = !String.isBlank(strRecordType) ? strRecordType : STRING_MASTER_RECORD_TYPE_NAME;
        Id recordTypeId = Schema.SObjectType.PMC_SS_SalesArea__c.getrecordtypeinfosbydevelopername().get(recordTypeDevName).getRecordTypeId();
         */

        PMC_SS_SalesArea__c objSalesArea;
        List<PMC_SS_SalesArea__c> lstSalesAreaToInsert = new List<PMC_SS_SalesArea__c>();
        
        //Iterate over the intCountToInsert to create Sales Area records
        for(Integer intCount = 0; intCount < intCountToInsert; intCount++) {
            objSalesArea = new PMC_SS_SalesArea__c();
            objSalesArea.Name = 'test Sales Area Name' + intCount;

            lstSalesAreaToInsert.add(objSalesArea);
        }
        if(!lstSalesAreaToInsert.isEmpty() && Schema.sObjectType.PMC_SS_SalesArea__c.isCreateable()) {
            Database.insert(lstSalesAreaToInsert, false);
            return lstSalesAreaToInsert;
        }
        return null;
    }

    /**
    * @description This method will be use to create Account Sales Area Relationship records for test class execution.
    * @param lstAccounts - List of account records
    * @param lstSalesAreas - List of Sales Area Records
    * @return This method will return count of Account Sales Area Relationship records requested for insertion.
    */
    public static List<PMC_SS_AccountSalesAreaRelationship__c> createAccountSalesAreaRelationship(List<Account> lstAccounts, List<PMC_SS_SalesArea__c> lstSalesAreas) {
        //Id recordTypeId = Schema.SObjectType.PMC_SS_AccountSalesAreaRelationship__c.getrecordtypeinfosbydevelopername().get(strRecordType).getRecordTypeId();
        PMC_SS_AccountSalesAreaRelationship__c objAccountSalesAreaRelationship;
        List<PMC_SS_AccountSalesAreaRelationship__c> lstAccountSalesAreaRelationshipToInsert = new List<PMC_SS_AccountSalesAreaRelationship__c>();
        
        //Iterate over the intCountToInsert to create Account Sales Area Relationship records
        for(Integer intCount = 0; intCount < lstAccounts.size(); intCount++) {
            objAccountSalesAreaRelationship = new PMC_SS_AccountSalesAreaRelationship__c();
            objAccountSalesAreaRelationship.PMC_SS_Account__c = lstAccounts[intCount].Id;
            objAccountSalesAreaRelationship.PMC_SS_SalesArea__c = lstSalesAreas[intCount].Id;
            lstAccountSalesAreaRelationshipToInsert.add(objAccountSalesAreaRelationship);
        }
        if(!lstAccountSalesAreaRelationshipToInsert.isEmpty() && Schema.sObjectType.PMC_SS_AccountSalesAreaRelationship__c.isCreateable()) {
            insert lstAccountSalesAreaRelationshipToInsert;
            return lstAccountSalesAreaRelationshipToInsert;
        }
        return null;
    }

    /**
    * @description This method will be use to create Lead object wrapper
    * @param strLastName - latsname for lead
    * @param strEmail - lead Email
    * @param strProductFamilyInterest - product interest of lead
    * @return This method will return lead object wrapper.
    */
    public static Lead createLeadObjectWrapper(String strLastName, String strEmail, String strProductFamilyInterest){
        Lead objLead = new Lead();

        objLead.LastName = strLastName;
        objLead.Status = PMC_SS_ConstantClass.LEAD_STATUS_NEW;
        objLead.Email = strEmail;
        objLead.MobilePhone = '9798484980';
        objLead.Company = 'Test.COM';
        objLead.Website = 'Test.COM';
        objLead.PMC_SS_ProductFamilyCategoryInterests__c = strProductFamilyInterest;

        return objLead;
    }
     
   /**
    * @description This method will be use to create Case object records if accountId is passed
    * @param idBusinessHours - BusinessHours Id
    * @param idAccount - Case Account Id
    * @param idOwner - Case Owner Id
    * @param idLocation - Case Location Id
    * @return This method will case object.
    */
    
     public static Case createCase(Id idBusinessHours, Id idAccount, Id idOwner,Id idLocation) {
         
        List<Contact> lstContacts = PMC_TestUtilityClass.createContact(1 ,'Master');
         
         
        Case objCase = new Case();
        objCase.Subject = 'Test Subject';
        objCase.Description = 'Test Description';
        objCase.Status = 'New';
        objCase.Type = 'Shipping';
        objCase.Origin = 'Phone';
        objCase.PMC_SS_CurrentDestinationLocation__c  = idLocation;
        objCase.BusinessHoursId = idBusinessHours;
        objCase.ContactId = lstContacts.get(0).Id;
         if(idAccount != null) {
             objCase.AccountId = idAccount;
         }
        objCase.OwnerId = idOwner;
             
        if(Schema.sObjectType.Case.isCreateable()) {
            return objCase;
        }
                                       
        return null;
     } 
      /**
    * @description This method will be use to create Case object records if accountId is passed and contact is null
    * @param idBusinessHours - BusinessHours Id
    * @param idAccount - Case Account Id
    * @param idOwner - Case Owner Id
    * @param idLocation - Case Location Id
    * @return This method will case object.
    */
    
     public static Case createCaseWithoutContact(Id idBusinessHours, Id idAccount, Id idOwner,Id idLocation) {
         
        
         
        Case objCase = new Case();
        objCase.Subject = 'Test Subject';
        objCase.Description = 'Test Description';
        objCase.Status = 'New';
        objCase.Type = 'Internal';
        objCase.PMC_SS_IssueReason__c ='MDM Verification';
        objCase.Origin = 'Email';
        objCase.PMC_SS_CurrentDestinationLocation__c  = idLocation;
        objCase.BusinessHoursId = idBusinessHours;
         if(idAccount != null) {
             objCase.AccountId = idAccount;
         }
        objCase.OwnerId = idOwner;
             
        if(Schema.sObjectType.Case.isCreateable()) {
            return objCase;
        }
                                       
        return null;
     } 
     /**
    * @description This method will be use to create AccountTeamMember records if accountId is passed
    * @param idUser - user Id
    * @param idAccount - Case Account Id
    * @param strTeamMemberRole -TeamMemberRole 
    * @return This method will AccountTeamMember.
    */
     
    public static AccountTeamMember createAccountTeamMember(Id idUser ,Id idAccount , String strTeamMemberRole ) {
     
        AccountTeamMember objAccountTeamMember = new AccountTeamMember();
        objAccountTeamMember.UserId = idUser;
        if(idAccount != null) {
            objAccountTeamMember.AccountId = idAccount;
        }
        objAccountTeamMember.TeamMemberRole = strTeamMemberRole;
        
        if(Schema.sObjectType.AccountTeamMember.isCreateable()) {
           return  objAccountTeamMember;
        }
                                       
        return null;
    }
     /**
    * @description This method will be use to create Case object records if contact id is passed
    * @param idBusinessHours - BusinessHours Id
    * @param idContact - Case Contact Id
    * @param idOwner - Case Owner Id
    * @return This method will case object.
    */
    
     public static Case createCaseWithContact(Id idBusinessHours, Id idContact, Id idOwner) {
         
        Case objCase = new Case();
        objCase.Subject = 'Test Subject';
        objCase.Description = 'Test Description';
        objCase.Status = 'New';
        objCase.Type = 'Shipping';
        objCase.Origin = 'Phone';
        objCase.BusinessHoursId = idBusinessHours;
        objCase.ContactId = idContact;
        objCase.OwnerId = idOwner;
             
        if(Schema.sObjectType.Case.isCreateable()) {
            insert objCase;
            return objCase;
        }
                                       
        return null;
     } 
     
     
   /**
    * @description This method will be use to create Contact object record with all Phone No.s
    * This method is used to get the test coverage. Please do not use this in your implementation
    * as it will lead to DUplicate contact validation.
    * @return This method will Contact object record.
    */
     
     public static Contact createContactWithPhone() {
         
         Contact objContact = new Contact();
         objContact.FirstName = 'test Jane';
         objContact.LastName = 'test Doe Jane';
         objContact.Phone = '0101010101';
         objContact.HomePhone = '0202020202';
         objContact.OtherPhone = '0303030303';
         objContact.MobilePhone = '0404040404';
         
         if(Schema.sObjectType.Contact.isCreateable()) {
             insert objContact;
             return objContact;
         }
         return null;
     }
     
     /**
    * @description This method will be used to create Portal User records for test class execution.
    * @param intCountToInsert - No of user records that we would like to create.
    * @param objProfileToAssign - Profile to be assigned to the Portal Users.
    * @return This method will return Portal user records requested for insertion.
    */
    public static List<User> createPortalUser(Integer intCountToInsert, Profile objProfileToAssign) {
        
        Account objAccountToInsert = PMC_TestUtilityClass.createAccount('The Test Company','PMC_SS_Prospect');
        List<Contact> lstContacts = PMC_TestUtilityClass.createContact(intCountToInsert,'Master');
        
        //get the sandbox name to append it to the user name
        String strSandboxName = UserInfo.getUserName().substringAfterLast('.');
        User objUser;
        List<User> lstPortalUsersToInsert = new List<User>();
        //Iterate over the intCountToInsert to create user records
        for(Integer intCount = 0; intCount < intCountToInsert; intCount++) {
            lstContacts[intCount].accountId= objAccountToInsert.Id;
            objUser = new User();
            objUser.FirstName = 'Test Portal';
            objUser.LastName = 'Test Doe '+intCount;
            objUser.Alias = 'tPorDoe'+intCount;
            objUser.Email='portal.doe'+intCount+'@mosaicco.com';
            objUser.Username = objUser.Email+'.'+strSandboxName;
            objUser.LanguageLocaleKey='en_US';
            objUser.EmailEncodingKey='UTF-8';
            objUser.LocaleSidKey='en_US';
            objUser.TimeZoneSidKey='America/Los_Angeles';
            objUser.ContactId = lstContacts[intCount].Id;
            objUser.ProfileId = objProfileToAssign.Id;
            objUser.isActive = true;
            lstPortalUsersToInsert.add(objUser);
        }

        if(!lstContacts.isEmpty() && Schema.sObjectType.Contact.isUpdateable()) {
            update lstContacts;
        }
        if(!lstPortalUsersToInsert.isEmpty() && Schema.sObjectType.User.isCreateable()) {
            Database.insert(lstPortalUsersToInsert, false);
            return lstPortalUsersToInsert;
        }
        return null;
    }
     
     /**
    * @description This method will be used to assign Permission Set Group to User records for test class execution.
    * @param lstUsersToAssign - The List of users to be assigned the Permission set group.
    * @param permSetGrpToAssign - Permission Set Group to be assigned to the Users.
    */
     public static void assignPermissionSetGroupToUsers(List<User> lstUsersToAssign, PermissionSetGroup permSetGrpToAssign) {
         List<PermissionSetAssignment> lstPermSetAssignment = new List<PermissionSetAssignment>();
         PermissionSetAssignment objPermSetAssignment;
         for(Integer intCount = 0; intCount < lstUsersToAssign.size(); intCount++) {
             objPermSetAssignment = new PermissionSetAssignment();
             objPermSetAssignment.AssigneeId= lstUsersToAssign[intCount].id;
             objPermSetAssignment.PermissionSetGroupId = permSetGrpToAssign.Id;
             lstPermSetAssignment.add(objPermSetAssignment);
         }
         if(!lstPermSetAssignment.isEmpty() && Schema.sObjectType.PermissionSetAssignment.isCreateable()) {
             Database.insert(lstPermSetAssignment, false);
            

         }
     }
     
     /**
    * @description This method will be used to insert Bulletin Article.
    * @param strArticleTitle - This is title for article.
    */
     public static void insertBulletinArticle(String strArticleTitle) {
		 Id idRecordType = Schema.SObjectType.Knowledge__kav.getrecordtypeinfosbydevelopername().get(Label.PMC_SS_KnowledgeArticle_BulletinRecordType).getRecordTypeId();
         Knowledge__kav objArticle = new Knowledge__kav();
         objArticle.RecordTypeId =idRecordType;
         objArticle.Title=strArticleTitle;
         objArticle.Summary=strArticleTitle;
         objArticle.PMC_SS_Region__c='North America';
         objArticle.UrlName=strArticleTitle;
         objArticle.PMC_SS_NumberOfDisplayDays__c=1;
        if(Schema.sObjectType.Knowledge__kav.isCreateable()) {
             Database.insert(objArticle, false);
         }
     }
     
    /**
    * @description This method will be used to insert Location.
    * @param strLocationName - Location Name
    * @return Location - inserted location record
    */
     public static Schema.Location createLocation(String strLocationName) {
         Schema.Location objLocation = new Schema.Location();
         objLocation.Name = strLocationName;
         objLocation.LocationType = 'Warehouse';
         objLocation.PMC_CPQ_Plant__c = 'Test Plant';
         objLocation.PMC_CPQ_SAPLocationId__c='9999';
         if(Schema.SObjectType.Location.isCreateable()) {
             insert (Schema.Location) objLocation;
             return objLocation;
         }
         
         return null;
     }
     
     /**
    * @description This method will be used to insert Product Location.
    * @param strLocationName - Location Name
    * @param objLocation - Schema.Location Object
    * @return PMC_CPQ_ProductLocation__c - inserted product location record
    */
     public static PMC_CPQ_ProductLocation__c createProductLocation(String strLocationName, Schema.Location objLocation) {
         PMC_CPQ_ProductLocation__c objProductLocation = new PMC_CPQ_ProductLocation__c();
		 objProductLocation.Name = strLocationName;
         objProductLocation.PMC_CPQ_Location__c = objLocation.Id;
         
         if(Schema.sObjectType.PMC_CPQ_ProductLocation__c.isCreateable()) {
             insert objProductLocation;
             return objProductLocation;
         }
         
         return null;
     }
     
     /**
    * @description This method will be used to insert Delivery.
    * @param strShipToName - ShipToName
    * @param objOrder - Order Object
    * @return Shipment - inserted Shipment record
    */
     
     public static Shipment createDelivery(String strShipToName, Order objOrder) {
         Shipment objShipment = new Shipment();
         objShipment.ShipToName = strShipToName;
         objShipment.PMC_CPQ_Order__c = objOrder.Id;
         objShipment.OwnerId = UserInfo.getUserId();
         
         if(Schema.sObjectType.Shipment.isCreateable()) {
             insert objShipment;
             return objShipment;
         }
         
         return null;
     }
     
    /**
    * @description This method will be used to insert Delivery Item.
    * @param objShipment - Shipment Object
    * @param objOrderItem - Order Item Object
    * @return ShipmentItem - inserted ShipmentItem record
    */
     public static ShipmentItem createDeliveryItem(Shipment objShipment, OrderItem objOrderItem) {
         ShipmentItem objShipmentItem = new ShipmentItem();
         objShipmentItem.PMC_CPQ_ModeofTransportation__c = 'Truck';
         objShipmentItem.PMC_CPQ_VehicleID__c = 'Test Vehicle';
         objShipmentItem.ShipmentId = objShipment.Id;
         objShipmentItem.Quantity = 2;
         objShipmentItem.PMC_CPQ_OrderProduct__c = objOrderItem.Id;
         
         if(Schema.sObjectType.ShipmentItem.isCreateable()) {
             insert objShipmentItem;
             return objShipmentItem;
         }
         
         return null;
     }
     
    /**
    * @description This method will be used to insert Invoice.
    * @param objShipment - Shipment Object
    * @param objOrder - Order Object
    * @param objContact - Contact Object
    * @return PMC_CPQ_Invoice__c - inserted Invoice record
    */
     public static PMC_CPQ_Invoice__c createInvoice(Shipment objShipment, Order objOrder, Contact objContact) {
         PMC_CPQ_Invoice__c objInvoice = new PMC_CPQ_Invoice__c();
         objInvoice.PMC_CPQ_OriginalAmount__c = 1000.0;
         objInvoice.PMC_CPQ_Order__c = objOrder.Id;
         objInvoice.PMC_CPQ_Contact__c = objContact.Id;
         objInvoice.PMC_CPQ_Delivery__c = objShipment.Id;
         
         if(Schema.sObjectType.PMC_CPQ_Invoice__c.isCreateable()) {
             insert objInvoice;
             return objInvoice;
         }
         
         return null;
     }
     
    /**
    * @description This method will be used to insert Sales Agreement.
    * @param intCountToInsert - No of records that we would like to create.
    * @param strRecordType - Record type name.
    * @return This method will return count of sales agreement records requested for insertion.
    */
     public static List<SalesAgreement> createSalesAgreement(Integer intCountToInsert, String strRecordType) {
         Id idPriceBook = Test.getStandardPricebookId();
         SalesAgreement objSalesAgreement;
         List<SalesAgreement> lstSalesAgreementToInsert = new List<SalesAgreement>();
         Account objAccount = createAccount('The Mosaic Company 2', 'PMC_SS_Prospect');
         
         //Iterate over the intCountToInsert to create Sales Agreement records
         for(Integer intCount = 0; intCount < intCountToInsert; intCount++) {
             objSalesAgreement = new SalesAgreement();
             objSalesAgreement.Name = 'test Sales Agreement '+intCount;
             objSalesAgreement.AccountId = objAccount.Id;
             objSalesAgreement.Status = PMC_SS_ConstantClass.SALES_AGREEMENT_STATUS_DRAFT;
             objSalesAgreement.StartDate = System.today()+1;
             objSalesAgreement.EndDate = Date.newInstance(objSalesAgreement.StartDate.year()+1, objSalesAgreement.StartDate.month(), objSalesAgreement.StartDate.Day());
             objSalesAgreement.ScheduleCount = 12;
             objSalesAgreement.ScheduleFrequency = PMC_SS_ConstantClass.SALES_AGREEMENT_SCHEDULEFREQUENCY_YEARLY;
             objSalesAgreement.CurrencyIsoCode = PMC_SS_ConstantClass.SALES_AGREEMENT_CURRENCYISOCODE_USD;
             objSalesAgreement.ProductLevel = PMC_SS_ConstantClass.SALES_AGREEMENT_PRODUCTLEVEL_PRODUCT;
             objSalesAgreement.ActualsCalculationMode = PMC_SS_ConstantClass.SALES_AGREEMENT_ACTUALSCALCULATIONMODE_MANUAL;
             objSalesAgreement.PricebookId = idPriceBook;
             
             lstSalesAgreementToInsert.add(objSalesAgreement);
         }
         if(!lstSalesAgreementToInsert.isEmpty() && Schema.sObjectType.SalesAgreement.isCreateable()) {
             Database.insert(lstSalesAgreementToInsert, true);
             return lstSalesAgreementToInsert;
         }
         return null;
     }
     
    /**
    * @description This method will be used to insert Sales Agreement Product.
    * @param intCountToInsert - No of records that we would like to create.
    * @param lstSalesAgreements - List of Sales Agreement Records.
    * @return This method will return count of sales agreement product records requested for insertion.
    */
     public static List<SalesAgreementProduct> createSalesAgreementProduct(Integer intCountToInsert, List<SalesAgreement> lstSalesAgreements) {
         SalesAgreementProduct objSalesAgreementProduct;
         List<SalesAgreementProduct> lstSalesAgreementProductToInsert = new List<SalesAgreementProduct>();
         
         List<Product2> lstProducts = new List<Product2>();
         Id recordTypeId = Schema.SObjectType.Product2.getrecordtypeinfosbydevelopername().get('PMC_CPQ_NA').getRecordTypeId();
         Product2 objProduct = new Product2();
         objProduct.Name ='Testing Product 123';
         objProduct.isActive = true;
         objProduct.RecordTypeId = recordTypeId;
         insert objProduct;
         lstProducts.add(objProduct);
         
         Id idPriceBook = Test.getStandardPricebookId();
         List<PricebookEntry> lstPriceBookEntry = createPriceBookEntry(lstProducts,idPriceBook);
         //Iterate over the intCountToInsert to create Sales Agreement Product records
         for(Integer intCount = 0; intCount < intCountToInsert; intCount++) {
             objSalesAgreementProduct = new SalesAgreementProduct();
             objSalesAgreementProduct.Name = 'test Sales Agreement Product '+intCount;
             objSalesAgreementProduct.SalesAgreementId = lstSalesAgreements[0].Id;
             objSalesAgreementProduct.PricebookEntryId = lstPriceBookEntry[0].Id;
             objSalesAgreementProduct.InitialPlannedQuantity = 10;
             
             lstSalesAgreementProductToInsert.add(objSalesAgreementProduct);
         }
         if(!lstSalesAgreementProductToInsert.isEmpty() && Schema.sObjectType.SalesAgreementProduct.isCreateable()) {
             Database.insert(lstSalesAgreementProductToInsert, true);
             return lstSalesAgreementProductToInsert;
         }
         return null;
     }
     
    

    

     /**
    * @description This method will be use to create PMC_SS_Allocation__c records for test class execution.
    * @param intCountToInsert - Number of Allocations records
    * @param idProductId - ProductId that will be passed as a parameter.
    * @param idLocation - LocationId that will be passed as a parameter.
    * @return List<PMC_SS_Allocation__c> This method will return allocation object wrapper requested for insertion.
    */
    public static List<PMC_SS_Allocation__c> createAllocation(Integer intCountToInsert, Id idProductId,Id idLocation) {
        List<PMC_SS_Allocation__c> lstAllocationsToInsert = new List<PMC_SS_Allocation__c>();
        for(Integer i=0;i<intCountToInsert;i++){
            PMC_SS_Allocation__c alloc= new PMC_SS_Allocation__c();
            alloc.PMC_SS_Product__c=idProductId;
            alloc.PMC_SS_Location__c=idLocation;
            alloc.PMC_SS_AllocationPeriod__c= Date.valueOf('2023-01-01');
            alloc.PMC_SS_RequestedQuantity__c=100;
            alloc.PMC_SS_AllocatedActualQuantity__c=95;
            lstAllocationsToInsert.add(alloc);        
        }
        return lstAllocationsToInsert;
    }
    /**
    * @description This method will be use to create ContentVersion object records 
    * @return objContentVersion - This method will ContentVersion object record.
    */
    
    private static ContentVersion createContentVersion() {
         
        String strFileContent = 'This is a dummy file created for testing the MDM functionality';
 
        ContentVersion objContentVersion = new ContentVersion();
        objContentVersion.ContentLocation = 'S'; 
        objContentVersion.PathOnClient = 'testdummy.png'; 
        objContentVersion.Title = 'testdummy'; 
        objContentVersion.VersionData = EncodingUtil.base64Decode(strFileContent);
        if(Schema.sObjectType.ContentVersion.isCreateable()) {
            insert objContentVersion;
            return objContentVersion;
        }
    return null; 
        
    }

    /**
    * @description This method will be use to create ContentDocumentLink object records 
    * @param idCase - Id of the case.
    * @return objContentDocumentLink - This method will ContentDocumentLink object record.
	*/
    public static ContentDocumentLink createContentDocumentLink(Id idCase){
        ContentVersion objContentDocument = PMC_TestUtilityClass.createContentVersion();
        ContentDocumentLink objContentDocumentLink = new ContentDocumentLink();
        objContentDocumentLink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:objContentDocument.Id].ContentDocumentId;
        objContentDocumentLink.LinkedEntityId = idCase; // you can use objectId,GroupId etc
        objContentDocumentLink.ShareType = 'I'; // Inferred permission, checkout description of ContentDocumentLink object for more details
        objContentDocumentLink.Visibility = 'AllUsers';
             
        if(Schema.sObjectType.ContentDocumentLink.isCreateable()) {
            insert objContentDocumentLink;
            return objContentDocumentLink;
        }
                                       
        return null;
     } 
     /**
    * @description This method will be use to return the Map of Profiles.  
    * @param lstProfileNames - List of Profile Names.
    * @return Map<String,Id> - This method will Return the Map of Profile and Id .
	*/
     public static Map<String,Id>  getProfiles(List<String>lstProfileNames){
         
         Map<String,Id>mapOfProfiles = new Map<String,Id>();
         For(Profile objProfile : [SELECT Id,Name FROM Profile WHERE Name IN :lstProfileNames with SYSTEM_MODE]){
            mapOfProfiles.put(objProfile.Name,objProfile.Id);
        }
         return mapOfProfiles;
     }
     
      /**
    * @description This method will be use to return the Map of Permission set groups. 
    * @param lstPermissionNames - List of Permission set grps. 
    * @return Map<String,PermissionSetGroup> - This method will Return the Map of Profile and Id .
	*/
     public static Map<String,PermissionSetGroup>  getPemissionsetGroups(List<String>lstPermissionNames){
         
        Map<String,PermissionSetGroup>mapOfPermissionGrp = new Map<String,PermissionSetGroup>();
         For(PermissionSetGroup objPermissionGrp : [SELECT Id,Status, DeveloperName FROM PermissionSetGroup WHERE DeveloperName IN :lstPermissionNames with SYSTEM_MODE]){
            if (objPermissionGrp.Status != 'Updated') {
                Test.calculatePermissionSetGroup(objPermissionGrp.id);
                }
             mapOfPermissionGrp.put(objPermissionGrp.DeveloperName,objPermissionGrp);
        } 
         return mapOfPermissionGrp;
     }
     
     /**
    * @description This method will be use to create Account Partner Relationship records for test class execution.
    * @param intCountToInsert - No of records that we would like to create.
    * @param idAccount - Id of Account.
    * @param idRelatedAccount - Id of Related Account
    * @return This method will return Account Partner Relationship records requested for insertion.
    */
    public static List<PMC_SS_AccountPartnerRelationships__c> createPartnerObjectWrapper(Integer intCountToInsert, Id idAccount, Id idRelatedAccount) {
         List<PMC_SS_AccountPartnerRelationships__c> lstPartnersToInsert = new List<PMC_SS_AccountPartnerRelationships__c>();
        
        //Iterate over the intCountToInsert to create partner records
        for(Integer intCount = 0; intCount < intCountToInsert; intCount++) {
            PMC_SS_AccountPartnerRelationships__c objPartner = new PMC_SS_AccountPartnerRelationships__c();
            objPartner.Name = 'Test Partner';
            objPartner.PMC_SS_Account__c = idAccount;
            objPartner.PMC_SS_RelatedAccount__c = idRelatedAccount;
            objPartner.PMC_SS_Type__c= 'Ship-to';
            
            lstPartnersToInsert.add(objPartner);
        }
            return lstPartnersToInsert;
    }


 }