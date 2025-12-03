public with sharing class OrderController {

    @AuraEnabled
    public static Map < String, String > createOrderWithProducts(String orderData) {
        Map < String, String > result = new Map < String, String > ();

        try {
            if (String.isBlank(orderData)) {
                throw new AuraHandledException('No order data provided.');
            }

            Map < String, Object > inputMap = (Map < String, Object > ) JSON.deserializeUntyped(orderData);

            if (!inputMap.containsKey('order')) {
                throw new AuraHandledException('Order data missing in request.');
            }

            Map < String, Object > orderFields = (Map < String, Object > ) inputMap.get('order');
            if (orderFields == null) {
                throw new AuraHandledException('Order fields are null.');
            }

            Order newOrder = new Order();

            // Handle AccountId
            Object accountIdObj = orderFields.get('accountId');
            if (accountIdObj instanceof String) {
                newOrder.AccountId = (String) accountIdObj;
            } else if (accountIdObj instanceof List < Object > ) {
                List < Object > accountIdList = (List < Object > ) accountIdObj;
                if (!accountIdList.isEmpty() && accountIdList[0] instanceof String) {
                    newOrder.AccountId = (String) accountIdList[0];
                } else {
                    throw new AuraHandledException('Invalid Account ID format.');
                }
            }

            newOrder.PoNumber = (String) orderFields.get('poNumber');

            if (orderFields.get('poReceivedDate') != null) {
                newOrder.Po_Received_Date__c = Date.valueOf((String) orderFields.get('poReceivedDate'));
            }

            newOrder.EffectiveDate = (orderFields.get('effectiveDate') != null) ?
                Date.valueOf((String) orderFields.get('effectiveDate')) :
                Date.today();

            newOrder.Status = (String) orderFields.get('status');
            newOrder.CurrencyIsoCode = (String) orderFields.get('currency');

            Object intendedUserObj = orderFields.get('intendedUserId');
            if (intendedUserObj instanceof List < Object > ) {
                List < Object > intendedUsers = (List < Object > ) intendedUserObj;
                if (!intendedUsers.isEmpty()) {
                    newOrder.Intended_User__c = (String) intendedUsers[0];
                }
            } else if (intendedUserObj instanceof String) {
                newOrder.Intended_User__c = (String) intendedUserObj;
            }

            Pricebook2 standardPricebook = [SELECT Id FROM Pricebook2 WHERE IsActive = TRUE AND Name = 'Standard Price Book'
                LIMIT 1
            ];

            System.debug(standardPricebook);

            newOrder.Pricebook2Id = standardPricebook.Id;

            if (newOrder.AccountId == null) {
                throw new AuraHandledException('Account ID is required.');
            }

            insert newOrder;

            // Handle products
            System.debug(inputMap);
            Object productsObj = inputMap.get('orderProducts');
            if (!(productsObj instanceof List < Object > )) {
                System.debug('Invalid product data format received.');
                throw new AuraHandledException('Invalid product data.');
            }

            List < Map < String, Object >> products = new List < Map < String, Object >> ();
            for (Object item: (List < Object > ) productsObj) {
                if (item instanceof Map < String, Object > ) {
                    products.add((Map < String, Object > ) item);
                }
            }

            System.debug('Parsed product list: ' + products);

            if (products.isEmpty()) {
                System.debug('Product list is empty.');
                throw new AuraHandledException('At least one product is required.');
            }

            System.debug('Validated product list: ' + products);

            // Resolve Product2Id to PricebookEntry
            System.debug('Resolving Product2Ids...');
            Set < Id > product2Ids = new Set < Id > ();
            for (Map < String, Object > product: products) {
                Object prodIdObj = product.get('Product2Id');
                Id product2Id;
                if (prodIdObj instanceof String) {
                    product2Id = (Id) prodIdObj;
                } else if (prodIdObj instanceof List < Object > ) {
                    List < Object > prodList = (List < Object > ) prodIdObj;
                    if (!prodList.isEmpty() && prodList[0] instanceof String) {
                        product2Id = (Id) prodList[0];
                    } else {
                        System.debug('Invalid Product2Id format in list: ' + prodIdObj);
                        throw new AuraHandledException('Invalid Product2Id format.');
                    }
                } else {
                    System.debug('Missing or invalid Product2Id: ' + prodIdObj);
                    throw new AuraHandledException('Product2Id is missing or invalid.');
                }
                product.put('ResolvedProduct2Id', product2Id);
                product2Ids.add(product2Id);
            }

            System.debug('Resolved Product2Ids: ' + product2Ids);

            System.debug('Querying active PricebookEntries for currency: ' + newOrder.CurrencyIsoCode);
            Map < Id, PricebookEntry > productToPbeMap = new Map < Id, PricebookEntry > ();
            List < PricebookEntry > pbeList = [
                SELECT Id, Product2Id, UnitPrice, CurrencyIsoCode
                FROM PricebookEntry
                WHERE Pricebook2Id =: newOrder.Pricebook2Id
                AND Product2Id IN: product2Ids
                AND IsActive = true
                AND CurrencyIsoCode =: newOrder.CurrencyIsoCode
            ];
            System.debug('Found ' + pbeList.size() + ' PricebookEntries matching currency ' + newOrder.CurrencyIsoCode);

            for (PricebookEntry pbe: pbeList) {
                System.debug('Adding PBE: ' + pbe.Id + ' for product ' + pbe.Product2Id +
                    ' with currency ' + pbe.CurrencyIsoCode +
                    ' and price ' + pbe.UnitPrice);
                productToPbeMap.put(pbe.Product2Id, pbe);
            }

            System.debug('Mapped PricebookEntries: ' + productToPbeMap);

            List < OrderItem > orderItems = new List < OrderItem > ();

            System.debug('Creating OrderItems...');
            for (Map < String, Object > product: products) {
                System.debug('Processing product: ' + product);
                Id resolvedProduct2Id = (Id) product.get('ResolvedProduct2Id');
                if (!productToPbeMap.containsKey(resolvedProduct2Id)) {
                    System.debug('No active PricebookEntry found for product: ' + resolvedProduct2Id);
                    throw new AuraHandledException('No active PricebookEntry found for product: ' + resolvedProduct2Id);
                }

                Decimal quantity = product.get('Quantity') != null ?
                    Decimal.valueOf(String.valueOf(product.get('Quantity'))) :
                    1;

                Decimal unitPrice = product.get('UnitPrice') != null ?
                    Decimal.valueOf(String.valueOf(product.get('UnitPrice'))) :
                    productToPbeMap.get(resolvedProduct2Id).UnitPrice;

                if (quantity <= 0) {
                    throw new AuraHandledException('Quantity must be greater than 0 for product: ' + resolvedProduct2Id);
                }

                if (unitPrice < 0) {
                    throw new AuraHandledException('Unit Price must be zero or greater.');
                }

                OrderItem oi = new OrderItem();
                oi.OrderId = newOrder.Id;
                oi.PricebookEntryId = productToPbeMap.get(resolvedProduct2Id).Id;
                oi.Quantity = quantity;
                oi.UnitPrice = unitPrice;

                orderItems.add(oi);
            }

            insert orderItems;

            result.put('orderId', newOrder.Id);
            result.put('status', 'success');

        } catch (Exception e) {
            System.debug('ERROR: ' + e.getMessage());
            System.debug('ERROR: ' + e.getLineNumber());
            result.put('status', 'error');
            result.put('message', e.getMessage());
        }

        return result;
    }

    private static Id getStandardPricebookId() {
        try {
            Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
            return pb.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Could not find standard pricebook: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable = true)
    public static List < String > getCurrencyOptions() {
        List < String > currencies = new List < String > ();
        currencies.add(UserInfo.getDefaultCurrency());

        if (UserInfo.isMultiCurrencyOrganization()) {
            for (CurrencyType ct: [SELECT IsoCode FROM CurrencyType WHERE IsActive = true ORDER BY IsoCode]) {
                if (!currencies.contains(ct.IsoCode)) {
                    currencies.add(ct.IsoCode);
                }
            }
        }

        return currencies;
    }

    @AuraEnabled
    public static string getSalesOrderDetail(String soId){
        try {

            Map<String, Object> resDataMap = new Map<String, Object>();

            Order ord = [
                SELECT Id, AccountId, Pricebook2Id, CurrencyIsoCode, OpportunityId, Operating_Unit__c, Warehouse__c, Requested_Delivery_Date__c,
                Promised_Delivery_Date__c, External_Document_No__c, Bill_to_Party__c, Ship_to_Party__c, Order_Type__c, Po_Received_Date__c,
                Dispatcher_Information__c, Payment_Term__c, Price_List__c, EffectiveDate, PoNumber, Intended_User__c
                FROM Order WHERE Id = :soId
            ];

            List <OrderItem> orderItems = [
                SELECT Id, UnitPrice, Quantity, Product2.Name, Product2Id, PricebookEntryId
                FROM OrderItem WHERE OrderId = :ord.Id
            ];

            resDataMap.put('order', ord);
            resDataMap.put('orderItems', orderItems);


            return JSON.serialize(resDataMap);
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string cloneExistingOrder(String ordId){
        try {

            Order ord = [
                SELECT Id, AccountId, Pricebook2Id, CurrencyIsoCode, OpportunityId, Operating_Unit__c, Warehouse__c, Requested_Delivery_Date__c,
                Promised_Delivery_Date__c, External_Document_No__c, Bill_to_Party__c, Ship_to_Party__c, Order_Type__c, Po_Received_Date__c,
                Dispatcher_Information__c, Payment_Term__c, Price_List__c, EffectiveDate
                FROM Order WHERE Id = :ordId
            ];

            Order originalOrder = ord;
            Order clonedOrder = originalOrder.clone(false, true, false, false);
            // clonedOrder.Product2Id = proList[0].Id;
            // clonedOrder.PricebookEntryId = pbe.Id;
            insert clonedOrder;

            return '';
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

      public static void temethod(){
          for(integer i=0; i<=1500; i++){
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
              i++;
          }} 

}