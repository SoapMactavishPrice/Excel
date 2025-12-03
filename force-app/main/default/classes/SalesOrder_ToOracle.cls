public class SalesOrder_ToOracle {

    // @future(callout = true)
    @AuraEnabled
    public static string createSalesOrderData(String soId) {

        String responseBodyData = '';

        // ------------------- API LOG to track the request -------------------
        API_Log__c api_log = new API_Log__c();
        api_log.Log_Name__c = 'SalesOrder_ToOracle';
        api_log.Request_Time__c = DateTime.now();

        try {

            String jsonBody = createJSONrequest(soId);
            // String jsonBody = createJSONrequestHardCode(soId);
            api_log.Request__c = jsonBody;

            // Define API URL
            String apiUrl = label.CreateSalesOrderOracle;

            // Authentication Header
            String username = label.api_username;
            String password = label.api_pass;
            String authHeader = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password));

            // Create HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(apiUrl);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', authHeader);
            req.setBody(jsonBody);
            req.setTimeout(120000);

            // Send HTTP request
            Http http = new Http();
            HttpResponse res = http.send(req);

            // Debug response
            // System.debug('Response: ' + res.getBody());
            String responseBody = res.getBody();
            responseBodyData = parseresponseBodyData(responseBody, soId);

            if (res.getStatusCode() == 200) {
                api_log.Log_Status__c = 'Success';
            } else {
                api_log.Log_Status__c = 'Failure';
            }
            api_log.Response_Code__c = String.valueOf(res.getStatusCode());
            api_log.Response__c = res.getBody();
            api_log.response_time__c = Datetime.now();

        } catch (Exception e) {
            System.debug('Error in API Call: ' + e.getMessage());
            responseBodyData = e.getMessage();
            api_log.Log_Status__c = 'Failure';
            api_log.Response_Code__c = '400';
            api_log.Exception_Description__c = 'Line Number : ' + e.getLineNumber() + ' \n\n ' + e.getMessage() + '\n\n' + e.getStackTraceString();
            api_log.Response_Time__c = Datetime.now();
        }

        if (!Test.isRunningTest()) {
            api_log.Order__c = soId;
        }
        insert api_log;

        return responseBodyData;
    }

    public static String createJSONrequestHardCode(String Id) {

        String orderFields = getAllFields('Order', Id);
        String orderItemFields = getAllFields('OrderItem', Id);
        Order exOrd = Database.query(orderFields);
        List < OrderItem > exOrdItem = Database.query(orderItemFields);

        System.debug(exOrd);
        System.debug(exOrdItem);

        Map < String, Object > orderLineItem = new Map < String, Object > {
            'lineNo' => 1000,
            'inventoryItemId' => 469303,
            'quantity' => 9000,
            'quantity2' => 131.5,
            'PrimaryUomCode' => 'KGM',
            'SecondaryUomCode' => 'NOS',
            'unitPrice' => 250.50,
            'Unitsellingprice' => 250.50,
            'pricingQuantity' => 10,
            'warehouseId' => 131,
            'requestedDeliveryDate' => '2025-03-15',
            'promisedDeliveryDate' => '2025-03-20',
            'type' => 'Standard',
            'no' => 'ORD550',
            'description' => 'Industrial Drill Machine',
            'customerDescription' => 'Heavy-duty drill machine for construction',
            'lineDiscount' => 5.00,
            'foc' => false,
            'productType' => 'Equipment',
            'orderTypeId' => 1043,
            'customerType' => 'Business',
            'remarks' => 'Handle with care',
            'comment' => 'Deliver before noon',
            'uomConversionFactor' => 1.0,
            'shortClosed' => false
        };

        List < Map < String, Object >> orderLineItems = new List < Map < String, Object >> {
            orderLineItem
        };

        Map < String, Object > innerInputJSON = new Map < String, Object > {
            'paymentTermId' => 1312,
            'priceListId' => 6010,
            'warehouseId' => 131,
            'orgId' => 120,
            'currencyISOCode' => 'INR',
            'poNumber' => 'PO-3493455',
            'customerName' => 'RELIANCE BIO ENERGY LIMITED',
            'dispatcherInformation' => 'John Doe',
            'customerNo' => 'CUS0000044',
            'orderDate' => '2025-03-10',
            'requestedDeliveryDate' => '2025-03-15',
            'promisedDeliveryDate' => '2025-03-20',
            'externalDocumentNo' => 'EXT-56789',
            'yourReference' => 'REF-1234',
            'poReceivedDate' => '2025-03-09',
            'billToName' => 'ABC Corp',
            'billToAddress' => '123 Main St',
            'billToAddress2' => 'Suite 200',
            'billToCity' => 'New York',
            'billToContact' => 'Jane Smith',
            'billToPostCode' => '10001',
            'billToCountryRegionCode' => 'US',
            'gstBillToStateCode' => 'NY',
            'shipToName' => 'XYZ Warehouse',
            'shipToAddress' => '456 Elm St',
            'shipToAddress2' => 'Building B',
            'shipToCity' => 'Los Angeles',
            'shipToContact' => 'Mike Johnson',
            'shipToPostCode' => '90001',
            'shipToCountryRegionCode' => 'US',
            'gstShipToStateCode' => 'CA',
            'shipToGSTRegNo' => 'GST-123456',
            'workDesrcription' => 'Shipment of industrial equipment',
            'comment' => 'Urgent delivery required',
            'sellToContact' => 'Robert Brown',
            'sellToEmail' => 'robert.brown@example.com',
            'sellToPhoneNo' => '+1-555-789-1234',
            'paymentTermCode' => 'NET30',
            'responsibilityCentre' => 'RC-2025',
            'salesPersonCode' => 'SP-007',
            'salesOrderNo' => 'ORD550',
            'shortClosed' => false,
            'orderTypeId' => 1043,
            'ShipToSiteuseCode' => 'SHIP_TO',
            'ShipToPartySiteid' => 91972,
            'BillToSiteuseCode' => 'BILL_TO',
            'BillToPartySiteid' => 91971,
            'orderLineItems' => orderLineItems
        };

        Map < String, Object > innerInputParameters = new Map < String, Object > {
            'InputParameters' => innerInputJSON
        };

        Map < String, Object > outerInputParameters = new Map < String, Object > {
            'P_SF_ORDER_NO' => 'ORD550',
            'P_JSON' => JSON.serialize(innerInputParameters)
        };

        Map < String, Object > finalJson = new Map < String, Object > {
            'InputParameters' => outerInputParameters
        };

        return JSON.serializePretty(finalJson);

    }

    public static String createJSONrequest(String Id) {

        String orderFields = getAllFields('Order', Id);
        Order exOrd = Database.query(orderFields);

        String orderItemFields = getOneLevelLineItemRecords('OrderItem', 'OrderId', Id);
        List < OrderItem > exOrdItem = Database.query(orderItemFields);

        System.debug(exOrd);
        System.debug(exOrdItem);

        List < Map < String, Object >> orderLineItems = new List < Map < String, Object >> ();

        for (OrderItem eoi: exOrdItem) {
            Map < String, Object > orderLineItem = new Map < String, Object > {
                'lineNo' => eoi.Line_No__c,
                'inventoryItemId' => eoi.Product2.Inventory_Item_Id__c.replace(',', ''),
                'quantity' => eoi.Quantity,
                'quantity2' => eoi.Quantity, // As per Excel team
                // 'quantity2' => eoi.Quantity_2__c, //131.5, // Need to confirm
                'PrimaryUomCode' => eoi.Product2.Primary_UOM_Code__c,
                'SecondaryUomCode' => eoi.Product2.Secondary_UOM_Code__c,
                'unitPrice' => eoi.UnitPrice,
                'Unitsellingprice' => eoi.UnitPrice, //250.50, // Need to confirm
                'pricingQuantity' => eoi.Quantity,
                'warehouseId' => eoi.Product2.Organization_Name__r.Organization_Id__c,
                'requestedDeliveryDate' => eoi.Requested_Delivery_Date__c,
                'promisedDeliveryDate' => eoi.Promised_Delivery_Date__c, //'2025-03-20', // Need to confirm
                'type' => eoi.Type__c, //'Standard', // Need to confirm
                'no' => eoi.Order.Name,
                'description' => eoi.Product2.Name,
                'customerDescription' => eoi.Order.Account.Name,
                'lineDiscount' => eoi.Discount__c,
                'foc' => eoi.FOC__c, //false, // Need to confirm
                'productType' => eoi.Product2.Item_Type__c, //'Equipment', // Need to confirm
                'orderTypeId' => eoi.Order.Order_Type__r.Order_Type_Id__c, // Need to confirm
                'customerType' => eoi.Order.Account.Type, // 'Business' // Need to confirm
                'remarks' => eoi.Remarks__c, //'Handle with care', // Need to confirm
                'comment' => eoi.Comment__c, //'Deliver before noon', // Need to confirm
                'uomConversionFactor' => 1.0, // As per Vaibhav it is 'NA' so we are sending 1.0 (Sarvanan)
                'shortClosed' => eoi.Short_Closed__c //false // Need to confirm
            };

            orderLineItems.add(orderLineItem);
        }

        if (String.isBlank(exOrd.Ship_to_Party__r.Oracle_Site_Code__c) || String.isBlank(exOrd.Bill_to_Party__r.Oracle_Site_Code__c)) {
            throw new IllegalArgumentException('Site Use Code required');
        }

        Map < String, Object > innerInputJSON = new Map < String, Object > {
            'paymentTermId' => exOrd.Payment_Term__r.Payment_Term_Id__c, // Need to confirm
            'priceListId' => exOrd.Price_List__c,
            'warehouseId' => exOrd.Warehouse__r.Organization_Id__c,
            'orgId' => exOrd.Operating_Unit__r.Operating_Unit_ID__c,
            'currencyISOCode' => exOrd.CurrencyIsoCode,
            'poNumber' => exOrd.PoNumber,
            'customerName' => exOrd.Account.Name,
            'dispatcherInformation' => checkNullVal(exOrd.Dispatcher_Information__c), // Need to confirm
            'customerNo' => exOrd.Account.Oracle_Customer_No__c,
            'orderDate' => Date.today(),
            'requestedDeliveryDate' => exOrd.Requested_Delivery_Date__c,
            'promisedDeliveryDate' => exOrd.Promised_Delivery_Date__c,
            'externalDocumentNo' => checkNullVal(exOrd.External_Document_No__c),
            'yourReference' => checkNullVal(exOrd.Your_Reference__c),
            'poReceivedDate' => exOrd.Po_Received_Date__c, // Need to confirm
            'billToName' => checkNullVal(exOrd.Bill_To_Name__c),
            'billToAddress' => exOrd.Bill_to_Party__r.Address_1__c,
            'billToAddress2' => exOrd.Bill_to_Party__r.Address_2__c,
            'billToCity' => checkNullVal(exOrd.Bill_to_Party__r.City__r.Name),
            'billToContact' => checkNullVal(exOrd.Bill_To_Contact__c),
            'billToPostCode' => checkNullVal(exOrd.Bill_to_Party__r.Postal_Code__r.Name),
            'billToCountryRegionCode' => 'US',
            'gstBillToStateCode' => getGSTstateCode(exOrd.Bill_to_Party__r.GST__c),
            'shipToName' => checkNullVal(exOrd.Ship_To_Name__c),
            'shipToAddress' => exOrd.Ship_to_Party__r.Address_1__c,
            'shipToAddress2' => exOrd.Ship_to_Party__r.Address_2__c,
            'shipToCity' => checkNullVal(exOrd.Ship_to_Party__r.City__r.Name),
            'shipToContact' => checkNullVal(exOrd.Ship_To_Contact__c),
            'shipToPostCode' => checkNullVal(exOrd.Ship_to_Party__r.Postal_Code__r.Name),
            'shipToCountryRegionCode' => 'US',
            'gstShipToStateCode' => getGSTstateCode(exOrd.Ship_to_Party__r.GST__c),
            'shipToGSTRegNo' => checkNullVal(exOrd.Ship_To_GST_Reg_No__c),
            'workDesrcription' => checkNullVal(exOrd.Description),
            'comment' => checkNullVal(exOrd.Comment__c),
            'sellToContact' => checkNullVal(exOrd.Sell_To_Contact__c),
            'sellToEmail' => checkNullVal(exOrd.Sell_To_Email__c),
            'sellToPhoneNo' => checkNullVal(exOrd.Sell_To_Phone_No__c),
            'paymentTermCode' => checkNullVal(exOrd.Payment_Term_Code__c),
            'responsibilityCentre' => 'RC-2025', // Need to confirm
            'salesPersonCode' => 'SP-007', // Need to confirm
            'salesOrderNo' => exOrd.Name,
            'shortClosed' => exOrd.Short_Closed__c,
            'orderTypeId' => exOrd.Order_Type__r.Order_Type_Id__c,
            'ShipToSiteuseCode' => 'SHIP_TO',
            'ShipToPartySiteid' => exOrd.Ship_to_Party__r.Oracle_Site_Code__c,
            'BillToSiteuseCode' => 'BILL_TO',
            'BillToPartySiteid' => exOrd.Bill_to_Party__r.Oracle_Site_Code__c,
            'FobPointCode' => checkNullVal(exOrd.FOB_Terms__c),
            'SecondTransporter' => checkNullVal(exOrd.Second_Transporter__c),
            'Delivery' => checkNullVal(exOrd.Delivery__c),
            'CustomerPaymentMode' => checkNullVal(exOrd.Payment_Mode__c),
            'BusinessUnit' => checkNullVal(exOrd.Business_Unit__c),
            'InstructionSite' => checkNullVal(exOrd.Instruction_to_Site__c),
            'JwExInvNo' => checkNullVal(exOrd.JwExInvNo__c),
            'JwAnnexNo' => checkNullVal(exOrd.JwAnnexNo__c),
            'JwRemarks' => checkNullVal(exOrd.JwRemarks__c),
            'GoodsDesc' => checkNullVal(exOrd.GoodsDesc__c),
            'GrnNumber' => checkNullVal(exOrd.GrnNumber__c),
            'DeliveryChallanNo' => checkNullVal(exOrd.DeliveryChallanNo__c),
            'LotNumber' => checkNullVal(exOrd.LotNumber__c),
            'orderLineItems' => orderLineItems
        };

        Map < String, Object > innerInputParameters = new Map < String, Object > {
            'InputParameters' => innerInputJSON
        };

        Map < String, Object > outerInputParameters = new Map < String, Object > {
            'P_SF_ORDER_NO' => exOrd.Name,
            'P_JSON' => JSON.serialize(innerInputParameters)
        };

        Map < String, Object > finalJson = new Map < String, Object > {
            'InputParameters' => outerInputParameters
        };

        return JSON.serializePretty(finalJson);

    }

    public static String parseresponseBodyData(String responseBody, String soId) {
        String status = '';
        String oracleSO_No = '';

        try {

            // Parse the JSON into a generic map
            Map < String, Object > fullJson = (Map < String, Object > ) JSON.deserializeUntyped(responseBody);

            if (fullJson.containsKey('OutputParameters')) {
                Map < String, Object > outputParams = (Map < String, Object > ) fullJson.get('OutputParameters');

                if (outputParams.containsKey('P_RESPONSE')) {
                    Map < String, Object > pResponse = (Map < String, Object > ) outputParams.get('P_RESPONSE');

                    if (pResponse.containsKey('Row')) {
                        List < Object > rows = (List < Object > ) pResponse.get('Row');

                        if (!rows.isEmpty()) {
                            // Get the first row only
                            Map < String, Object > firstRow = (Map < String, Object > ) rows[0];

                            if (firstRow.containsKey('Column')) {
                                List < Object > columns = (List < Object > ) firstRow.get('Column');

                                for (Object colObj: columns) {
                                    Map < String, Object > column = (Map < String, Object > ) colObj;
                                    String name = (String) column.get('@name');
                                    String value = (String) column.get('$');

                                    status = value;
                                    if (name == 'STATUS') {
                                        status = value;
                                    }
                                    if (name == 'ORACLE_SO_NO') {
                                        oracleSO_No = value;
                                    }
                                }

                                // Check for 'ERROR' in STATUS
                                if (!String.isEmpty(status) && status.toUpperCase().contains('ERROR')) {
                                    System.debug('ERROR in STATUS: ' + status);
                                } else {
                                    System.debug('STATUS is OK: ' + status);
                                    System.debug('oracleSO_No: ' + oracleSO_No);
                                    saveResponseData(oracleSO_No, soId);
                                }
                            }
                        }
                    }
                }
            } else {
                status = responseBody;
            }
        } catch (Exception e) {
            status = e.getMessage();
            System.debug('Error while parsing responseBody: ' + e.getMessage());
        }
        return status;
    }

    public static String getGSTstateCode(String gstNo) {
        String gstValue = gstNo;
        String firstTwoChars = '';

        if (gstValue != null && gstValue.length() >= 2) {
            firstTwoChars = gstValue.substring(0, 2);
            return firstTwoChars;
        } else {
            return null;
        }

    }

    public static void saveResponseData(String ordNo, String soId) {

        Order so = [SELECT Id, Name, Oracle_Sales_Order_No__c, Status FROM Order WHERE Id =: soId];
        so.Oracle_Sales_Order_No__c = ordNo;
        so.Status = 'Activated';
        update so;
    }

    public static String getAllFields(String ObjectName, String ObjId) {

        List < String > fields = new List < String > (Schema.getGlobalDescribe().get(ObjectName).getDescribe().fields.getMap().keySet());
        String query = 'SELECT ';
        if (ObjectName == 'Order') {
            query = query + 'Bill_to_Party__r.GST__c,Ship_to_Party__r.GST__c,Order_Type__r.Order_Type_Id__c,Payment_Term__r.Payment_Term_Id__c,Operating_Unit__r.Operating_Unit_ID__c,Warehouse__r.Organization_Id__c,Bill_to_Party__r.Address_1__c,Bill_to_Party__r.Address_2__c,Bill_to_Party__r.City__r.Name,Bill_to_Party__r.Postal_Code__r.Name,Ship_to_Party__r.Address_1__c,Ship_to_Party__r.Address_2__c,Ship_to_Party__r.City__r.Name,Ship_to_Party__r.Postal_Code__r.Name,Ship_to_Party__r.SF_Address_Code__c,Bill_to_Party__r.SF_Address_Code__c,Account.Name,Account.Customer_Code__c,Ship_to_Party__r.Oracle_Site_Code__c,Bill_to_Party__r.Oracle_Site_Code__c,Account.Oracle_Customer_No__c, ';
            query = query + String.join(fields, ',') + ' FROM ' + ObjectName + ' WHERE Id = \'' + ObjId + '\'';
        } else if (ObjectName == 'OrderItem') {
            query = query + String.join(fields, ',') + ' FROM ' + ObjectName + ' WHERE OrderId = \'' + ObjId + '\'';
        }

        return query;

    }

    public static String getOneLevelLineItemRecords(String ObjectName, String pranetObjectName, String parentRecId) {
        List < String > fields = new List < String > (Schema.getGlobalDescribe().get(ObjectName).getDescribe().fields.getMap().keySet());
        String query = 'SELECT ';
        if (ObjectName == 'OrderItem') {
            query = query + 'Warehouse__r.Organization_Id__c, Order.Name, Product2.Name, Order.Account.Name,Product2.Inventory_Item_Id__c, Product2.Primary_UOM_Code__c, Product2.Secondary_UOM_Code__c, Product2.Organization_Name__r.Organization_Id__c,Order.Account.Type,Order.Order_Type__r.Order_Type_Id__c,Product2.Item_Type__c, ';
        }
        query = query + String.join(fields, ',') + ' FROM ' + ObjectName + ' WHERE ' + pranetObjectName + ' = \'' + parentRecId + '\'';
        return query;
    }

    public static String checkNullVal (String val){
        String retValue;
        if (val == null) {
            retValue = '';
        } else {
            retValue = val;
        }
        return retValue;
    }

}