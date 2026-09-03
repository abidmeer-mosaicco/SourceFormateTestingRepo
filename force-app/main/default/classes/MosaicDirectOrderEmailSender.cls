public without sharing class MosaicDirectOrderEmailSender {

    private static final List<String> SUCCESS_COLUMNS = new List<String>{ 'Order', 'Order Item', 'Req. Shipment Date', 'PO Number', 'Order Qty', 'UOM', 'Origin', 'Ship To' };
    private static final String ORDER_FIELDS = 'Id, PMC_CPQ_ShipToAccount__c, OrderNumber, Status, CreatedById, SBQQ__Quote__R.Name, ContractId, Contract.ContractNumber, Contract.AccountId, PMC_CPQ_SAPOrderNumber__c, PMC_CPQ_OrderIntegrationStatus__c';

    public static void sendOrderConfirmationEmail(List<Order> orders, String customerEmail, String customerName, String quoteName, List<String> ccEmails) {
        try {
            String htmlBody = generateEmailBody(orders, customerName, quoteName);

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{ customerEmail });
            if (!ccEmails.isEmpty()) email.setCcAddresses(ccEmails);

            email.setSubject('Contract ' + quoteName + ' - Your Mosaic Orders Have Been Created');
            email.setHtmlBody(htmlBody);
            email.setSaveAsActivity(true);
            // email.setSenderDisplayName('Mosaic Customer Service');

            List<OrgWideEmailAddress> oweas = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply.customer.service@mosaicco.com'];
            if (!oweas.isEmpty()) email.setOrgWideEmailAddressId(oweas[0].Id);

            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ email });

            for (Messaging.SendEmailResult result : results) {
                if (result.isSuccess()) {
                    System.debug(LoggingLevel.INFO, 'Email sent successfully to ' + customerEmail);
                } else {
                    System.debug(LoggingLevel.ERROR, 'Failed to send email to ' + customerEmail + ': ' + result.getErrors()[0].getMessage());
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error sending email: ' + e.getMessage());
        }
    }

    public static void sendOrderErrorEmail(List<Order> orders, String customerEmail, String customerName, String quoteName, List<String> ccEmails, String errorMessage) {
        try {
            String htmlBody = generateErrorEmailBody(customerName, quoteName, errorMessage);

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{ customerEmail });

            if (!ccEmails.isEmpty()) email.setCcAddresses(ccEmails);

            List<String> orderNumbers = new List<String>();
            for (Order order : orders) {
                orderNumbers.add(order.OrderNumber);
            }

            String orderNumbersStr = String.join(orderNumbers, ', ');
            htmlBody = htmlBody.replace('{!OrderNumber}', orderNumbersStr);

            email.setSubject('Contract ' + quoteName + ' - Error Processing Your Order');
            email.setHtmlBody(htmlBody);
            email.setBccAddresses(new List<String>{'customer.service@mosaicco.com'});
            email.setSaveAsActivity(true);
            // email.setSenderDisplayName('Mosaic Customer Service');

            List<OrgWideEmailAddress> oweas = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply.customer.service@mosaicco.com'];
            if (!oweas.isEmpty()) email.setOrgWideEmailAddressId(oweas[0].Id);

            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ email });

            for (Messaging.SendEmailResult result : results) {
                if (result.isSuccess()) {
                    System.debug(LoggingLevel.INFO, 'Error email sent successfully to ' + customerEmail);
                } else {
                    System.debug(LoggingLevel.ERROR, 'Failed to send error email to ' + customerEmail + ': ' + result.getErrors()[0].getMessage());
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error sending error email: ' + e.getMessage());
        }
    }

    @TestVisible
    private static String generateEmailBody(List<Order> orders, String customerName, String contractNumber) {
        EmailTemplate template = [SELECT Id, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Mosaic_Direct_Order_Notification' LIMIT 1];
        if (template == null) throw new AuraHandledException('Email template not found!');

        String htmlBody = template.HtmlValue;
        Set<Id> orderIds = new Set<Id>();
        for (Order o : orders) orderIds.add(o.Id);

        List<OrderItem> orderItems = [SELECT Id, OrderId, Order.PMC_CPQ_SAPOrderNumber__c, PMC_CPQ_SAPOrderLineID__c, PMC_CPQ_RequestedShipDate__c, PMC_CPQ_LinePONumber__c, Quantity, PMC_CPQ_UnitOfMeasure__c, PMC_CPQ_ShippingType__c, PMC_CPQ_ProductLocation__r.Name, PMC_CPQ_ShipTo__r.Name FROM OrderItem WHERE OrderId IN :orderIds];

        Set<Id> shipToIds = new Set<Id>();
        Map<Id, List<OrderItem>> mapItemsByOrder = new Map<Id, List<OrderItem>>();
        for (OrderItem oi : orderItems) {
            if (!mapItemsByOrder.containsKey(oi.OrderId)) mapItemsByOrder.put(oi.OrderId, new List<OrderItem>());
            mapItemsByOrder.get(oi.OrderId).add(oi);
            shipToIds.add(oi.PMC_CPQ_ShipTo__c);
        }

        Map<String, String> shipToAddresses = new Map<String, String>();
        List<Account> shipTOs = [SELECT Name, BillingCity, BillingStateCode, BillingCountryCode, BillingStreet, BillingPostalCode, Id FROM Account WHERE Id IN :shipToIds];
        for (Account acc : shipTOs) {
            List<String> parts1 = new List<String>();
            List<String> parts2 = new List<String>();

            if (!String.isBlank(acc.Name)) { parts1.add(acc.Name); }
            if (!String.isBlank(acc.BillingCity)) { parts1.add('-' + acc.BillingCity); }
            if (!String.isBlank(acc.BillingStateCode)) { parts1.add(', ' + acc.BillingStateCode + '<br>'); }
            if (!String.isBlank(acc.BillingStreet)) { parts2.add(acc.BillingStreet); }
            if (!String.isBlank(acc.BillingPostalCode)) { parts2.add(', ' + acc.BillingPostalCode); }

            shipToAddresses.put(acc.Id, '<strong>' + String.join(parts1, '') + '</strong>' + String.join(parts2, ''));
        }

        String tableContent = '';
        for (Order ord : orders) {
            List<OrderItem> items = mapItemsByOrder.get(ord.Id);
            if (items == null || items.isEmpty()) continue;

            String sapOrderNumber;
            String finalColumns = '<th>' + String.join(SUCCESS_COLUMNS, '</th><th>') + '</th>';
            System.debug('Final Columns: ' + finalColumns);

            tableContent += '<h3><strong>Order: {!SAPOrderNumber}</strong></h3>';
            tableContent += '<table class="order-table">';
            tableContent += '<tr>' + finalColumns + '</tr>';
            // tableContent += '<tr><th>Sales Order</th><th>Sales Order Item</th><th>Req. Shipment Date</th><th>Order PO Number</th><th>Order Qty (t)</th><th>UOM</th><th>Ship Method</th><th>Origin</th><th>Ship To</th></tr>';

            for (OrderItem item : items) {
                String rawSapCode = (item.PMC_CPQ_SAPOrderLineID__c != null) ? item.PMC_CPQ_SAPOrderLineID__c : '';
                String itemSapCode = '';

                if (rawSapCode != '') {
                    List<String> itemSAPNumber = rawSapCode.split('_');

                    if (itemSAPNumber.size() > 0) {
                        sapOrderNumber = itemSAPNumber[0];
                        itemSapCode = itemSAPNumber[1].leftPad(4, '0');
                    }
                }

                tableContent += '<tr>';
                tableContent += '<td>' + sapOrderNumber + '</td>';
                tableContent += '<td>' + itemSapCode + '</td>';
                tableContent += '<td>' + ((item.PMC_CPQ_RequestedShipDate__c != null) ? item.PMC_CPQ_RequestedShipDate__c.format() : '') + '</td>';
                tableContent += '<td>' + ((item.PMC_CPQ_LinePONumber__c != null) ? item.PMC_CPQ_LinePONumber__c : '') + '</td>';
                tableContent += '<td>' + ((item.Quantity != null) ? String.valueOf(item.Quantity) : '') + '</td>';
                tableContent += '<td>' + ((item.PMC_CPQ_UnitOfMeasure__c != null) ? item.PMC_CPQ_UnitOfMeasure__c : '') + '</td>';
                // tableContent += '<td>' + ((item.PMC_CPQ_ShippingType__c != null) ? item.PMC_CPQ_ShippingType__c : '') + '</td>';
                tableContent += '<td>' + ((item.PMC_CPQ_ProductLocation__r.Name != null) ? item.PMC_CPQ_ProductLocation__r.Name : '') + '</td>';
                tableContent += '<td>' + shipToAddresses.get(item.PMC_CPQ_ShipTo__c) + '</td>';
                tableContent += '</tr>';
            }

            tableContent = tableContent.replace('{!SAPOrderNumber}', sapOrderNumber);
            tableContent += '</table>';
        }

        htmlBody = htmlBody.replace('{!customerName}', customerName != null ? customerName : 'Valued Customer');
        htmlBody = htmlBody.replace('{!tableContent}', tableContent);

        return htmlBody;
    }

    private static String generateErrorEmailBody(String customerName, String quoteName, String errorMessage) {
        EmailTemplate template = [SELECT Id, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Mosaic_Direct_Order_Error_Notification' LIMIT 1];
        if (template == null) throw new AuraHandledException('Error email template not found!');
        
        String htmlBody = template.HtmlValue;
        htmlBody = htmlBody.replace('{!customerName}', customerName != null ? customerName : 'Valued Customer');
        htmlBody = htmlBody.replace('{!quoteName}', quoteName != null ? quoteName : 'N/A');
        htmlBody = htmlBody.replace('{!ErrorMessage}', errorMessage != null ? errorMessage : 'An unexpected error occurred.');
        return htmlBody;
    }

    @future
    public static void handleOrderSubmission(String jsonOrders) {
        if (jsonOrders == null) return;
        List<Order> ordersToProcess = (List<Order>) JSON.deserialize(jsonOrders, List<Order>.class);
        if (ordersToProcess.isEmpty()) return;

        Set<Id> orderIds = new Set<Id>();
        for (Order o : ordersToProcess) orderIds.add(o.Id);

        List<Order> fullOrders = Database.query('SELECT ' + ORDER_FIELDS + ' FROM Order WHERE Id IN :orderIds') ?? new List<Order>();

        if (fullOrders.isEmpty()) return;

        Order firstOrder = fullOrders[0];
        Id ownerId = firstOrder.CreatedById;
        Id accountId = firstOrder.Contract.AccountId;
        String contractNumber = firstOrder.Contract.ContractNumber;
        String quoteName = firstOrder.SBQQ__Quote__R?.Name.replace('Q-', '');

        User user = [SELECT Name, Contact.Name, Contact.Email FROM User WHERE Id = :ownerId LIMIT 1] ?? null;
        String customerName = 'Customer';

        if (user != null) {
            if (user?.Contact?.Name != null) customerName = user.Contact.Name;
            if (customerName == null || customerName == 'Customer') customerName = user.Name;
        }

        String customerEmail = user == null ? '' : user?.Contact?.Email;

        if (String.isBlank(customerEmail)) return;

        List<AccountTeamMember> teamMembers = [SELECT User.Email FROM AccountTeamMember WHERE AccountId = :accountId];
        List<String> ccEmails = new List<String>();
        for (AccountTeamMember atm : teamMembers) {
            if (String.isNotBlank(atm.User.Email)) {
                ccEmails.add(atm.User.Email);
            }
        }

        List<Order> successOrders = new List<Order>();
        List<Order> errorOrders = new List<Order>();
        for (Order ord : fullOrders) {
            if (ord.PMC_CPQ_OrderIntegrationStatus__c == 'Error' && ord.PMC_CPQ_SAPOrderNumber__c == null) {
                errorOrders.add(ord);
            } else {
                successOrders.add(ord);
            }
        }

        if (!successOrders.isEmpty()) {
            sendOrderConfirmationEmail(successOrders, customerEmail, customerName, quoteName, ccEmails);
        }

        if (!errorOrders.isEmpty()) {
            List<String> errorOrderNumbers = new List<String>();
            for (Order ord : errorOrders) {
                errorOrderNumbers.add(ord.OrderNumber);
            }

            String errorMessage = 'The following order(s) encountered an integration error: ' + String.join(errorOrderNumbers, ', ');
            sendOrderErrorEmail(errorOrders, customerEmail, customerName, quoteName, ccEmails, errorMessage);
        }
    }
}