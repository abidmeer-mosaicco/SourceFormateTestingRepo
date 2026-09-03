import { LightningElement } from 'lwc';
// Custom Labels For Technical Bulletin
import PMC_SS_SearchArticlesLabel from '@salesforce/label/c.PMC_SS_SearchArticlesLabel';
import PMC_SS_CloseLabel from '@salesforce/label/c.PMC_SS_CloseLabel';
import PMC_SS_TechnicalBulletin_Label from '@salesforce/label/c.PMC_SS_TechnicalBulletin_Label';
import PMC_SS_ViewAllLabel from '@salesforce/label/c.PMC_SS_ViewAllLabel';
// Service Now
import WarrantyFormalization_Instruction from '@salesforce/label/c.PMC_SS_SNOW_WarrantyFormalization_Instruction';
import RequestType_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_RequestType_FieldLabel';
import PMC_SS_SNOW_ContactName_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_ContactName_FieldLabel';
import PMC_SS_SNOW_ContactEmail_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_ContactEmail_FieldLabel';
import PMC_SS_SNOW_OrderNumberorContractNumber_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_OrderNumberorContractNumber_FieldLabel';
import PMC_SS_SNOW_AccountName_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_AccountName_FieldLabel';
import PMC_SS_SNOW_CustomerSAPCode_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_CustomerSAPCode_FieldLabel';
import PMC_SS_SNOW_Invoice_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_Invoice_FieldLabel';
import PMC_SS_SNOW_ContractNumber_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_ContractNumber_FieldLabel';
import PMC_SS_SNOW_ContractValue_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_ContractValue_FieldLabel';
import PMC_SS_SNOW_Business_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_Business_FieldLabel';
import PMC_SS_SNOW_Reason_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_Reason_FieldLabel';
import PMC_SS_SNOW_ExactDatetobePaid_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_ExactDatetobePaid_FieldLabel';
import PMC_SS_SNOW_SegmentManager_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_SegmentManager_FieldLabel';
import PMC_SS_SNOW_Program_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_Program_FieldLabel';
import PMC_SS_SNOW_AbatementContractNumber_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_AbatementContractNumber_FieldLabel';
import PMC_SS_SNOW_CaseNumber_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_CaseNumber_FieldLabel';
import PMC_SS_SNOW_Unity_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_Unity_Fieldlabel';
import PMC_SS_SNOW_ReasonDetail_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_ReasonDetail_FieldLabel';
import PMC_SS_SNOW_RecipientsofCircularizationLetter_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_RecipientsofCircularizationLetter_FieldLabel';
import PMC_SS_SNOW_InitialRequestPeriod_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_InitialRequestPeriod_FieldLabel';
import PMC_SS_SNOW_MosaicPayingReceivingCompany_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_MosaicPayingReceivingCompany_FieldLabel';
import PMC_SS_SNOW_CPR_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_CPR_FieldLabel';
import PMC_SS_SNOW_Mortgage_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_Mortgage_FieldLabel';
import PMC_SS_SNOW_InitialDate_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_InitialDate_FieldLabel';
import PMC_SS_SNOW_FinalDate_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_FinalDate_FieldLabel';
import PMC_SS_SNOW_CaseCurrency_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_CaseCurrency_FieldLabel';
import PMC_SS_SNOW_WarrantyType_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_WarrantyType_FieldLabel';
import PMC_SS_SNOW_FinancialOperationValue_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_FinancialOperationValue_FieldLabel';
import PMC_SS_SNOW_EndorsementValue_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_EndorsementValue_FieldLabel';
import PMC_SS_SNOW_PayeeName_FieldLabel from '@salesforce/label/c.PMC_SS_SNOW_PayeeName_FieldLabel';
import PMC_SS_Comments_FieldLabel from '@salesforce/label/c.PMC_SS_Comments_FieldLabel';
import PMC_SS_SNOW_Save_Label from '@salesforce/label/c.PMC_SS_SNOW_Save_Label';
import PMC_SS_ServiceNow_Label from '@salesforce/label/c.PMC_SS_ServiceNow_Label';
import PMC_SS_SNOW_CircularizationLetters_Instruction from '@salesforce/label/c.PMC_SS_SNOW_CircularizationLetters_Instruction';
import PMC_SS_SNOW_PerformWarranty_Instruction from '@salesforce/label/c.PMC_SS_SNOW_PerformWarranty_Instruction';
import PMC_SS_SNOW_CustomerCreditAnalysis_Instruction from '@salesforce/label/c.PMC_SS_SNOW_CustomerCreditAnalysis_Instruction';
import PMC_SS_SNOW_CollectionsPortal_Instruction from '@salesforce/label/c.PMC_SS_SNOW_CollectionsPortal_Instruction';
import PMC_SS_SNOW_DebitorCreditNotes_Instruction from '@salesforce/label/c.PMC_SS_SNOW_DebitorCreditNotes_Instruction';
import PMC_SS_SNOW_UseofCreditsReturnReceiptofDischargeandReports_InstructionOne from '@salesforce/label/c.PMC_SS_SNOW_UseofCreditsReturnReceiptofDischargeandReports_InstructionOne';
import PMC_SS_SNOW_UseofCreditsReturnReceiptofDischargeandReports_InstructionTwo from '@salesforce/label/c.PMC_SS_SNOW_UseofCreditsReturnReceiptofDischargeandReports_InstructionTwo';
import PMC_SS_SNOW_RequestType_KeyValue from '@salesforce/label/c.PMC_SS_SNOW_RequestType_KeyValue';
import select_ticketType from "@salesforce/label/c.PMC_SS_TicketType";
import PMC_SS_SNOW_Cancel_Label from "@salesforce/label/c.PMC_SS_SNOW_Cancel_Label";

// Dispute management 
import PMC_SS_Product_FieldLabel from '@salesforce/label/c.PMC_SS_Product_FieldLabel';
import PMC_SS_Tons_FieldLabel from '@salesforce/label/c.PMC_SS_Tons_FieldLabel';
import PMC_SS_UOM_FieldLabel from '@salesforce/label/c.PMC_SS_UOM_FieldLabel';
import PMC_SS_ShipFrom_FieldLabel from '@salesforce/label/c.PMC_SS_ShipFrom_FieldLabel';
import PMC_SS_ShipTo_FieldLabel from '@salesforce/label/c.PMC_SS_ShipTo_FieldLabel';
import PMC_SS_ShipmentDate_FieldLabel from '@salesforce/label/c.PMC_SS_ShipmentDate_FieldLabel';
import PMC_SS_OriginalInvoiceAmount_FieldLabel from '@salesforce/label/c.PMC_SS_OriginalInvoiceAmount_FieldLabel';
import PMC_SS_CancelAmount_FieldLabel from '@salesforce/label/c.PMC_SS_CancelAmount_FieldLabel';
import PMC_SS_RebillAmount_FieldLabel from '@salesforce/label/c.PMC_SS_RebillAmount_FieldLabel';
import PMC_SS_DollarAmount_FieldLabel from '@salesforce/label/c.PMC_SS_DollarAmount_FieldLabel';
import PMC_SS_InvoiceDifference_FieldLabel from '@salesforce/label/c.PMC_SS_InvoiceDifference_FieldLabel';
import PMC_SS_Account_FieldLabel from '@salesforce/label/c.PMC_SS_Account_FieldLabel';
import PMC_SS_Contact_FieldLabel from '@salesforce/label/c.PMC_SS_Contact_FieldLabel';
import PMC_SS_OriginalContract_FieldLabel from '@salesforce/label/c.PMC_SS_OriginalContract_FieldLabel';
import PMC_SS_CreditDebitAmount_FieldLabel from '@salesforce/label/c.PMC_SS_CreditDebitAmount_FieldLabel';
import PMC_SS_ReturnQuantity_FieldLabel from '@salesforce/label/c.PMC_SS_ReturnQuantity_FieldLabel';
import PMC_SS_ReturnAmount_FieldLabel from '@salesforce/label/c.PMC_SS_ReturnAmount_FieldLabel';
import PMC_SS_ShipToAccount_FieldLabel from '@salesforce/label/c.PMC_SS_ShipToAccount_FieldLabel';
import PMC_SS_SoldToAccount_FieldLabel from '@salesforce/label/c.PMC_SS_SoldToAccount_FieldLabel';
import PMC_SS_Plant_FieldLabel from '@salesforce/label/c.PMC_SS_Plant_FieldLabel';
import PMC_SS_ModeOfTransportation_FieldLabel from '@salesforce/label/c.PMC_SS_ModeOfTransportation_FieldLabel';
import PMC_SS_PGIDate_FieldLabel from '@salesforce/label/c.PMC_SS_PGIDate_FieldLabel';
import PMC_SS_CancelRebill_ScreenTitle from '@salesforce/label/c.PMC_SS_CancelRebill_ScreenTitle';
import PMC_SS_CreditDebit_ScreenTitle from '@salesforce/label/c.PMC_SS_CreditDebit_ScreenTitle';
import PMC_SS_Return_ScreenTitle from '@salesforce/label/c.PMC_SS_Return_ScreenTitle';
import PMC_SS_ReverseShipment_ScreenTitle from '@salesforce/label/c.PMC_SS_ReverseShipment_ScreenTitle';
import PMC_SS_SelectDeliveryItem_FieldLabel from "@salesforce/label/c.PMC_SS_SelectDeliveryItem_FieldLabel";
import PMC_SS_VehicleId_FieldLabel from "@salesforce/label/c.PMC_SS_VehicleId_FieldLabel";

// Error labels
import PMC_SS_SNOW_ServicenowTicketCreation_SuccessMessage from '@salesforce/label/c.PMC_SS_SNOW_ServicenowTicketCreation_SuccessMessage';
import PMC_SS_Caseupdated_MessageLabel from '@salesforce/label/c.PMC_SS_Caseupdated_MessageLabel';
import PMC_SS_Success_MessageLabel from '@salesforce/label/c.PMC_SS_Success_MessageLabel';
import PMC_SS_SNOW_ServiceNowTicketCreation_ErrorMessage from '@salesforce/label/c.PMC_SS_SNOW_ServiceNowTicketCreation_ErrorMessage';
import PMC_SS_PleasetryAgain_MessageLabel from '@salesforce/label/c.PMC_SS_PleasetryAgain_MessageLabel';
import PMC_SS_FailedtoUpdateRecord_ErrorMessage from '@salesforce/label/c.PMC_SS_FailedtoUpdateRecord_ErrorMessage';
import PMC_SS_FailedtoFetchData_ErrorMessage from '@salesforce/label/c.PMC_SS_FailedtoFetchData_ErrorMessage';
import PMC_SS_SelectTicketType_ErrorMessage from '@salesforce/label/c.PMC_SS_SelectTicketType_ErrorMessage';
import PMC_SS_SelectOption from '@salesforce/label/c.PMC_SS_SelectOption';





const customLabel = {
    PMC_SS_ViewAllLabel :PMC_SS_ViewAllLabel,
    PMC_SS_TechnicalBulletin_Label: PMC_SS_TechnicalBulletin_Label,
    PMC_SS_CloseLabel:PMC_SS_CloseLabel,
    PMC_SS_SearchArticlesLabel: PMC_SS_SearchArticlesLabel,
    //Service NOW
    WarrantyFormalization_Instruction: WarrantyFormalization_Instruction,
    RequestType_FieldLabel: RequestType_FieldLabel,
    PMC_SS_SNOW_ContactName_FieldLabel : PMC_SS_SNOW_ContactName_FieldLabel,
    PMC_SS_SNOW_ContactEmail_FieldLabel: PMC_SS_SNOW_ContactEmail_FieldLabel,
    PMC_SS_SNOW_OrderNumberorContractNumber_FieldLabel : PMC_SS_SNOW_OrderNumberorContractNumber_FieldLabel,
    PMC_SS_SNOW_AccountName_FieldLabel : PMC_SS_SNOW_AccountName_FieldLabel,
    PMC_SS_SNOW_CustomerSAPCode_FieldLabel : PMC_SS_SNOW_CustomerSAPCode_FieldLabel,
    PMC_SS_SNOW_Invoice_FieldLabel: PMC_SS_SNOW_Invoice_FieldLabel,
    PMC_SS_SNOW_ContractNumber_FieldLabel :PMC_SS_SNOW_ContractNumber_FieldLabel,
    PMC_SS_SNOW_ContractValue_FieldLabel : PMC_SS_SNOW_ContractValue_FieldLabel,
    PMC_SS_SNOW_Business_FieldLabel : PMC_SS_SNOW_Business_FieldLabel,
    PMC_SS_SNOW_Reason_FieldLabel : PMC_SS_SNOW_Reason_FieldLabel,
    PMC_SS_SNOW_ExactDatetobePaid_FieldLabel :PMC_SS_SNOW_ExactDatetobePaid_FieldLabel,
    PMC_SS_SNOW_SegmentManager_FieldLabel : PMC_SS_SNOW_SegmentManager_FieldLabel,
    PMC_SS_SNOW_Program_FieldLabel : PMC_SS_SNOW_Program_FieldLabel,
    PMC_SS_SNOW_AbatementContractNumber_FieldLabel: PMC_SS_SNOW_AbatementContractNumber_FieldLabel,
    PMC_SS_SNOW_CaseNumber_FieldLabel : PMC_SS_SNOW_CaseNumber_FieldLabel,
    PMC_SS_SNOW_ReasonDetail_FieldLabel : PMC_SS_SNOW_ReasonDetail_FieldLabel,
    PMC_SS_SNOW_Unity_FieldLabel :PMC_SS_SNOW_Unity_FieldLabel,
    PMC_SS_SNOW_RecipientsofCircularizationLetter_FieldLabel :PMC_SS_SNOW_RecipientsofCircularizationLetter_FieldLabel,
    PMC_SS_SNOW_InitialRequestPeriod_FieldLabel:PMC_SS_SNOW_InitialRequestPeriod_FieldLabel,
    PMC_SS_SNOW_MosaicPayingReceivingCompany_FieldLabel :PMC_SS_SNOW_MosaicPayingReceivingCompany_FieldLabel,
    PMC_SS_SNOW_CPR_FieldLabel : PMC_SS_SNOW_CPR_FieldLabel,
    PMC_SS_SNOW_Mortgage_FieldLabel :PMC_SS_SNOW_Mortgage_FieldLabel,
    PMC_SS_SNOW_InitialDate_FieldLabel :PMC_SS_SNOW_InitialDate_FieldLabel,
    PMC_SS_SNOW_FinalDate_FieldLabel :PMC_SS_SNOW_FinalDate_FieldLabel,
    PMC_SS_SNOW_CaseCurrency_FieldLabel :PMC_SS_SNOW_CaseCurrency_FieldLabel,
    PMC_SS_SNOW_WarrantyType_FieldLabel :PMC_SS_SNOW_WarrantyType_FieldLabel,
    PMC_SS_SNOW_FinancialOperationValue_FieldLabel :PMC_SS_SNOW_FinancialOperationValue_FieldLabel,
    PMC_SS_SNOW_EndorsementValue_FieldLabel :PMC_SS_SNOW_EndorsementValue_FieldLabel,
    PMC_SS_SNOW_PayeeName_FieldLabel :PMC_SS_SNOW_PayeeName_FieldLabel,
    PMC_SS_Comments_FieldLabel :PMC_SS_Comments_FieldLabel,
    PMC_SS_SNOW_Save_Label : PMC_SS_SNOW_Save_Label,
    PMC_SS_ServiceNow_Label :PMC_SS_ServiceNow_Label,
    PMC_SS_SNOW_CircularizationLetters_Instruction :PMC_SS_SNOW_CircularizationLetters_Instruction,
    PMC_SS_SNOW_PerformWarranty_Instruction : PMC_SS_SNOW_PerformWarranty_Instruction,
    PMC_SS_SNOW_CustomerCreditAnalysis_Instruction,PMC_SS_SNOW_CollectionsPortal_Instruction,PMC_SS_SNOW_DebitorCreditNotes_Instruction,
    PMC_SS_SNOW_UseofCreditsReturnReceiptofDischargeandReports_InstructionOne,
    PMC_SS_SNOW_UseofCreditsReturnReceiptofDischargeandReports_InstructionTwo,
    PMC_SS_SNOW_RequestType_KeyValue,select_ticketType,PMC_SS_SNOW_Cancel_Label,
    // dispute management 
    PMC_SS_Product_FieldLabel  : PMC_SS_Product_FieldLabel,
    PMC_SS_SelectDeliveryItem_FieldLabel : PMC_SS_SelectDeliveryItem_FieldLabel,
    PMC_SS_VehicleId_FieldLabel : PMC_SS_VehicleId_FieldLabel,
    PMC_SS_Tons_FieldLabel  : PMC_SS_Tons_FieldLabel,
    PMC_SS_UOM_FieldLabel : PMC_SS_UOM_FieldLabel,
    PMC_SS_ShipTo_FieldLabel : PMC_SS_ShipTo_FieldLabel,
    PMC_SS_ShipmentDate_FieldLabel : PMC_SS_ShipmentDate_FieldLabel,
    PMC_SS_OriginalInvoiceAmount_FieldLabel : PMC_SS_OriginalInvoiceAmount_FieldLabel,
    PMC_SS_CancelAmount_FieldLabel : PMC_SS_CancelAmount_FieldLabel,
    PMC_SS_RebillAmount_FieldLabel  :PMC_SS_RebillAmount_FieldLabel,
    PMC_SS_DollarAmount_FieldLabel  :PMC_SS_DollarAmount_FieldLabel,
    PMC_SS_InvoiceDifference_FieldLabel  :PMC_SS_InvoiceDifference_FieldLabel,
    PMC_SS_Account_FieldLabel  :PMC_SS_Account_FieldLabel,
    PMC_SS_Contact_FieldLabel  :PMC_SS_Contact_FieldLabel,
    PMC_SS_OriginalContract_FieldLabel  :PMC_SS_OriginalContract_FieldLabel,
    PMC_SS_CreditDebitAmount_FieldLabel  :PMC_SS_CreditDebitAmount_FieldLabel,
    PMC_SS_ReturnQuantity_FieldLabel :PMC_SS_ReturnQuantity_FieldLabel,
    PMC_SS_ReturnAmount_FieldLabel :PMC_SS_ReturnAmount_FieldLabel,
    PMC_SS_ShipToAccount_FieldLabel :PMC_SS_ShipToAccount_FieldLabel,
    PMC_SS_SoldToAccount_FieldLabel  :PMC_SS_SoldToAccount_FieldLabel,
    PMC_SS_Plant_FieldLabel  :PMC_SS_Plant_FieldLabel,
    PMC_SS_ModeOfTransportation_FieldLabel  :PMC_SS_ModeOfTransportation_FieldLabel,
    PMC_SS_PGIDate_FieldLabel  :PMC_SS_PGIDate_FieldLabel,
    PMC_SS_Comments_FieldLabel  :PMC_SS_Comments_FieldLabel,
    PMC_SS_ShipFrom_FieldLabel :PMC_SS_ShipFrom_FieldLabel,
    PMC_SS_ReverseShipment_ScreenTitle :PMC_SS_ReverseShipment_ScreenTitle,
    PMC_SS_Return_ScreenTitle : PMC_SS_Return_ScreenTitle,
    PMC_SS_CreditDebit_ScreenTitle :PMC_SS_CreditDebit_ScreenTitle,
    PMC_SS_CancelRebill_ScreenTitle :PMC_SS_CancelRebill_ScreenTitle,

    //Error Message
    PMC_SS_SNOW_ServicenowTicketCreation_SuccessMessage : PMC_SS_SNOW_ServicenowTicketCreation_SuccessMessage,
    PMC_SS_Caseupdated_MessageLabel : PMC_SS_Caseupdated_MessageLabel,
    PMC_SS_Success_MessageLabel :PMC_SS_Success_MessageLabel,
    PMC_SS_SNOW_ServiceNowTicketCreation_ErrorMessage :PMC_SS_SNOW_ServiceNowTicketCreation_ErrorMessage,
    PMC_SS_FailedtoFetchData_ErrorMessage : PMC_SS_FailedtoFetchData_ErrorMessage,
    PMC_SS_FailedtoUpdateRecord_ErrorMessage : PMC_SS_FailedtoUpdateRecord_ErrorMessage,
    PMC_SS_PleasetryAgain_MessageLabel : PMC_SS_PleasetryAgain_MessageLabel,
    PMC_SS_SelectTicketType_ErrorMessage :PMC_SS_SelectTicketType_ErrorMessage,
    PMC_SS_SelectOption : PMC_SS_SelectOption

};

export {customLabel};
 
export default class Pmc_ss_customLabelUtility extends LightningElement {}