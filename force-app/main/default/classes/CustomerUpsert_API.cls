@RestResource(urlMapping='/CreateUpdateCustomer')
global class CustomerUpsert_API {
    @HttpPost
    global static void doPost() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        String jSONRequestBody = request.requestBody.toString().replace('\n', '');
        
        // ------------------- API LOG to track the request -------------------
        API_Log__c api_log = new API_Log__c();
        api_log.Log_Name__c = 'CreateUpdateCustomer';
        api_log.Request__c = jSONRequestBody;
        api_log.Request_Time__c = DateTime.now();

        JSON2ApexSaveWebToLead jsonObj = JSON2ApexSaveWebToLead.parse(jSONRequestBody);
        System.debug('======----->jsonObj' + jsonObj);

        try {

            List < Organization__c > org = new List < Organization__c >();

            if (String.isBlank(jsonObj.customerNo)) { // Replacing 'uniqueID' with 'customerNo'
                throw new IllegalArgumentException('customerNo required');
            } else {
                List<Account> existingAccount = [SELECT Id, Name, Customer_Code__c FROM Account WHERE Customer_Code__c =: jsonObj.customerNo];
                Account acc = new Account();
                if (existingAccount.size() > 0) {
                    acc.Id = existingAccount[0].Id;
                    acc.Customer_Code__c = existingAccount[0].Customer_Code__c;
                } else {
                    acc.Customer_Code__c = jsonObj.customerNo;
                }

                acc.Blocked__c = jsonObj.blocked;
                // acc.Location__c = jsonObj.location;
                acc.Gen_Bus_Posting_Group__c = jsonObj.genBusPostingGroup;
                acc.Customer_Posting_Group__c = jsonObj.customerPostingGroup;
                acc.Customer_Group__c = jsonObj.customerGroup;
                // acc.Customer_Code__c = jsonObj.territoryCode;
                acc.GST_Customer_Type__c = jsonObj.gstCustomerType;
                acc.GSTIN_No__c = jsonObj.gstRegistrationNo;
                acc.PAN_Status__c = jsonObj.panStatus;
                acc.PAN_No__c = jsonObj.panNo;
                acc.Sales_Person_Code__c = jsonObj.salesPersonCode;
                // acc.Customer_Code__c = jsonObj.responsibilityCentre;
                acc.Credit_Limit__c = jsonObj.creditLimitLCY;
                acc.Payment_Terms__c = jsonObj.paymentTerms;
                // acc.Customer_Code__c = jsonObj.currencyCode;
                // acc.Customer_Code__c = jsonObj.uniqueID;
                acc.Phone = jsonObj.customerPhoneNo;
                acc.Telephone_Extension__c = jsonObj.telephoneExtension;
                acc.Telephone_Type__c = jsonObj.telephoneType;
                acc.Telephone_Area_Code__c = jsonObj.telephoneAreaCode;
                acc.Contact__c = jsonObj.contact;
                acc.Contact_First_Name__c = jsonObj.contactFirstName;
                acc.Contact_Last_Name__c = jsonObj.contactLastName;
                acc.Company_Email_Address__c = jsonObj.eMail;
                acc.Country_Code__c = jsonObj.countryRegionCode;
                // acc.BillingPostalCode = jsonObj.postcode;
                // acc.BillingState = jsonObj.state;
                // acc.BillingCity = jsonObj.city;
                // acc.Address_2__c = jsonObj.customerAddress2;
                // acc.Address_1__c = jsonObj.customerAddress;
                acc.Name = jsonObj.customerName;
                // acc.Site_Use__c = jsonObj.siteUse;
                // acc.Customer_Code__c = jsonObj.customerNo;
                if (jsonObj.org_id != null) {
                    org = [
                        SELECT Id, Organization_Id__c 
                        FROM Organization__c 
                        WHERE Organization_Id__c =: jsonObj.org_id
                    ];
                }
                
                acc.Gender__c = jsonObj.gender;
                upsert acc;

                List<RecordType> addressRecordTypeList = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Address_Information__c'];
                Map<String, String> addressRecordTypeMap = new Map<String, String>();
                for (RecordType rt : addressRecordTypeList) {
                    String tname = '';
                    if (rt.Name == 'Bill To') {
                        tname = 'BILL_TO';
                    } else if (rt.Name == 'Ship To') {
                        tname = 'SHIP_TO';
                    }
                    addressRecordTypeMap.put(tname, rt.Id);
                }
                System.debug(addressRecordTypeMap);

                List<AddressInfoClass> addressList = jsonObj.address;
                List<Address_Information__c> addInfoListtoUpsert = new List<Address_Information__c>();
                
                if (addressList != null && addressList.size() > 0) {
                    if (existingAccount.size() > 0) {
                        for (AddressInfoClass aic : addressList) {
                            String sname = aic.siteUse+' - '+ aic.siteUseCode+'%';
                            List<Address_Information__c> addInfoList = new List<Address_Information__c>();
                            Address_Information__c addInfo = new Address_Information__c();
                            addInfoList = [
                                SELECT Id, Name
                                FROM Address_Information__c
                                WHERE Account__c =: acc.Id
                                AND Name = :sname
                            ];
                            if (addInfoList.size() > 0) {
                                addInfo.Id = addInfoList[0].Id;
                            } else {
                                addInfo.RecordTypeId = addressRecordTypeMap.get(aic.siteUse);
                                addInfo.Account__c = acc.Id;
                                addInfo.Name = aic.siteUse+' - '+aic.siteUseCode;
                                addInfo.Site_Use_Code__c = aic.siteUseCode;
                                if (org.size() > 0) {
                                    addInfo.Organization__c = org[0].Id;
                                }
                            }
                            if (!String.isBlank(aic.postcode)) {
                                List<Postal_Code__c> postcodeList = [SELECT Id, Name FROM Postal_Code__c WHERE Name =: aic.postcode];
                                if (postcodeList.size() > 0) {
                                    addInfo.Postal_Code__c = postcodeList[0].Id;
                                }
                            }
                            if (!String.isBlank(aic.state)) {
                                List<State__c> stateList = [SELECT Id, Name FROM State__c WHERE Name =: aic.state];
                                if (stateList.size() > 0) {
                                    addInfo.State__c = stateList[0].Id;
                                }
                            }
                            if (!String.isBlank(aic.city)) {
                                List<City__c> cityList = [SELECT Id, Name FROM City__c WHERE Name =: aic.city];
                                if (cityList.size() > 0) {
                                    addInfo.City__c = cityList[0].Id;
                                }
                            }
                            if (!String.isBlank(aic.location)) {
                                List<Area__c> locationList = [SELECT Id, Name FROM Area__c WHERE Name =: aic.location];
                                if (locationList.size() > 0) {
                                    addInfo.Area__c = locationList[0].Id;
                                }
                            }
                            if (!String.isBlank(aic.country)) {
                                List<Country__c> countryList = [SELECT Id, Name FROM Country__c WHERE Name =: aic.country];
                                if (countryList.size() > 0) {
                                    addInfo.Country__c = countryList[0].Id;
                                }
                            }
                            addInfo.Address_2__c = aic.customerAddress2;
                            addInfo.Address_1__c = aic.customerAddress;
                            addInfo.Primary_Address__c = aic.primaryAddress;

                            addInfoListtoUpsert.add(addInfo);
                        }
                    } else {
                        for (AddressInfoClass var : addressList) {
                            Address_Information__c addInfo = new Address_Information__c();
                            addInfo.RecordTypeId = addressRecordTypeMap.get(var.siteUse);
                            addInfo.Account__c = acc.Id;
                            addInfo.Name = var.siteUse+' - '+var.siteUseCode;
                            addInfo.Site_Use_Code__c = var.siteUseCode;
                            if (org.size() > 0) {
                                addInfo.Organization__c = org[0].Id;
                            }
                            if (!String.isBlank(var.postcode)) {
                                List<Postal_Code__c> postcodeList = [SELECT Id, Name FROM Postal_Code__c WHERE Name =: var.postcode];
                                if (postcodeList.size() > 0) {
                                    addInfo.Postal_Code__c = postcodeList[0].Id;
                                }
                            }
                            if (!String.isBlank(var.state)) {
                                List<State__c> stateList = [SELECT Id, Name FROM State__c WHERE Name =: var.state];
                                if (stateList.size() > 0) {
                                    addInfo.State__c = stateList[0].Id;
                                }
                            }
                            if (!String.isBlank(var.city)) {
                                List<City__c> cityList = [SELECT Id, Name FROM City__c WHERE Name =: var.city];
                                if (cityList.size() > 0) {
                                    addInfo.City__c = cityList[0].Id;
                                }
                            }
                            if (!String.isBlank(var.location)) {
                                List<Area__c> locationList = [SELECT Id, Name FROM Area__c WHERE Name =: var.location];
                                if (locationList.size() > 0) {
                                    addInfo.Area__c = locationList[0].Id;
                                }
                            }
                            if (!String.isBlank(var.country)) {
                                List<Country__c> countryList = [SELECT Id, Name FROM Country__c WHERE Name =: var.country];
                                if (countryList.size() > 0) {
                                    addInfo.Country__c = countryList[0].Id;
                                }
                            }
                            addInfo.Address_2__c = var.customerAddress2;
                            addInfo.Address_1__c = var.customerAddress;
                            addInfo.Primary_Address__c = var.primaryAddress;

                            addInfoListtoUpsert.add(addInfo);
                        }
                    }
                }

                if (addInfoListtoUpsert.size() > 0) {
                    System.debug(addInfoListtoUpsert);
                    upsert addInfoListtoUpsert;
                }

                System.debug('-->Data Saved Successfully');
                // ------------------- Send the Success Response -------------------
                Map < string, object > successResMap = new Map < string, object > ();
                successResMap.put('status', 'success');
                successResMap.put('message', 'Customer Upsert Successfully');
                successResMap.put('sfdcId', acc.Id);
                successResMap.put('uniqueID/customerNo', acc.Customer_Code__c);
                String resp = JSON.serialize(successResMap);
                response.responseBody = Blob.valueOf(resp);
                response.addHeader('Content-Type', 'application/json');
                response.statusCode = 200;

                api_log.Log_Status__c = 'Success';
                api_log.Response_Code__c = '200';
                api_log.Response__c = String.valueOf(resp);
                api_log.response_time__c = Datetime.now();
            }
            
        } catch (Exception e) {
            System.debug('Catch Error' + e.getStackTraceString());
            System.debug('Catch Error' + e.getMessage());
            System.debug('Catch Error' + e.getlineNumber());

            // ------------------- Create Response Map -------------------
            Map < string, string > errorResMap = new Map < string, string > ();
            errorResMap.put('status', 'Something went wrong');
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
        public String uniqueID;
        public Boolean blocked;
        // public String location;
        public String genBusPostingGroup;
        public String customerPostingGroup;
        public String customerGroup;
        public String territoryCode;
        public String gstCustomerType;
        public String gstRegistrationNo;
        public String panStatus;
        public String panNo;
        public String salesPersonCode;
        public String responsibilityCentre;
        public Decimal creditLimitLCY;
        public String paymentTerms;
        public String currencyCode;
        public String sfdcCustomerNo;
        public String customerPhoneNo;
        public String contact;
        public String eMail;
        public String countryRegionCode;
        // public String postcode;
        // public String state;
        // public String city;
        // public String country;
        public String customerAddress2;
        public String customerAddress;
        public String customerName;
        public String customerNo;
        public String telephoneExtension;
        public String telephoneType;
        public String telephoneAreaCode;
        public String contactFirstName;
        public String contactLastName;
        public Decimal org_id;
        public String gender;
        public List<AddressInfoClass> address;
    }
    
    public class AddressInfoClass {
        public String siteUse;
        public String siteUseCode;
        public String postcode;
        public String state;
        public String city;
        public String location;
        public String country;
        public String customerAddress2;
        public String customerAddress;
        public Boolean primaryAddress;
    }
    

    public static JSON2ApexSaveWebToLead parse(String json) {
        return (JSON2ApexSaveWebToLead) System.JSON.deserialize(json, JSON2ApexSaveWebToLead.class);
    }

}