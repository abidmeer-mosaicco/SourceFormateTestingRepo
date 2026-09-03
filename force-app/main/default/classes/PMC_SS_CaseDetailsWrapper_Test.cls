@IsTest
public class PMC_SS_CaseDetailsWrapper_Test {
   @IsTest
   static void testWrapper() {
       // Instantiate wrapper
       PMC_SS_CaseDetailsWrapper wrapper = new PMC_SS_CaseDetailsWrapper();
       // Set all properties (dummy values)
       wrapper.caseId = 'CASE123';
       wrapper.orderId = 'ORDER123';
       wrapper.orderItemId = 'ITEM123';
       wrapper.invoiceId = 'INV123';
       wrapper.actionReason = 'TestReason';
       wrapper.accountId = 'ACCOUNT123';
       wrapper.contactId = 'CONTACT123';
       wrapper.contractId = 'CONTRACT123';
       wrapper.originalInvoiceAmount = 100.0;
       wrapper.invoiceDifference = 10.0;
       wrapper.cancelAmount = 5.0;
       wrapper.rebillAmount = 15.0;
       wrapper.atFaultParty = 'Supplier';
       wrapper.location = 'Warehouse1';
       wrapper.paymentRequestType = 'Credit';
       wrapper.soldToAccountId = 'SOLD123';
       wrapper.shipToAccountId = 'SHIP123';
       wrapper.creditDebitAmount = 50.0;
       wrapper.returnQuantity = 2;
       wrapper.returnAmount = 25.0;
       wrapper.plantId = 'PLANT1';
       wrapper.vehicleId = 'VEH123';
       wrapper.modeOfTransportation = 'Truck';
       wrapper.pgiDate = '2025-09-08';
       // Assert a few fields
       System.assertEquals('CASE123', wrapper.caseId);
       System.assertEquals(100.0, wrapper.originalInvoiceAmount);
       System.assertEquals(2, wrapper.returnQuantity);
       System.assertEquals('Truck', wrapper.modeOfTransportation);
   }
}