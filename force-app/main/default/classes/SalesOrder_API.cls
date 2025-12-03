@RestResource(urlMapping='/CreateUpdateSalesOrder')
global class SalesOrder_API {
    @HttpPost
    global static void doPost() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        String jSONRequestBody = request.requestBody.toString().replace('\n', '');
        
        // ------------------- API LOG to track the request -------------------
        API_Log__c api_log = new API_Log__c();
        api_log.Log_Name__c = 'CreateUpdateSalesOrder';
        api_log.Request__c = jSONRequestBody;
        api_log.Request_Time__c = DateTime.now();

        JSON2ApexSaveWebToLead jsonObj = JSON2ApexSaveWebToLead.parse(jSONRequestBody);
        System.debug('======----->jsonObj' + jsonObj);

        try {

            if (String.isBlank(jsonObj.customerNo) && String.isBlank(jsonObj.no)) {
                throw new IllegalArgumentException('customerNo and no required');
            } else {
                List<Account> accList = [
                    SELECT Id, Name, Customer_Code__c FROM Account WHERE Customer_Code__c =: jsonObj.customerNo
                ];
                if (accList.size() > 0) {

                    List<Order> ordList = [
                        SELECT Id, Name FROM Order WHERE Name =: jsonObj.no
                    ];  

                    Order ord = new Order();
                    if (ordList.size() > 0) {
                        ord.Id = ordList[0].Id;
                    } else {
                        ord.CurrencyIsoCode = jsonObj.currencyISOCode;
                    }
                    ord.AccountId = accList[0].Id;
                    ord.Status = 'Draft';
                    ord.Name = jsonObj.no;
                    if (jsonObj.operatingUnitId != null && jsonObj.operatingUnitId != '') {
                        List < Operating_Unit__c > ou = [
                            SELECT Id, Name
                            FROM Operating_Unit__c
                            WHERE Name =: jsonObj.operatingUnitId
                        ];
                        if(ou.size() > 0){
                            ord.Operating_Unit__c = ou[0].Id;
                        }
                    }
                    if (jsonObj.warehouseId != null && jsonObj.warehouseId != '') {
                        List < Organization__c > ou = [
                            SELECT Id, Organization_Id__c 
                            FROM Organization__c
                            WHERE Organization_Id__c  =: Decimal.valueOf(jsonObj.warehouseId)
                        ];
                        if(ou.size() > 0){
                            ord.Warehouse__c = ou[0].Id;
                        }
                    }
                    ord.Customer_Code__c = jsonObj.customerNo;
                    ord.Price_List__c = jsonObj.priceListId;
                    // ord.Customer_Code__c = jsonObj.poNumber;
                    ord.EffectiveDate = Date.valueOf(jsonObj.orderDate);
                    ord.Requested_Delivery_Date__c = Date.valueOf(jsonObj.requestedDeliveryDate);
                    ord.Promised_Delivery_Date__c = Date.valueOf(jsonObj.promisedDeliveryDate);
                    ord.External_Document_No__c = jsonObj.externalDocumentNo;
                    ord.Your_Reference__c = jsonObj.yourReference;
                    ord.PoDate = Date.valueOf(jsonObj.poReceivedDate);
                    ord.Bill_To_Name__c = jsonObj.billToName;
                    ord.Bill_To_Address__c = jsonObj.billToAddress;
                    ord.Bill_To_Address_2__c = jsonObj.billToAddress2;
                    ord.Bill_To_City__c = jsonObj.billToCity;
                    ord.Bill_To_Contact__c = jsonObj.billToContact;
                    ord.Bill_To_Postal_Code__c = jsonObj.billToPostCode;
                    ord.Bill_To_Country_Region_Code__c = jsonObj.billToCountryRegionCode;
                    ord.GST_Bill_To_State_Code__c = jsonObj.gstBillToStateCode;
                    ord.Ship_To_Name__c = jsonObj.shipToName;
                    ord.Ship_To_Address__c = jsonObj.shipToAddress;
                    ord.Ship_To_Address_2__c = jsonObj.shipToAddress2;
                    ord.Ship_To_City__c = jsonObj.shipToCity;
                    ord.Ship_To_Contact__c = jsonObj.shipToContact;
                    ord.Ship_To_Postal_Code__c = jsonObj.shipToPostCode;
                    ord.Ship_To_Country_Region_Code__c = jsonObj.shipToCountryRegionCode;
                    ord.GST_Ship_To_State_Code__c = jsonObj.gstShipToStateCode;
                    ord.Ship_To_GST_Reg_No__c = jsonObj.shipToGSTRegNo;
                    ord.Description = jsonObj.workDesrcription;
                    ord.Comment__c = jsonObj.comment;
                    ord.Sell_To_Contact__c = jsonObj.sellToContact;
                    ord.Sell_To_Email__c = jsonObj.sellToEmail;
                    ord.Sell_To_Phone_No__c = jsonObj.sellToPhoneNo;
                    ord.Payment_Term_Code__c = jsonObj.paymentTermCode;
                    ord.Sales_Person_Code__c = jsonObj.salesPersonCode;
                    ord.ERP_Order_No__c = jsonObj.salesOrderNo;
                    ord.Short_Closed__c = Boolean.valueOf(jsonObj.shortClosed);

                    upsert ord;

                    List<OrderLineItemWrapper> orderLineItemList = new List<OrderLineItemWrapper>();
                    if (jsonObj.orderLineItems != null && jsonObj.orderLineItems.size() > 0) {
                        orderLineItemList = jsonObj.orderLineItems;
                        List < OrderItem > insertOrderLineItem = new List < OrderItem > ();

                        for (OrderLineItemWrapper ordline: orderLineItemList) {
                            OrderItem ordlineItem = new OrderItem();
                        }
                    }

                    System.debug('-->Data Saved Successfully');
                    // ------------------- Send the Success Response -------------------
                    Map < string, object > successResMap = new Map < string, object > ();
                    successResMap.put('status', 'success');
                    successResMap.put('message', 'Sales Order Created Successfully');
                    successResMap.put('sfdcId', ord.Id);
                    // successResMap.put('uniqueID', acc.Customer_Code__c);
                    String resp = JSON.serialize(successResMap);
                    response.responseBody = Blob.valueOf(resp);
                    response.addHeader('Content-Type', 'application/json');
                    response.statusCode = 200;

                    api_log.Log_Status__c = 'Success';
                    api_log.Response_Code__c = '200';
                    api_log.Response__c = String.valueOf(resp);
                    api_log.response_time__c = Datetime.now();
                    
                } else {
                    throw new IllegalArgumentException('customerNo is InValid');
                }
            }

        } catch (Exception e) {
            System.debug('Catch Error' + e.getStackTraceString());
            System.debug('Catch Error' + e.getMessage());
            System.debug('Catch Error' + e.getlineNumber());

            // ------------------- Create Response Map -------------------
            Map < string, string > errorResMap = new Map < string, string > ();
            errorResMap.put('status', 'Something went wrong. Line Number ' + e.getlineNumber());
            errorResMap.put('message', e.getMessage());

            // ------------------- Send Response Map -------------------
            String resp = JSON.serialize(errorResMap);
            response.responseBody = Blob.valueOf(resp);
            response.addHeader('Content-Type', 'application/json');
            response.statusCode = 400;
            
            api_log.Log_Status__c = 'Failure';
            api_log.Response_Code__c = '400';
            api_log.Exception_Description__c = 'Line Number : ' + e.getLineNumber() + ' \n\n ' + e.getMessage() + '\n\n' + e.getStackTraceString();
            api_log.Response_Time__c = Datetime.now();
            
        }
        
        insert api_log;

    }

    public class JSON2ApexSaveWebToLead {
        public String no;
        public String operatingUnitId;
        public String priceListId;
        public String warehouseId;
        public String currencyISOCode;
        public String poNumber;
        public String customerName;
        public String dispatcherInformation;
        public String customerNo;
        public String orderDate;
        public String requestedDeliveryDate;
        public String promisedDeliveryDate;
        public String externalDocumentNo;
        public String yourReference;
        public String poReceivedDate;
        public String billToName;
        public String billToAddress;
        public String billToAddress2;
        public String billToCity;
        public String billToContact;
        public String billToPostCode;
        public String billToCountryRegionCode;
        public String gstBillToStateCode;
        public String shipToName;
        public String shipToAddress;
        public String shipToAddress2;
        public String shipToCity;
        public String shipToContact;
        public String shipToPostCode;
        public String shipToCountryRegionCode;
        public String gstShipToStateCode; 
        public String shipToGSTRegNo;
        public String workDesrcription;
        public String comment;
        public String sellToContact;
        public String sellToEmail;
        public String sellToPhoneNo;
        public String paymentTermCode;
        public String responsibilityCentre;
        public String salesPersonCode;
        public String salesOrderNo;
        public String shortClosed;
        public List<OrderLineItemWrapper> orderLineItems;
    }

    public class OrderLineItemWrapper{
        public String sfOrderNo;
        public String lineType;
        public String inventoryItem;
        public Integer lineNo;
        public Integer quantity;
        public String unitofMeasureCode;
        public Decimal unitPrice;
        public Date requestedDeliveryDate;
        public Date promisedDeliveryDate;
        public String salesOrderNo;
        public String type;
        public String no;
        public String description;
        public String customerDescription;
        public Decimal lineDiscount;
        public Boolean foc;
        public String productType;
        public String orderType;
        public String customerType;
        public String remarks;
        public String comment;
        public Decimal uomConversionFactor;
        public Boolean shortClosed;
    }

    public static JSON2ApexSaveWebToLead parse(String json) {
        return (JSON2ApexSaveWebToLead) System.JSON.deserialize(json, JSON2ApexSaveWebToLead.class);
    }

}