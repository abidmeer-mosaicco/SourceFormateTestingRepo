/**
 * @description This class is the wrapper class for the FPD LWC datatable columns.
 *	This class has no methods.Its just used for serializing and deserializing the column values.
 * @author Ridhu Varshini M
 * @storynumber GDASF-12110
 */
public with sharing class PMC_CPQ_OrderProductDetailsWrapperClass {
	@AuraEnabled
	public String customId;
	@AuraEnabled
	public String orderLine;
	@AuraEnabled
	public String productName;
	@AuraEnabled
	public Decimal quantity;
	@AuraEnabled
	public Date priceByDate;
	@AuraEnabled
	public String accountName;
	@AuraEnabled
	public Decimal freight;
	@AuraEnabled
	public Decimal fpdPrice;
	@AuraEnabled
	public Decimal finalAgreedPrice;
	@AuraEnabled
	public String status;
	@AuraEnabled
	public String orderNum;
	@AuraEnabled
	public String contractNum;
	@AuraEnabled
	public String po;
	@AuraEnabled
	public String shipTo;
	@AuraEnabled
	public String integrationMessage;
	@AuraEnabled
	public String sapOrderNumber;
	@AuraEnabled
	public String sapOrderLineID;
	@AuraEnabled
	public String approvalStatus;
    @AuraEnabled
	public String rejectedReason; //GCPM-5209
	@AuraEnabled
	public String integrationStatus { get; set; }  //GCPM-3644
	
}