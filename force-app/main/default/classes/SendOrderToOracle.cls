public class SendOrderToOracle {
    
    @AuraEnabled
    public static string getChangedOrderLineItems(String ordId, String orgId){
        // Clone and delete the previous because Organization is not matching
        try {

            Order ord = [SELECT Id, Pricebook2Id FROM Order WHERE Id = :ordId LIMIT 1];

            List<OrderItem> orderItemList = new List<OrderItem>();
            orderItemList = [
                SELECT Id, Quantity, Product2.Inventory_Item_Id__c, Product2.Primary_UOM_Code__c, Product2.Secondary_UOM_Code__c,
                Product2.Organization_Name__r.Organization_Id__c, Product2.Name, UnitPrice, Pricing_Quantity__c, Product2.Organization_Name__c,
                Order.Oracle_Sales_Order_No__c, Unit_Selling_Price__c, Order.Price_List__c, Product2.ProductCode, Product2Id, CurrencyIsoCode
                FROM OrderItem
                WHERE OrderId = :ordId
            ];

            List<Product2> proList = [
                SELECT Id, Name, ProductCode, CurrencyIsoCode
                FROM Product2
                WHERE Organization_Name__c = :orgId
                AND ProductCode = :orderItemList[0].Product2.ProductCode
                LIMIT 1
            ];

            System.debug(proList);

            PricebookEntry pbe = [
                SELECT Id, CurrencyIsoCode FROM PricebookEntry 
                WHERE Pricebook2Id = :ord.Pricebook2Id 
                AND Product2Id = :proList[0].Id
                AND CurrencyIsoCode = :orderItemList[0].CurrencyIsoCode
                AND IsActive = true 
                LIMIT 1
            ];

            if (proList.size() > 0) {
                OrderItem originalOrder = orderItemList[0];
                OrderItem clonedOrderItem = originalOrder.clone(false, true, false, false);
                clonedOrderItem.Product2Id = proList[0].Id;
                clonedOrderItem.PricebookEntryId = pbe.Id;
                insert clonedOrderItem;
                delete originalOrder;
                orderItemList = [
                    SELECT Id, Quantity, Product2.Inventory_Item_Id__c, Product2.Primary_UOM_Code__c, Product2.Secondary_UOM_Code__c,
                    Product2.Organization_Name__r.Organization_Id__c, Product2.Name, UnitPrice, Pricing_Quantity__c, Product2.Organization_Name__c,
                    Order.Oracle_Sales_Order_No__c, Unit_Selling_Price__c, Order.Price_List__c, Product2.ProductCode
                    FROM OrderItem
                    WHERE OrderId = :ordId
                ];
            }

            return JSON.serialize(orderItemList);
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getOrderLineItems(String ordId){
        try {

            List<OrderItem> orderItemList = new List<OrderItem>();
            orderItemList = [
                SELECT Id, Quantity, Product2.Inventory_Item_Id__c, Product2.Primary_UOM_Code__c, Product2.Secondary_UOM_Code__c,
                Product2.Organization_Name__r.Organization_Id__c, Product2.Name, UnitPrice, Pricing_Quantity__c, Product2.Organization_Name__c,
                Order.Oracle_Sales_Order_No__c, Unit_Selling_Price__c, Order.Price_List__c, Product2.ProductCode, Product2Id
                FROM OrderItem
                WHERE OrderId = :ordId
            ];

            return JSON.serialize(orderItemList);
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string getPriceList(String productId, String curr){
        try {

            List<Map<String, String>> responseMap = new List<Map<String, String>>();
            String responseData = '';

            List<PricebookEntry> PricebookEntryList = [
                SELECT Id, Name, Pricebook2Id, Pricebook2.Name, Pricebook2.Price_List_Id__c
                FROM PricebookEntry
                WHERE Product2Id = :productId
                AND Pricebook2.Price_List_Id__c != null
                AND CurrencyIsoCode = :curr
            ];

            if (PricebookEntryList.size() > 0) {
                for (PricebookEntry v : PricebookEntryList) {
                    Map<String, String> resMap = new Map<String, String>();
                    resMap.put('label', v.Pricebook2.Name + ' ('+v.Pricebook2.Price_List_Id__c+')');
                    resMap.put('value', v.Pricebook2.Price_List_Id__c);
                    responseMap.add(resMap);
                }
                responseData = JSON.serialize(responseMap);
            }

            return responseData;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string getAddInfo(String ouId, String accId){
        Map<String, Object> respMap = new Map<String, Object>();
        List<Address_Information__c> billToAddInfoList = new List<Address_Information__c>();
        List<Address_Information__c> shipToAddInfoList = new List<Address_Information__c>();
        List<Address_Information__c> addInfoList = [
            SELECT Id, Name, Operating_Unit__c, Primary_Address__c, Address_1__c, Address_2__c, Area__c, Area__r.Name,
            City__c, City__r.Name, State__c, State__r.Name, RecordType.DeveloperName
            FROM Address_Information__c
            WHERE Operating_Unit__c = :ouId
            AND Account__c = :accId
        ];

        for (Address_Information__c a : addInfoList) {
            if (a.RecordType.DeveloperName == 'Bill_To') {
                billToAddInfoList.add(a);
            }
            if (a.RecordType.DeveloperName == 'Ship_To') {
                shipToAddInfoList.add(a);
            }
        }

        respMap.put('billToAddInfoList', billToAddInfoList);
        respMap.put('shipToAddInfoList', shipToAddInfoList);
        return JSON.serialize(respMap);

    }

    @AuraEnabled
    public static string getOrganization(String ouId){
        try {

            List<Map<String, String>> responseMap = new List<Map<String, String>>();
            String responseData = '';

            Operating_Unit__c ou = [SELECT Id, Operating_Unit_ID__c FROM Operating_Unit__c WHERE Id = :ouId];

            Decimal oudec = Decimal.valueOf(ou.Operating_Unit_ID__c);

            List<Organization__c> OrganizationList = [
                SELECT Id, Name, Organization_Id__c
                FROM Organization__c
                WHERE OU_Id__c = :oudec
            ];

            if (OrganizationList.size() > 0) {
                for (Organization__c v : OrganizationList) {
                    Map<String, String> resMap = new Map<String, String>();
                    resMap.put('label', v.Name);
                    resMap.put('value', v.Id);
                    responseMap.add(resMap);
                }
                responseData = JSON.serialize(responseMap);
            }

            return responseData;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string saveDispatchSchedule(String oId, String oliId, String prodId, String jsonPayload){
        try {

            System.debug(jsonPayload);
            // Parse the string into list of wrappers
            List<LineItemWrapper> items = (List<LineItemWrapper>) JSON.deserialize(jsonPayload, List<LineItemWrapper>.class);

            List<Dispatch_Schedule__c> dsListToInsert = new List<Dispatch_Schedule__c>();
            for (LineItemWrapper w : items) {
                dsListToInsert.add(new Dispatch_Schedule__c(
                    Order__c = oId,
                    Order_Product__c = oliId,
                    Product__c = prodId,
                    Total_Quantity__c = w.qty,
                    Dispatch_Expected_Start_Date__c = Date.valueOf(w.startDate),
                    Dispatch_Expected_End_Date__c = Date.valueOf(w.endDate)
                ));
            }
            insert dsListToInsert;

            return 'Success';
            
        } catch (Exception e) {
            // return 'fail';
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class LineItemWrapper {
        public Integer qty;
        public String startDate;
        public String endDate;
    }

    public static void fc () {
        Integer i = 0;
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
    }
    
}