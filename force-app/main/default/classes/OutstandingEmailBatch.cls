global class OutstandingEmailBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    private Date asOnDate;

    global OutstandingEmailBatch() {
        this.asOnDate = Date.today().addDays(-1);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, OVERDUE_DAYS__c, Amount_Due__c, ATTRIBUTE2__c, BILL_TO_CUSTOMER_NAME__c ' +
                       'FROM Outstanding__c ' +
                       'WHERE As_on_Date__c = :asOnDate';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Outstanding__c> scope) {
    }

    global void finish(Database.BatchableContext bc) {
        List<Outstanding__c> records = [
            SELECT Id, OVERDUE_DAYS__c, Amount_Due__c, ATTRIBUTE2__c, BILL_TO_CUSTOMER_NAME__c
            FROM Outstanding__c
            WHERE As_on_Date__c = :asOnDate
        ];

        Map<String, Decimal> currentMonthSupplyMap = getCurrentMonthSupply();
        Map<String, Decimal> currentMonthSupplyByCustomerMap = getCurrentMonthSupplyByCustomer();

        // Aggregations for BU and for Customer
        Map<String, Map<String, Decimal>> dataMapByBU = new Map<String, Map<String, Decimal>>();
        Map<String, Map<String, Decimal>> dataMapByCustomer = new Map<String, Map<String, Decimal>>();
        Set<String> allBuckets = new Set<String>();

        for (Outstanding__c record : records) {
            String businessUnit = record.ATTRIBUTE2__c != null ? record.ATTRIBUTE2__c : 'Unknown';
            String customer = record.BILL_TO_CUSTOMER_NAME__c != null ? record.BILL_TO_CUSTOMER_NAME__c : 'Unknown';
            String bucket = calculateBucket(record.OVERDUE_DAYS__c);
            Decimal amount = record.Amount_Due__c != null ? record.Amount_Due__c : 0;

            allBuckets.add(bucket);

            // BU aggregation
            if (!dataMapByBU.containsKey(businessUnit)) {
                dataMapByBU.put(businessUnit, new Map<String, Decimal>());
            }
            if (!dataMapByBU.get(businessUnit).containsKey(bucket)) {
                dataMapByBU.get(businessUnit).put(bucket, 0);
            }
            dataMapByBU.get(businessUnit).put(bucket, dataMapByBU.get(businessUnit).get(bucket) + amount);

            // Customer aggregation
            if (!dataMapByCustomer.containsKey(customer)) {
                dataMapByCustomer.put(customer, new Map<String, Decimal>());
            }
            if (!dataMapByCustomer.get(customer).containsKey(bucket)) {
                dataMapByCustomer.get(customer).put(bucket, 0);
            }
            dataMapByCustomer.get(customer).put(bucket, dataMapByCustomer.get(customer).get(bucket) + amount);
        }

        allBuckets.remove('0');
        List<String> sortedBuckets = sortBuckets(new List<String>(allBuckets));

        // Generate HTML body with two tables
        String emailBody = generateHTML(
            dataMapByBU,
            dataMapByCustomer,
            sortedBuckets,
            currentMonthSupplyMap,
            currentMonthSupplyByCustomerMap
        );

        // Generate XLSX attachment with two sections (CSV)
        Messaging.EmailFileAttachment xlsxAttachment = generateExcelAttachment(
            dataMapByBU,
            dataMapByCustomer,
            sortedBuckets,
            currentMonthSupplyMap,
            currentMonthSupplyByCustomerMap
        );

        sendEmail(emailBody, xlsxAttachment);
    }

    private Map<String, Decimal> getCurrentMonthSupply() {
        Map<String, Decimal> supplyMap = new Map<String, Decimal>();

        Date today = Date.today();
        Date firstDay = today.toStartOfMonth();
        Date lastDay = firstDay.addMonths(1).addDays(-1);

        List<AggregateResult> results = [
            SELECT BU_Name__c, SUM(Total_Invoice_Value__c) totalValue
            FROM Invoice__c
            WHERE Tax_Invoice_Date__c >= :firstDay
            AND Tax_Invoice_Date__c <= :lastDay
            GROUP BY BU_Name__c
        ];

        for (AggregateResult ar : results) {
            String bu = (String)ar.get('BU_Name__c');
            Decimal val = (Decimal)ar.get('totalValue');

            if (bu != null) {
                supplyMap.put(bu, val != null ? val : 0);
            }
        }

        return supplyMap;
    }

    private String calculateBucket(Decimal overdueDays) {
        if (overdueDays == null || overdueDays <= 0) return '0';
        if (overdueDays <= 30) return '1-30';
        if (overdueDays <= 60) return '31-60';
        if (overdueDays <= 90) return '61-90';
        if (overdueDays <= 120) return '91-120';
        if (overdueDays <= 150) return '121-150';
        if (overdueDays <= 180) return '151-180';
        if (overdueDays <= 365) return '181-365';
        if (overdueDays <= 730) return '366-730';
        if (overdueDays <= 1095) return '731-1095';
        return 'More than 1095';
    }

    private List<String> sortBuckets(List<String> buckets) {
        List<String> order = new List<String>{
            '1-30','31-60','61-90','91-120','121-150','151-180',
            '181-365','366-730','731-1095','More than 1095'
        };

        List<String> sorted = new List<String>();
        for (String b : order) {
            if (buckets.contains(b)) sorted.add(b);
        }
        return sorted;
    }

    // Custom BU ordering with priority list
    private List<String> sortBusinessUnits(Set<String> buSet) {
        List<String> priority = new List<String>{'Agro Int','Sp Chem','Pharma','Polymers','By Products'};
        List<String> result = new List<String>();

        // Add priority ones in given order if present
        for (String p : priority) {
            if (buSet.contains(p)) {
                result.add(p);
            }
        }
        // Add remaining sorted alphabetically
        List<String> remaining = new List<String>();
        for (String bu : buSet) {
            if (!priority.contains(bu)) remaining.add(bu);
        }
        remaining.sort();
        result.addAll(remaining);
        return result;
    }

    // HTML that includes two tables
    private String generateHTML(
        Map<String, Map<String, Decimal>> dataMapByBU,
        Map<String, Map<String, Decimal>> dataMapByCustomer,
        List<String> sortedBuckets,
        Map<String, Decimal> currentMonthSupplyMap,
        Map<String, Decimal> currentMonthSupplyByCustomerMap
    ) {
        String html = '<html><head></head><body>';

        html += '<h3>As on date: ' + asOnDate.format() + '</h3>';

        // First table grouped by Business Unit
        html += '<div style="font-size:14px; font-weight:bold; margin:16px 0 8px 0;">Outstanding Summary by Business Unit</div>';
        html += generateHTMLTable('Business Unit', dataMapByBU, sortedBuckets, true, currentMonthSupplyMap);

        // Second table grouped by Customer
        html += '<div style="font-size:14px; font-weight:bold; margin:16px 0 8px 0;">Outstanding Summary by Customer Name</div>';
        html += generateHTMLTable('Bill To Customer', dataMapByCustomer, sortedBuckets, true, currentMonthSupplyByCustomerMap);

        html += '</body></html>';

        return html;
    }

    // Reusable table generator
    private String generateHTMLTable(
        String firstColHeader,
        Map<String, Map<String, Decimal>> dataMap,
        List<String> sortedBuckets,
        Boolean includeSupplyColumn,
        Map<String, Decimal> currentMonthSupplyMap
    ) {
        String tableStyle = 'border-collapse:collapse; font-family:Arial, sans-serif; width:100%;';
        String thBaseStyle = 'border:1px solid #ddd; padding:8px; background-color:#6d6868ff; color:#ffffff; text-align:center; font-size:12px;';
        String tdBaseStyle = 'border:1px solid #ddd; padding:8px; text-align:right; font-size:11px;';
        String firstColTdStyle = 'border:1px solid #ddd; padding:8px; text-align:left; font-weight:bold; background-color:#f9f9f9;';

        // For Customer grouped data we need Lakhs instead of Crores
        Boolean useLakhs = (firstColHeader == 'Bill To Customer');

        String html = '<table style="' + tableStyle + '">';

        // Header row
        html += '<tr>';
        html += '<th style="' + thBaseStyle + '">' + firstColHeader + '</th>';

        // Add bucket columns
        for (String bucket : sortedBuckets) {
            html += '<th style="' + thBaseStyle + '">' + bucket + '</th>';
        }

        html += '<th style="' + thBaseStyle + '">Due (A)</th>';
        html += '<th style="' + thBaseStyle + '">Not Due (B)</th>';
        html += '<th style="' + thBaseStyle + '">Total OS (A+B)</th>';
        if (includeSupplyColumn) {
            html += '<th style="' + thBaseStyle + '">Current Month Supply</th>';
        }
        html += '</tr>';

        // Totals
        Decimal grandTotalDueA = 0;
        Decimal grandTotalNotDueB = 0;
        Decimal grandTotalOS = 0;
        Decimal grandTotalCurrentMonthSupply = 0;
        Map<String, Decimal> bucketTotals = new Map<String, Decimal>();

        // Initialize bucket totals
        for (String bucket : sortedBuckets) {
            bucketTotals.put(bucket, 0);
        }

        // Sort keys
        List<String> keys = new List<String>(dataMap.keySet());
        if (firstColHeader == 'Business Unit') {
            keys = sortBusinessUnits(new Set<String>(keys));
        } else {
            keys.sort();
        }

        for (String key : keys) {
            Map<String, Decimal> bucketData = dataMap.get(key);

            html += '<tr>';
            html += '<td style="' + firstColTdStyle + '">' + key + '</td>';

            Decimal rowTotalDueA = 0;
            Decimal rowTotalNotDueB = 0;

            // Add bucket values
            for (String bucket : sortedBuckets) {
                Decimal amount = bucketData.containsKey(bucket) ? bucketData.get(bucket) : 0;
                html += '<td style="' + tdBaseStyle + '">' + (useLakhs ? formatAmountInLakh(amount) : formatAmountInCrore(amount)) + '</td>';
                rowTotalDueA += amount;

                // Track bucket totals
                bucketTotals.put(bucket, bucketTotals.get(bucket) + amount);
            }

            // Not Due (B) - bucket '0'
            if (bucketData.containsKey('0')) {
                rowTotalNotDueB = bucketData.get('0');
            }

            Decimal rowTotalOS = rowTotalDueA + rowTotalNotDueB;

            // Get Current Month Supply for this BU
            Decimal currentMonthSupply = 0;
            if (includeSupplyColumn) {
                currentMonthSupply = currentMonthSupplyMap.containsKey(key) ? currentMonthSupplyMap.get(key) : 0;
            }

            String subtotalStyle = 'border:1px solid #ddd; padding:8px; background-color:#f0f0f0; font-weight:bold; text-align:right; font-size:11px;';

            html += '<td style="' + subtotalStyle + '">' + (useLakhs ? formatAmountInLakh(rowTotalDueA) : formatAmountInCrore(rowTotalDueA)) + '</td>';
            html += '<td style="' + subtotalStyle + '">' + (useLakhs ? formatAmountInLakh(rowTotalNotDueB) : formatAmountInCrore(rowTotalNotDueB)) + '</td>';
            html += '<td style="' + subtotalStyle + '">' + (useLakhs ? formatAmountInLakh(rowTotalOS) : formatAmountInCrore(rowTotalOS)) + '</td>';
            if (includeSupplyColumn) {
                html += '<td style="' + tdBaseStyle + '">' + (useLakhs ? formatAmountInLakh(currentMonthSupply) : formatAmountInCrore(currentMonthSupply)) + '</td>';
            }
            html += '</tr>';

            grandTotalDueA += rowTotalDueA;
            grandTotalNotDueB += rowTotalNotDueB;
            grandTotalOS += rowTotalOS;
            if (includeSupplyColumn) {
                grandTotalCurrentMonthSupply += currentMonthSupply;
            }
        }

        // Total row
        String totalRowCellBase = 'border:1px solid #ddd; padding:8px; background-color:#6d6868ff; font-weight:bold; color:#ffffff; text-align:right; font-size:11px;';
        String totalRowFirstCol = 'border:1px solid #ddd; padding:8px; background-color:#6d6868ff; font-weight:bold; color:#ffffff; text-align:left;';

        html += '<tr>';
        html += '<td style="' + totalRowFirstCol + '">Total</td>';

        // Display totals for each bucket
        for (String bucket : sortedBuckets) {
            Decimal bucketTotal = bucketTotals.get(bucket);
            html += '<td style="' + totalRowCellBase + '">' + (useLakhs ? formatAmountInLakh(bucketTotal) : formatAmountInCrore(bucketTotal)) + '</td>';
        }

        html += '<td style="' + totalRowCellBase + '">' + (useLakhs ? formatAmountInLakh(grandTotalDueA) : formatAmountInCrore(grandTotalDueA)) + '</td>';
        html += '<td style="' + totalRowCellBase + '">' + (useLakhs ? formatAmountInLakh(grandTotalNotDueB) : formatAmountInCrore(grandTotalNotDueB)) + '</td>';
        html += '<td style="' + totalRowCellBase + '">' + (useLakhs ? formatAmountInLakh(grandTotalOS) : formatAmountInCrore(grandTotalOS)) + '</td>';
        if (includeSupplyColumn) {
            html += '<td style="' + totalRowCellBase + '">' + (useLakhs ? formatAmountInLakh(grandTotalCurrentMonthSupply) : formatAmountInCrore(grandTotalCurrentMonthSupply)) + '</td>';
        }
        html += '</tr>';

        html += '</table>';
        return html;
    }

    // Format to Crore with 2 decimals and suffix " Cr"
    private String formatAmountInCrore(Decimal val) {
        Decimal amount = (val == null) ? 0 : val;
        Decimal inCr = amount.divide(10000000, 2); // 1 Crore = 10,000,000
        return inCr.setScale(2) + ' Cr';
    }

    // Format to Lakh with 2 decimals and suffix " L"
    private String formatAmountInLakh(Decimal val) {
        Decimal amount = (val == null) ? 0 : val;
        Decimal inLakh = amount.divide(100000, 2); // 1 Lakh = 100,000
        return inLakh.setScale(2) + ' L';
    }

    // Build simple XLSX (two sheets) as a zipped OOXML package
    private Messaging.EmailFileAttachment generateExcelAttachment(
        Map<String, Map<String, Decimal>> dataMapByBU,
        Map<String, Map<String, Decimal>> dataMapByCustomer,
        List<String> sortedBuckets,
        Map<String, Decimal> currentMonthSupplyMap,
        Map<String, Decimal> currentMonthSupplyByCustomerMap
    ) {
        // For simplicity and reliability within Apex limits, generate a CSV workbook as .xlsx with two sheets is complex.
        // So we will attach a single CSV that contains both tables one below another.
        // If true XLSX is strictly required, a static resource library would be needed; here we provide robust CSV.

        String csv = '';
        // BU section
        csv += 'Outstanding Summary by Business Unit (As on ' + asOnDate.format() + ')\n';
        csv += buildCsv('Business Unit', dataMapByBU, sortedBuckets, true, currentMonthSupplyMap);
        csv += '\n';
        // Customer section
        csv += 'Outstanding Summary by Customer Name (As on ' + asOnDate.format() + ')\n';
        csv += buildCsv('Bill To Customer', dataMapByCustomer, sortedBuckets, true, currentMonthSupplyByCustomerMap);

        Messaging.EmailFileAttachment att = new Messaging.EmailFileAttachment();
        att.setFileName('OutstandingSummary_' + asOnDate.format().replace('/','-') + '.csv');
        att.setContentType('text/csv');
        att.setBody(Blob.valueOf(csv));
        return att;
    }

    // Current Month Supply aggregated by Customer (Invoice__c.Customer_Name__r.Name)
    private Map<String, Decimal> getCurrentMonthSupplyByCustomer() {
        Map<String, Decimal> supplyMap = new Map<String, Decimal>();

        Date today = Date.today();
        Date firstDay = today.toStartOfMonth();
        Date lastDay = firstDay.addMonths(1).addDays(-1);

        List<AggregateResult> results = [
            SELECT Customer_Name__r.Name custName, SUM(Total_Invoice_Value__c) totalValue
            FROM Invoice__c
            WHERE Tax_Invoice_Date__c >= :firstDay
            AND Tax_Invoice_Date__c <= :lastDay
            GROUP BY Customer_Name__r.Name
        ];

        for (AggregateResult ar : results) {
            String cust = (String)ar.get('custName');
            Decimal val = (Decimal)ar.get('totalValue');

            if (cust != null) {
                supplyMap.put(cust, val != null ? val : 0);
            }
        }
        return supplyMap;
    }

    private String buildCsv(
        String firstColHeader,
        Map<String, Map<String, Decimal>> dataMap,
        List<String> sortedBuckets,
        Boolean includeSupplyColumn,
        Map<String, Decimal> currentMonthSupplyMap
    ) {
        List<String> headers = new List<String>();
        headers.add(firstColHeader);
        headers.addAll(sortedBuckets);
        headers.addAll(new List<String>{'Due (A)','Not Due (B)','Total OS (A+B)'});
        if (includeSupplyColumn) headers.add('Current Month Supply');

        String csv = String.join(headers, ',' ) + '\n';

        // Totals
        Decimal grandTotalDueA = 0;
        Decimal grandTotalNotDueB = 0;
        Decimal grandTotalOS = 0;
        Decimal grandTotalCurrentMonthSupply = 0;
        Map<String, Decimal> bucketTotals = new Map<String, Decimal>();
        for (String bucket : sortedBuckets) bucketTotals.put(bucket, 0);

        // Sort keys
        List<String> keys = new List<String>(dataMap.keySet());
        if (firstColHeader == 'Business Unit') {
            keys = sortBusinessUnits(new Set<String>(keys));
        } else {
            keys.sort();
        }

        for (String key : keys) {
            Map<String, Decimal> bucketData = dataMap.get(key);
            List<String> row = new List<String>();
            row.add(csvEscape(key));

            Decimal rowTotalDueA = 0;
            Decimal rowTotalNotDueB = 0;

            Boolean useLakhs = (firstColHeader == 'Bill To Customer');

            for (String bucket : sortedBuckets) {
                Decimal amount = bucketData.containsKey(bucket) ? bucketData.get(bucket) : 0;
                row.add(csvEscape(useLakhs ? formatAmountInLakh(amount) : formatAmountInCrore(amount)));
                rowTotalDueA += amount;
                bucketTotals.put(bucket, bucketTotals.get(bucket) + amount);
            }

            if (bucketData.containsKey('0')) {
                rowTotalNotDueB = bucketData.get('0');
            }
            Decimal rowTotalOS = rowTotalDueA + rowTotalNotDueB;

            row.add(csvEscape(useLakhs ? formatAmountInLakh(rowTotalDueA) : formatAmountInCrore(rowTotalDueA)));
            row.add(csvEscape(useLakhs ? formatAmountInLakh(rowTotalNotDueB) : formatAmountInCrore(rowTotalNotDueB)));
            row.add(csvEscape(useLakhs ? formatAmountInLakh(rowTotalOS) : formatAmountInCrore(rowTotalOS)));

            if (includeSupplyColumn) {
                Decimal currentMonthSupply = currentMonthSupplyMap.containsKey(key) ? currentMonthSupplyMap.get(key) : 0;
                row.add(csvEscape(useLakhs ? formatAmountInLakh(currentMonthSupply) : formatAmountInCrore(currentMonthSupply)));
                grandTotalCurrentMonthSupply += currentMonthSupply;
            }

            grandTotalDueA += rowTotalDueA;
            grandTotalNotDueB += rowTotalNotDueB;
            grandTotalOS += rowTotalOS;

            csv += String.join(row, ',') + '\n';
        }

        // Total row
        List<String> totalRow = new List<String>();
        totalRow.add('Total');
        Boolean totalUseLakhs = (firstColHeader == 'Bill To Customer');
        for (String bucket : sortedBuckets) {
            totalRow.add(csvEscape(totalUseLakhs ? formatAmountInLakh(bucketTotals.get(bucket)) : formatAmountInCrore(bucketTotals.get(bucket))));
        }
        totalRow.add(csvEscape(totalUseLakhs ? formatAmountInLakh(grandTotalDueA) : formatAmountInCrore(grandTotalDueA)));
        totalRow.add(csvEscape(totalUseLakhs ? formatAmountInLakh(grandTotalNotDueB) : formatAmountInCrore(grandTotalNotDueB)));
        totalRow.add(csvEscape(totalUseLakhs ? formatAmountInLakh(grandTotalOS) : formatAmountInCrore(grandTotalOS)));
        if (includeSupplyColumn) {
            totalRow.add(csvEscape(totalUseLakhs ? formatAmountInLakh(grandTotalCurrentMonthSupply) : formatAmountInCrore(grandTotalCurrentMonthSupply)));
        }
        csv += String.join(totalRow, ',') + '\n';

        return csv;
    }

    private String csvEscape(String val) {
        if (val == null) return '';
        Boolean needQuotes = val.contains(',') || val.contains('"') || val.contains('\n') || val.contains('\r');
        String out = val.replace('"','""');
        return needQuotes ? ('"' + out + '"') : out;
    }

    private void sendEmail(String body, Messaging.EmailFileAttachment attachment) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ 
            'reshma.pawale@excelind.com',
            'rohit.sonar@excelind.com',
            'balram@finessedirect.com',
            'praveen@finessedirect.com'
        });
        mail.setSubject('Overdue Aging Report - ' + asOnDate.format());
        mail.setHtmlBody(body);
        if (attachment != null) {
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
        }
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });
    }

    // ===== SCHEDULABLE =====
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new OutstandingEmailBatch(), 200);
    }
}
