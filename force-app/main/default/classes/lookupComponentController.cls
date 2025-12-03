public without sharing class lookupComponentController {
    @AuraEnabled(cacheable = true)
    public static string findRecords(string indusId, string deptId, String searchKey, String objectName,
        String recdataid, string returnFields, List < String > queryFields, String displayFields,
        String filter, String sortColumn, String maxResults, Boolean searchWithMiddle, string family, string currencyCode) {

        set < id > indId = new set < id > {
            indusId
        };
        set < id > depId = new set < id > {
            deptId
        };

        String a = '';
        if (returnFields != null && returnFields.trim() != '') {
            a = returnFields;
        }
        if (displayFields != null && displayFields.trim() != '') {
            a = (a == '' ? displayFields : a + ',' + displayFields);
        }
        Set < String > b = new Set < String > ();
        String col = '';
        if (a.trim() != '') {
            for (String t: a.split(',')) {
                b.add(t.trim());
            }
            for (String t: b) {
                col = col + ',' + t;
            }
        }

        string searchText = '';
        //if(searchWithMiddle == true){
        searchText = '\'%' + String.escapeSingleQuotes(searchKey) + '%\'';
        //}else {
        //  searchText = '\'' + String.escapeSingleQuotes(searchKey) + '%\'';
        //}

        List < AggregateResult > agr = [select count(Id) total, ProductCode from product2 group by ProductCode];

        String vQuery = '';

        if (objectName == 'PricebookEntry') {

            vQuery = 'SELECT Id, Product2Id, UnitPrice,Product2.Name, Product2.Family,ProductCode FROM PricebookEntry where IsActive = true AND CurrencyIsoCode = \'' + String.escapeSingleQuotes(currencyCode) + '\'';

            if (string.isNotBlank(searchKey)) {
                vQuery += ' AND (Product2.Name LIKE ' + searchText + ' OR Product2.ProductCode LIKE ' + searchText + ')';
                //vQuery +=' and Family =\''+family+'\'';
            } else {
                if (string.isNotBlank(family)) {
                    // vQuery +=' where Family =\''+family+'\'';
                }
            }
        } else if (objectName == 'Order') {
            vQuery = 'SELECT Id, Name FROM Order WHERE Name != null';
            if (string.isNotBlank(searchKey)) {
                // vQuery += ' WHERE (Name LIKE ' + searchText + ' OR OrderNumber LIKE ' + searchText + ')';
                vQuery += ' AND Name LIKE ' + searchText + '';
            }
        }


        // vQuery += 'limit 10';
        /*if (queryFields == null || queryFields.isEmpty()) {
        vQuery += ' Name LIKE ' + searchText;
        } else {
        string likeField = '(';
        for(string field : queryFields) {
        likeField += field + ' LIKE ' + searchText +' OR ';
        }
        likeField+=')';
        system.debug('0-->'+likeField);
        vQuery += ' (' + likeField.removeStart(' OR ') + ') ';
        system.debug('1-->'+vQuery);
        }
        */
        if (filter != null && filter != '') {
            vQuery += ' AND (' + filter + ')';
        }

        if (sortColumn != null && sortColumn != '') {
            vQuery += ' ORDER BY ' + sortColumn;
        }

        if (maxResults == null || maxResults == '') {
            maxResults = '10';
        }

        //vQuery += ' LIMIT ' + maxResults;

        System.debug(vQuery);

        String actualResponse = '';

        if (objectName == 'PricebookEntry') {

            List < string > prodCodeList = new List < string > ();
            List < Wrapper > returnList = new List < Wrapper > ();
            for (PricebookEntry p2: Database.query(vQuery)) {
                if (!prodCodeList.contains(p2.ProductCode)) {
                    Wrapper wrp = new Wrapper();
                    wrp.Id = p2.Id;
                    wrp.Name = p2.Product2.Name;
                    wrp.productCode = p2.ProductCode;
                    wrp.familyField = p2.Product2.Family;
                    wrp.unitPrice = p2.UnitPrice;
                    wrp.proId = p2.Product2Id;
                    prodCodeList.add(p2.ProductCode);
                    returnList.add(wrp);
                }

            }
            system.debug('prodCodeList ->' + prodCodeList.size() + ' --  ' + prodCodeList);
            system.debug('returnList ->' + returnList.size() + ' --  ' + returnList);


            actualResponse = JSON.serialize(returnList);

        } else if (objectName == 'Order') {

            List < OrderWrapper > returnList = new List < OrderWrapper > ();
            
            for (Order p2: Database.query(vQuery)) {

                OrderWrapper wrp = new OrderWrapper();
                wrp.Id = p2.Id;
                wrp.Name = p2.Name;
                returnList.add(wrp);
            }
            actualResponse = JSON.serialize(returnList);
        }

        
        return actualResponse;
    }

    @AuraEnabled
    public static string fetchDefaultRecord(string recordId, string sObjectApiName, string returnFields) {
        string sRecId = recordId;

        if (returnFields != null && returnFields != '') {
            returnFields = ',' + returnFields;
        } else {
            returnFields = '';
        }
        string sQuery = 'SELECT Id, Product2Id, UnitPrice,Product2.Name, Product2.Family,ProductCode	 FROM PricebookEntry where Id = \'' + recordId + '\' LIMIT 1';
        //sQuery = 'SELECT Id, Product2Id, UnitPrice,Product2.Name, Product2.Family,Product2.ProductCode '+ returnFields + ' From ' + sObjectApiName + ' Where Id = : sRecId LIMIT 1';
        system.debug('sQuery' + sQuery);
        for (PricebookEntry p2: database.query(sQuery)) {
            Wrapper wrp = new Wrapper();
            wrp.Id = p2.Id;
            wrp.Name = p2.Product2.Name;
            wrp.productCode = p2.ProductCode;
            wrp.familyField = p2.Product2.Family;
            wrp.unitPrice = p2.UnitPrice;
            wrp.proId = p2.Product2Id;
            return JSON.serialize(wrp);
        }
        return null;
    }

    public class Wrapper {
        public string Id;
        public string Name;
        public string productCode;
        public String familyField {
            get;
            set;
        }
        public decimal unitPrice {
            get;
            set;
        }
        public String proId {
            get;
            set;
        }

    }

    public class OrderWrapper {
        public string Id;
        public string Name;
    }

}