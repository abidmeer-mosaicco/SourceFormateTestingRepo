/**
 * @description       : Wrapper class to hold the order related details
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-02-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

public with sharing class PMC_SS_CaseDetailsWrapper {

    /**
     * @description - Holds case id
    */
    @AuraEnabled
    public String caseId{get;set;}

    /**
     * @description - Holds orde id
    */
    @AuraEnabled
    public String orderId{get;set;}

    /**
     * @description - Holds order item id
    */
    @AuraEnabled
    public String orderItemId{get;set;}

    /**
     * @description - Holds invoice id
    */
    @AuraEnabled
    public String invoiceId{get;set;}

    /**
     * @description - Holds action reason
    */
    @AuraEnabled
    public String actionReason{get;set;}

    /**
     * @description - Holds account id
    */
    @AuraEnabled
    public String accountId{get;set;}

    /**
     * @description - Holds contact id
    */
    @AuraEnabled
    public String contactId{get;set;}

    /**
     * @description - Holds contract id
    */
    @AuraEnabled
    public String contractId{get;set;}

    /**
     * @description - Holds original invoice amount
    */
    @AuraEnabled
    public Decimal originalInvoiceAmount{get;set;}

    /**
     * @description - Holds invoice difference
    */
    @AuraEnabled
    public Decimal invoiceDifference{get;set;}

    /**
     * @description - Holds cancel amount
    */
    @AuraEnabled
    public Decimal cancelAmount{get;set;}

    /**
     * @description - Holds rebill amount
    */
    @AuraEnabled
    public Decimal rebillAmount{get;set;}

    /**
     * @description - Holds at fault party
    */
    @AuraEnabled
    public String atFaultParty{get;set;}

    /**
     * @description - Holds payment request type
    */
     @AuraEnabled
    public String location{get;set;}
    /**
     * @description - Holds payment request type
    */
    @AuraEnabled
    public String paymentRequestType{get;set;}

    /**
     * @description - Holds sold-to account id
    */
    @AuraEnabled
    public String soldToAccountId{get;set;}

    /**
     * @description - Holds ship-to account id
    */
    @AuraEnabled
    public String shipToAccountId{get;set;}

    /**
     * @description - Holds credit amount
    */
    @AuraEnabled
    public Decimal creditDebitAmount{get;set;}

    /**
     * @description - Holds return quantity
    */
    @AuraEnabled
    public Integer returnQuantity{get;set;}

    /**
     * @description - Holds return amount
    */
    @AuraEnabled
    public Decimal returnAmount{get;set;}

    /**
     * @description - Holds plant id
    */
    @AuraEnabled
    public String plantId{get;set;}

    /**
     * @description - Holds vehicle id
    */
    @AuraEnabled
    public String vehicleId{get;set;}

    /**
     * @description - Holds MOT
    */
    @AuraEnabled
    public String modeOfTransportation{get;set;}

    /**
     * @description - Holds PGI Date
    */
    @AuraEnabled
    public String pgiDate{get;set;}
}