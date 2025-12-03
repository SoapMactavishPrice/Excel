public with sharing class EnhancedCustomLookup {
    public EnhancedCustomLookup() {}

    @AuraEnabled(cacheable = true)
    public static List<sObject> findRecords(
        String searchKey, 
        String objectName, 
        String recdataid, 
        String returnFields, 
        List<String> queryFields, 
        String displayFields, 
        String filter, 
        String sortColumn, 
        String maxResults,
        String parentAccountId // New parameter for account filtering
    ) {
        // Combine returnFields and displayFields
        String a = '';
        if (returnFields != null && returnFields.trim() != '') {
            a = returnFields;
        }
        if (displayFields != null && displayFields.trim() != '') {
            a = (a == '' ? displayFields : a + ',' + displayFields);
        }
        
        // Remove duplicate fields
        Set<String> fieldSet = new Set<String>();
        String col = '';
        if (a.trim() != '') {
            for (String t: a.split(',')) {
                fieldSet.add(t.trim());
            }
            for (String t: fieldSet) {
                col = col + ',' + t;
            }
        }

        string searchText = '\'%' + String.escapeSingleQuotes(searchKey) + '%\'';

        String fields = '';
        if (objectName == 'Case') {
            fields = 'CaseNumber ';
        } else {
            fields = 'Name ';
        }

        // Build base query
        String vQuery = 'SELECT Id, ' + fields + col + ' FROM ' + objectName + ' WHERE ';
		system.debug('objectName--'+objectName);
        // Add account filter if provided for Contact object
        if (objectName == 'Contact' && parentAccountId != null && parentAccountId != '') {
            vQuery += ' AccountId = \'' + String.escapeSingleQuotes(parentAccountId) + '\' AND ';
        }

        // Add search conditions
        if (queryFields == null || queryFields.isEmpty()) {
            if (objectName == 'Case') {
                vQuery += ' CaseNumber LIKE ' + searchText;
            } else {
                vQuery += ' Name LIKE ' + searchText;
            }
        } else {
            string likeField = '';
            system.debug('queryFields->'+queryFields+ ' -- ' +searchText);
            for (string field: queryFields) {
                likeField += ' OR ' + field + ' LIKE ' + searchText;
            }
            vQuery += ' (' + likeField.removeStart(' OR ') + ') ';
        }

        if (objectName == 'User') {
            string currentUserId = UserInfo.getUserId();
            vQuery += ' AND Id != \'' + currentUserId + '\'';

        }

        // Add additional filter if provided
        System.debug('filter'+filter);
        if (filter != null && filter != '') {
            vQuery += ' AND (' + filter + ')';
        }

        // Add sorting
        if (sortColumn != null && sortColumn != '') {
            vQuery += ' ORDER BY ' + sortColumn;
        }

        // Set limit
        if (maxResults == null || maxResults == '') {
            maxResults = '10';
        }
        vQuery += ' LIMIT ' + maxResults;

        System.debug('Query: ' + vQuery);
        return Database.query(vQuery);
    }

    @AuraEnabled
    public static sObject fetchDefaultRecord(string recordId, string sObjectApiName, string returnFields) {
        string sRecId = recordId;

        if (returnFields != null && returnFields != '') {
            returnFields = ',' + returnFields;
        } else {
            returnFields = '';
        }
        
        String fields = '';
        if (sObjectApiName == 'Case') {
            fields = 'CaseNumber ';
        } else {
            fields = 'Name ';
        }
        
        string sQuery = 'Select Id, ' + fields + returnFields + ' From ' + sObjectApiName + ' Where Id = : sRecId LIMIT 1';
        for (sObject obj: database.query(sQuery)) {
            return obj;
        }
        return null;
    }
}