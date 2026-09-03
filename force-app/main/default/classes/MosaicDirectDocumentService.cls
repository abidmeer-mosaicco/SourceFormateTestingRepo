/**
 * @description       : Service Class for view and download Documents
 **/
global without sharing class MosaicDirectDocumentService {
  /**
   *  Wrapper class for invoice result
   */
  public class InvoiceResult {
    @AuraEnabled
    public Boolean success;
    @AuraEnabled
    public String message;
    @AuraEnabled
    public String invoiceNumber;
    @AuraEnabled
    public String orderNumber;
    @AuraEnabled
    public String orderId;

    public InvoiceResult() {
      this.success = false;
    }

    public InvoiceResult(Boolean success, String message) {
      this.success = success;
      this.message = message;
    }
  }

  /**
   *  Wrapper class for download result
   */
  public class DocumentDownloadResult {
    @AuraEnabled
    public Boolean success;
    @AuraEnabled
    public String message;
    @AuraEnabled
    public String pdfData;

    public DocumentDownloadResult() {
      this.success = false;
    }

    public DocumentDownloadResult(Boolean success, String message) {
      this.success = success;
      this.message = message;
    }
  }

  /**
   *  Wrapper class for BOL/COA document information
   */
  public class DocumentInfo {
    @AuraEnabled
    public Boolean success;
    @AuraEnabled
    public String message;
    @AuraEnabled
    public String deliveryNumber;
    @AuraEnabled
    public String itemNumber;
    @AuraEnabled
    public String shipmentItemId;

    public DocumentInfo() {
      this.success = false;
    }

    public DocumentInfo(Boolean success, String message) {
      this.success = success;
      this.message = message;
    }
  }

  /**
   *  Wrapper class for Download All result
   */
  public class DownloadAllResult {
    @AuraEnabled
    public Boolean success;
    @AuraEnabled
    public String message;
    @AuraEnabled
    public DocumentDownloadResult invoiceResult;
    @AuraEnabled
    public DocumentDownloadResult bolResult;
    @AuraEnabled
    public DocumentDownloadResult coaResult;
    @AuraEnabled
    public Integer totalDocuments;
    @AuraEnabled
    public Integer successfulDownloads;

    public DownloadAllResult() {
      this.success = false;
      this.totalDocuments = 0;
      this.successfulDownloads = 0;
    }
  }

  /**
   * Extract the item number after the underscore
   * Example: "85594085_000001" -> "000001"
   * @param itemNumber The original item number
   * @return String The processed item number
   */
  private static String extractItemNumberAfterUnderscore(String itemNumber) {
    if (String.isBlank(itemNumber) || !itemNumber.contains('_')) {
      return itemNumber;
    }
    return itemNumber.substringAfterLast('_');
  }

  /**
   * Public wrapper for testing item number extraction
   * @param itemNumber The original item number
   * @return String The processed item number
   */
  @AuraEnabled
  global static String processItemNumber(String itemNumber) {
    return extractItemNumberAfterUnderscore(itemNumber);
  }

  /**
   *  Get Invoice Number and Order Number from Order ID
   * param orderId The Order record ID
   * return Map containing success status, invoice number, and order number
   */
  @AuraEnabled
  global static Map<String, Object> getInvoiceNumber(String shipmentItemId) {
    Map<String, Object> result = new Map<String, Object>();
    result.put('success', false);

    try {
      if (String.isBlank(shipmentItemId)) {
        result.put('message', 'Shipment ID is required');
        return result;
      }

      ShipmentItem shipmentItem = [SELECT Id, PMC_CPQ_OrderProduct__c FROM ShipmentItem WHERE Id = :shipmentItemId LIMIT 1] ?? null;
      if (shipmentItem == null) return result;

      PMC_CPQ_InvoiceItem__c invoiceItem = [
        SELECT 
          Id, 
          PMC_CPQ_Invoice__r.PMC_CPQ_InvoiceNumber__c, 
          PMC_CPQ_DeliveryItem__c, 
          PMC_CPQ_DeliveryItem__r.PMC_CPQ_OrderProduct__c 
        FROM PMC_CPQ_InvoiceItem__c 
        WHERE PMC_CPQ_DeliveryItem__r.PMC_CPQ_OrderProduct__c = :shipmentItem.PMC_CPQ_OrderProduct__c 
        AND PMC_CPQ_Invoice__r.PMC_CPQ_Cancelled__c = false
        ORDER BY CreatedDate DESC
        LIMIT 1
      ] ?? null;

      if (invoiceItem == null) {
        invoiceItem = [
          SELECT 
            Id, 
            PMC_CPQ_Invoice__r.PMC_CPQ_InvoiceNumber__c, 
            PMC_CPQ_DeliveryItem__c, 
            PMC_CPQ_DeliveryItem__r.PMC_CPQ_OrderProduct__c 
          FROM PMC_CPQ_InvoiceItem__c 
          WHERE PMC_CPQ_DeliveryItem__r.PMC_CPQ_OrderProduct__c = :shipmentItem.PMC_CPQ_OrderProduct__c 
          ORDER BY CreatedDate DESC
          LIMIT 1
        ] ?? null;
      }

      OrderItem orderItem = [
        SELECT Id, OrderId, Order.PMC_CPQ_SAPOrderNumber__c
        FROM OrderItem
        WHERE Id = :shipmentItem.PMC_CPQ_OrderProduct__c
        LIMIT 1
      ] ?? null;

      // Get the Order Number
      // List<Order> orders = [
      //   SELECT Id, PMC_CPQ_SAPOrderNumber__c
      //   FROM Order
      //   WHERE Id = :orderId
      //   LIMIT 1
      // ];

      // if (orders.isEmpty()) {
      //   result.put('success', false);
      //   result.put('message', 'Order not found');
      //   return result;
      // }

      // Order order = orders[0];
      // String orderNumber = order.PMC_CPQ_SAPOrderNumber__c;

      // // Get Invoice related to the Order
      // List<PMC_CPQ_Invoice__c> invoices = [
      //   SELECT Id, PMC_CPQ_InvoiceNumber__c, PMC_CPQ_Order__c
      //   FROM PMC_CPQ_Invoice__c
      //   WHERE PMC_CPQ_Order__c = :orderId
      //   LIMIT 1
      // ];

      if (orderItem == null) {
        result.put('success', false);
        result.put('message', 'No Order Item found');
        return result;
      }

      if (invoiceItem == null) {
        result.put('success', false);
        result.put('message', 'No Invoice found for this Order Item');
        return result;
      }

      String invoiceNumber = invoiceItem?.PMC_CPQ_Invoice__r?.PMC_CPQ_InvoiceNumber__c;
      if (String.isBlank(invoiceNumber)) {
        result.put('success', false);
        result.put('message', 'Invoice Number is not populated');
        return result;
      }

      result.put('success', true);
      result.put('invoiceNumber', invoiceNumber);
      result.put('orderNumber', orderItem.Order.PMC_CPQ_SAPOrderNumber__c);
      result.put('orderId', orderItem.OrderId);
      result.put('message', 'Invoice information retrieved successfully');

      return result;
    } catch (Exception e) {
      result.put('success', false);
      result.put('message', 'Error retrieving Invoice: ' + e.getMessage());
      return result;
    }
  }

  /**
   * Get Order ID from OrderItem ID (for ShipmentItem relationship)
   * param orderItemId The OrderItem record ID
   * return String Order ID or null if not found
   */
  @AuraEnabled
  global static String getOrderIdFromOrderItem(String orderItemId) {
    try {
      if (String.isBlank(orderItemId)) {
        return null;
      }

      // Check if it's a ShipmentItem ID (starts with 0ob)
      if (orderItemId.startsWith('0ob')) {
        // Query ShipmentItem to get the OrderItem ID
        List<ShipmentItem> shipmentItems = [
          SELECT PMC_CPQ_OrderProduct__c
          FROM ShipmentItem
          WHERE Id = :orderItemId
          LIMIT 1
        ];

        if (shipmentItems.isEmpty() || String.isBlank(shipmentItems[0].PMC_CPQ_OrderProduct__c)) {
          return null;
        }

        String orderProductId = shipmentItems[0].PMC_CPQ_OrderProduct__c;

        // Check if OrderProduct ID is Order ID (801) or OrderItem ID (802/0o8)
        if (orderProductId.startsWith('801')) {
          return orderProductId;
        } else {
          // It's an OrderItem ID, need to get Order ID
          orderItemId = orderProductId;
        }
      }
      List<OrderItem> orderItems = [
        SELECT OrderId
        FROM OrderItem
        WHERE Id = :orderItemId
        LIMIT 1
      ];

      if (orderItems.isEmpty()) {
        return null;
      }

      return orderItems[0].OrderId;
    } catch (Exception e) {
      return null;
    }
  }

  /**
   * Download Invoice PDF from SAP
   * param strBillingDocNumber The billing document number (Invoice Number)
   * return Map containing success status and PDF data
   */
  @AuraEnabled
  global static Map<String, Object> downloadInvoice(String strBillingDocNumber) {
    Map<String, Object> result = new Map<String, Object>();

    try {
      if (String.isBlank(strBillingDocNumber)) {
        result.put('success', false);
        result.put('message', 'Billing Document Number is required');
        return result;
      }

      // Call SAP service
      HttpResponse response = MosaicDirectDocumentApiService.getInvoiceDoc(strBillingDocNumber);

      if (response != null && response.getStatusCode() == 200) {
        // Parse response
        String responseBody = response.getBody();
        PMC_DH_DocumentResponseWrapper resWrapper = (PMC_DH_DocumentResponseWrapper) JSON.deserialize(
          responseBody,
          PMC_DH_DocumentResponseWrapper.class
        );

        if (resWrapper != null && resWrapper.objData != null) {
          if (resWrapper.objData.strStatusCode == 'S') {
            // Check if PDF data is actually present and valid
            String pdfData = resWrapper.objData.strData;
            if (String.isBlank(pdfData)) {
              result.put('success', false);
              result.put('message', 'Documento não encontrado');
              return result;
            } else {
              // Success - return PDF data
              result.put('success', true);
              result.put('pdfData', pdfData); // Base64 PDF data
              result.put('message', 'Invoice downloaded successfully');
            }
          } else {
            // SAP returned error
            result.put('success', false);
            result.put('message', 'SAP Error: ' + resWrapper.objData.strMessage);
            return result;
          }
        } else {
          result.put('success', false);
          result.put('message', 'Invalid response format from SAP');
          return result;
        }
      } else {
        String statusCode = response != null ? String.valueOf(response.getStatusCode()) : 'null';
        result.put('success', false);
        result.put('message', 'HTTP Error: ' + statusCode);
        return result;
      }
    } catch (Exception e) {
      result.put('success', false);
      result.put('message', 'Exception during Invoice download: ' + e.getMessage());
    }

    return result;
  }

  /**
   * Bulk method to get invoice numbers for multiple orders
   * param orderIds List of Order IDs
   * return List of InvoiceResult for each order
   */
  @AuraEnabled
  public static List<InvoiceResult> getInvoiceNumbersBulk(List<String> orderIds) {
    List<InvoiceResult> results = new List<InvoiceResult>();

    if (orderIds == null || orderIds.isEmpty()) {
      return results;
    }

    try {
      // Validate object access
      if (!Schema.sObjectType.Order.isAccessible() || !Schema.sObjectType.PMC_CPQ_Invoice__c.isAccessible()) {
        for (String orderId : orderIds) {
          results.add(new InvoiceResult(false, 'No access to required objects'));
        }
        return results;
      }

      // Bulk query orders
      Map<Id, Order> ordersMap = new Map<Id, Order>(
        [
          SELECT Id, PMC_CPQ_SAPOrderNumber__c
          FROM Order
          WHERE Id IN :orderIds
        ]
      );

      // Bulk query invoices
      Map<Id, PMC_CPQ_Invoice__c> invoicesMap = new Map<Id, PMC_CPQ_Invoice__c>();
      for (PMC_CPQ_Invoice__c invoice : [
        SELECT PMC_CPQ_Order__c, PMC_CPQ_InvoiceNumber__c
        FROM PMC_CPQ_Invoice__c
        WHERE PMC_CPQ_Order__c IN :orderIds
      ]) {
        invoicesMap.put(invoice.PMC_CPQ_Order__c, invoice);
      }

      // Process results
      for (String orderId : orderIds) {
        InvoiceResult result = new InvoiceResult();
        result.orderId = orderId;

        if (!ordersMap.containsKey(orderId)) {
          result.success = false;
          result.message = 'Order not found';
        } else if (!invoicesMap.containsKey(orderId)) {
          result.success = false;
          result.message = 'No Invoice found for this Order';
        } else {
          Order order = ordersMap.get(orderId);
          PMC_CPQ_Invoice__c invoice = invoicesMap.get(orderId);

          if (String.isBlank(invoice.PMC_CPQ_InvoiceNumber__c)) {
            result.success = false;
            result.message = 'Invoice Number is not populated';
          } else {
            result.success = true;
            result.invoiceNumber = invoice.PMC_CPQ_InvoiceNumber__c;
            result.orderNumber = order.PMC_CPQ_SAPOrderNumber__c;
            result.message = 'Invoice information retrieved successfully';
          }
        }

        results.add(result);
      }
    } catch (Exception e) {
      // If bulk operation fails, return error for all
      for (String orderId : orderIds) {
        results.add(new InvoiceResult(false, 'Bulk operation error: ' + e.getMessage()));
      }
    }

    return results;
  }

  /**
   * Get document information from ShipmentItem ID
   * For BOL: strBillingDocNumber = PMC_CPQ_DeliveryItemID__c (part before underscore)
   * For COA: strBillingDocNumber = PMC_CPQ_DeliveryItemID__c (part before underscore), strItemNumber = PMC_CPQ_DeliveryItemID__c (full value)
   * param shipmentItemId The ShipmentItem record ID
   * return Map containing deliveryNumber, itemNumber, orderItemNumber, and orderNumber for filename generation
   */
  @AuraEnabled
  global static Map<String, Object> getDocumentInfo(String shipmentItemId) {
    Map<String, Object> result = new Map<String, Object>();
    try {
      if (String.isBlank(shipmentItemId)) {
        result.put('success', false);
        result.put('message', 'ShipmentItem ID is required');
        return result;
      }

      String FPDrecordTypeId = Schema.SObjectType.Shipment
        .getRecordTypeInfosByName()
        .get('FPD Delivery')
        .getRecordTypeId();

      List<ShipmentItem> shipmentItems = [
        SELECT
          Id,
          ShipmentId,
          PMC_CPQ_DeliveryItemID__c,
          PMC_CPQ_OrderProduct__c,
          PMC_CPQ_OrderProduct__r.OrderItemNumber__c,
          PMC_CPQ_OrderProduct__r.OrderId,
          PMC_CPQ_OrderProduct__r.Order.PMC_CPQ_SAPOrderNumber__c
        FROM ShipmentItem
        WHERE Id = :shipmentItemId
        LIMIT 1
      ];

      if (shipmentItems.isEmpty()) {
        result.put('success', false);
        result.put('message', 'ShipmentItem not found');
        return result;
      }

      ShipmentItem shipmentItem = shipmentItems[0];
      Id currentShipmentId = shipmentItem.ShipmentId;
      Id orderItemId = shipmentItem.PMC_CPQ_OrderProduct__c;

      List<Shipment> shipments = [
        SELECT
          Id,
          Status,
          PMC_CPQ_DeliveryStatus__c,
          RecordTypeId,
          PMC_CPQ_Order__c
        FROM Shipment
        WHERE Id = :currentShipmentId
        LIMIT 1
      ];

      if (shipments.isEmpty()) {
        result.put('success', false);
        result.put('message', 'Shipment not found');
        return result;
      }

      Shipment currentShipment = shipments[0];
      String orderId = currentShipment.PMC_CPQ_Order__c;

      if (String.isNotBlank(orderId)) {
        List<Shipment> shipmentsFPD = [
          SELECT Id
          FROM Shipment
          WHERE PMC_CPQ_Order__c = :orderId
          AND RecordTypeId = :FPDrecordTypeId
          AND Status != 'Delivery Deleted'
          AND PMC_CPQ_DeliveryStatus__c = 'Completely Shipped'
        ];

        if (!shipmentsFPD.isEmpty()) {
          Set<Id> shipmentIds = new Set<Id>();
          for (Shipment ship : shipmentsFPD) {
            shipmentIds.add(ship.Id);
          }

          List<ShipmentItem> finalShipmentItems = [
            SELECT
              Id,
              ShipmentId,
              PMC_CPQ_DeliveryItemID__c,
              PMC_CPQ_OrderProduct__r.OrderItemNumber__c,
              PMC_CPQ_OrderProduct__r.OrderId,
              PMC_CPQ_OrderProduct__r.Order.PMC_CPQ_SAPOrderNumber__c
            FROM ShipmentItem
            WHERE ShipmentId IN :shipmentIds AND PMC_CPQ_OrderProduct__c = :orderItemId
            LIMIT 1
          ];

          if (!finalShipmentItems.isEmpty()) {
            shipmentItem = finalShipmentItems[0];
          }
        }
      }

      if (String.isBlank(shipmentItem.PMC_CPQ_DeliveryItemID__c)) {
        result.put('success', false);
        result.put('message', 'Delivery Item ID (PMC_CPQ_DeliveryItemID__c) is not populated');
        return result;
      }

      String deliveryItemId = shipmentItem.PMC_CPQ_DeliveryItemID__c;
      String deliveryNumber = deliveryItemId.contains('_') 
        ? deliveryItemId.substringBefore('_') 
        : deliveryItemId;

      result.put('success', true);
      result.put('deliveryNumber', deliveryNumber);
      result.put('itemNumber', shipmentItem.PMC_CPQ_DeliveryItemID__c);
      result.put('orderItemNumber', shipmentItem.PMC_CPQ_OrderProduct__r?.OrderItemNumber__c);
      result.put('orderNumber', shipmentItem.PMC_CPQ_OrderProduct__r?.Order?.PMC_CPQ_SAPOrderNumber__c);
      result.put('shipmentItemId', shipmentItem.Id);
      result.put('message', 'Document information retrieved successfully');

      return result;
    } catch (Exception e) {
      result.put('success', false);
      result.put('message', 'Error retrieving document info: ' + e.getMessage());
      return result;
    }
  }

  /**
   * Download BOL document from SAP
   * param strBillingDocNumber The delivery number (part before underscore from PMC_CPQ_DeliveryItemID__c)
   * return Map containing success status and PDF data
   */
  @AuraEnabled
  global static Map<String, Object> downloadBOL(String strBillingDocNumber) {
    Map<String, Object> result = new Map<String, Object>();

    try {
      if (String.isBlank(strBillingDocNumber)) {
        result.put('success', false);
        result.put('message', 'Billing Document Number (Delivery Number) is required');
        return result;
      }

      // Call SAP service through dedicated integration layer
      HttpResponse response = MosaicDirectDocumentApiService.getBOLDoc(strBillingDocNumber);

      if (response != null && response.getStatusCode() == 200) {
        // Parse response
        String responseBody = response.getBody();
        PMC_DH_DocumentResponseWrapper resWrapper = (PMC_DH_DocumentResponseWrapper) JSON.deserialize(
          responseBody,
          PMC_DH_DocumentResponseWrapper.class
        );

        if (resWrapper != null && resWrapper.objData != null) {
          if (resWrapper.objData.strStatusCode == 'S') {
            // Check if PDF data is actually present and valid
            String pdfData = resWrapper.objData.strData;
            if (String.isBlank(pdfData)) {
              result.put('success', false);
              result.put('message', 'BOL documento não encontrado');
              return result;
            } else {
              // Success - return PDF data
              result.put('success', true);
              result.put('pdfData', pdfData); // Base64 PDF data
              result.put('message', 'BOL downloaded successfully');
            }
          } else {
            // SAP returned error
            result.put('success', false);
            result.put('message', 'SAP Error: ' + resWrapper.objData.strMessage);
            return result;
          }
        } else {
          result.put('success', false);
          result.put('message', 'Invalid response format from SAP');
          return result;
        }
      } else {
        String statusCode = response != null ? String.valueOf(response.getStatusCode()) : 'null';
        result.put('success', false);
        result.put('message', 'HTTP Error: ' + statusCode);
        return result;
      }
    } catch (Exception e) {
      result.put('success', false);
      result.put('message', 'Exception during BOL download: ' + e.getMessage());
    }

    return result;
  }

  /**
   * Download COA document from SAP
   * param strBillingDocNumber The delivery number (part before underscore from PMC_CPQ_DeliveryItemID__c)
   * param strItemNumber The Delivery Item ID (PMC_CPQ_DeliveryItemID__c) - will be processed to extract value after underscore
   * return Map containing success status and PDF data
   */
  @AuraEnabled
  global static Map<String, Object> downloadCOA(String strBillingDocNumber, String strItemNumber) {
    Map<String, Object> result = new Map<String, Object>();

    try {
      if (String.isBlank(strBillingDocNumber)) {
        result.put('success', false);
        result.put('message', 'Billing Document Number (Delivery Number) is required');
        return result;
      }

      if (String.isBlank(strItemNumber)) {
        result.put('success', false);
        result.put('message', 'Item Number is required');
        return result;
      }

      // Extract item number after underscore for SAP call
      String processedItemNumber = extractItemNumberAfterUnderscore(strItemNumber);

      // Call SAP service through dedicated integration layer
      HttpResponse response = MosaicDirectDocumentApiService.getCOADoc(strBillingDocNumber, processedItemNumber);

      if (response != null && response.getStatusCode() == 200) {
        // Parse response
        String responseBody = response.getBody();
        PMC_DH_DocumentResponseWrapper resWrapper = (PMC_DH_DocumentResponseWrapper) JSON.deserialize(
          responseBody,
          PMC_DH_DocumentResponseWrapper.class
        );

        if (resWrapper != null && resWrapper.objData != null) {
          if (resWrapper.objData.strStatusCode == 'S') {
            // Check if PDF data is actually present and valid
            String pdfData = resWrapper.objData.strData;
            if (String.isBlank(pdfData)) {
              result.put('success', false);
              result.put('message', 'COA documento não encontrado');
              return result;
            } else {
              // Success - return PDF data
              result.put('success', true);
              result.put('pdfData', pdfData); // Base64 PDF data
              result.put('message', 'COA downloaded successfully');
            }
          } else {
            // SAP returned error
            result.put('success', false);
            result.put('message', 'SAP Error: ' + resWrapper.objData.strMessage);
            return result;
          }
        } else {
          result.put('success', false);
          result.put('message', 'Invalid response format from SAP');
          return result;
        }
      } else {
        String statusCode = response != null ? String.valueOf(response.getStatusCode()) : 'null';
        result.put('success', false);
        result.put('message', 'HTTP Error: ' + statusCode);
        return result;
      }
    } catch (Exception e) {
      result.put('success', false);
      result.put('message', 'Exception during COA download: ' + e.getMessage());
    }

    return result;
  }

  /**
   * Download all documents (Invoice, BOL, COA) for a given Order and ShipmentItem
   * param orderId The Order record ID
   * param shipmentItemId The ShipmentItem record ID
   * return Map containing all download results
   */
  @AuraEnabled
  global static Map<String, Object> downloadAllDocuments(String orderId, String shipmentItemId) {
    Map<String, Object> result = new Map<String, Object>();
    result.put('totalDocuments', 3);
    result.put('successfulDownloads', 0);

    try {
      Integer successfulDownloads = 0;

      // 1. Download Invoice
      if (String.isNotBlank(shipmentItemId)) {
        Map<String, Object> invoiceNumberResult = getInvoiceNumber(shipmentItemId);
        if ((Boolean) invoiceNumberResult.get('success')) {
          String invoiceNumber = (String) invoiceNumberResult.get('invoiceNumber');
          Map<String, Object> invoiceDownloadResult = downloadInvoice(invoiceNumber);

          Map<String, Object> invoiceResult = new Map<String, Object>();
          invoiceResult.put('success', (Boolean) invoiceDownloadResult.get('success'));
          invoiceResult.put('message', (String) invoiceDownloadResult.get('message'));
          invoiceResult.put('pdfData', (String) invoiceDownloadResult.get('pdfData'));
          result.put('invoiceResult', invoiceResult);

          if ((Boolean) invoiceResult.get('success')) {
            successfulDownloads++;
          }
        } else {
          Map<String, Object> invoiceResult = new Map<String, Object>();
          invoiceResult.put('success', false);
          invoiceResult.put('message', (String) invoiceNumberResult.get('message'));
          invoiceResult.put('pdfData', null);
          result.put('invoiceResult', invoiceResult);
        }
      } else {
        Map<String, Object> invoiceResult = new Map<String, Object>();
        invoiceResult.put('success', false);
        invoiceResult.put('message', 'Shipment Item ID not provided');
        invoiceResult.put('pdfData', null);
        result.put('invoiceResult', invoiceResult);
      }

      // 2. Download BOL and COA (require ShipmentItem)
      if (String.isNotBlank(shipmentItemId)) {
        Map<String, Object> docInfo = getDocumentInfo(shipmentItemId);

        if ((Boolean) docInfo.get('success')) {
          String deliveryNumber = (String) docInfo.get('deliveryNumber');
          String itemNumber = (String) docInfo.get('itemNumber');

          // Download BOL
          Map<String, Object> bolDownloadResult = downloadBOL(deliveryNumber);
          Map<String, Object> bolResult = new Map<String, Object>();
          bolResult.put('success', (Boolean) bolDownloadResult.get('success'));
          bolResult.put('message', (String) bolDownloadResult.get('message'));
          bolResult.put('pdfData', (String) bolDownloadResult.get('pdfData'));
          result.put('bolResult', bolResult);

          if ((Boolean) bolResult.get('success')) {
            successfulDownloads++;
          }

          // Download COA
          Map<String, Object> coaDownloadResult = downloadCOA(deliveryNumber, itemNumber);
          Map<String, Object> coaResult = new Map<String, Object>();
          coaResult.put('success', (Boolean) coaDownloadResult.get('success'));
          coaResult.put('message', (String) coaDownloadResult.get('message'));
          coaResult.put('pdfData', (String) coaDownloadResult.get('pdfData'));
          result.put('coaResult', coaResult);

          if ((Boolean) coaResult.get('success')) {
            successfulDownloads++;
          }
        } else {
          String errorMsg = 'Failed to get document info: ' + (String) docInfo.get('message');

          Map<String, Object> bolResult = new Map<String, Object>();
          bolResult.put('success', false);
          bolResult.put('message', errorMsg);
          bolResult.put('pdfData', null);
          result.put('bolResult', bolResult);

          Map<String, Object> coaResult = new Map<String, Object>();
          coaResult.put('success', false);
          coaResult.put('message', errorMsg);
          coaResult.put('pdfData', null);
          result.put('coaResult', coaResult);
        }
      } else {
        Map<String, Object> bolResult = new Map<String, Object>();
        bolResult.put('success', false);
        bolResult.put('message', 'ShipmentItem ID not provided');
        bolResult.put('pdfData', null);
        result.put('bolResult', bolResult);

        Map<String, Object> coaResult = new Map<String, Object>();
        coaResult.put('success', false);
        coaResult.put('message', 'ShipmentItem ID not provided');
        coaResult.put('pdfData', null);
        result.put('coaResult', coaResult);
      }

      // Update successful downloads count
      result.put('successfulDownloads', successfulDownloads);

      // Determine overall success
      Boolean overallSuccess = successfulDownloads > 0;
      result.put('success', overallSuccess);

      if (overallSuccess) {
        result.put('message', String.format('Successfully downloaded {0} of {1} documents', new List<Object>{ successfulDownloads, 3 }));
      } else {
        result.put('message', 'Failed to download any documents');
      }
    } catch (Exception e) {
      result.put('success', false);
      result.put('message', 'Exception during Download All: ' + e.getMessage());
    }

    return result;
  }

  /**
   * Check if COA is restricted for Sulfuric Acid + Rail combination
   * param shipmentItemId The ShipmentItem record ID
   * return Map containing restriction status
   */
  @AuraEnabled
  global static Map<String, Object> checkCOARestriction(String shipmentItemId) {
    Map<String, Object> result = new Map<String, Object>();

    if (String.isBlank(shipmentItemId)) {
      result.put('isRestricted', false);
      result.put('message', '');
      return result;
    }

    // Query to check if product is Sulfuric Acid and mode of transport is Rail
    List<ShipmentItem> items = [
      SELECT PMC_CPQ_OrderProduct__r.Product2.PMC_CPQ_SAPProductCode__c, PMC_CPQ_OrderProduct__r.PMC_CPQ_ModeofTransportation__c
      FROM ShipmentItem
      WHERE Id = :shipmentItemId
      LIMIT 1
    ];

    if (items.isEmpty()) {
      result.put('isRestricted', false);
      result.put('message', '');
      return result;
    }

    ShipmentItem item = items[0];
    String productCode = item.PMC_CPQ_OrderProduct__r?.Product2?.PMC_CPQ_SAPProductCode__c;
    String modeOfTransport = item.PMC_CPQ_OrderProduct__r?.PMC_CPQ_ModeofTransportation__c;

    // Check if product is Sulfuric Acid (code '2000002') and transport is Rail
    Boolean isSulfuricAcid = productCode == '2000002';
    Boolean isRailTransport = modeOfTransport == 'Rail';

    if (isSulfuricAcid && isRailTransport) {
      result.put('isRestricted', true);
      result.put('message', 'The product is Sulfuric Acid and the Transportation Mode is Rail, the CoA is not available for download.');
    } else {
      result.put('isRestricted', false);
      result.put('message', '');
    }

    return result;
  }
}