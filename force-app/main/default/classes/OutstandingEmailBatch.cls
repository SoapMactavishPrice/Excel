public class OutstandingEmailBatch implements Database.Batchable<sObject> {
    
    private Date asOnDate;
    
    public OutstandingEmailBatch() {
        this.asOnDate = Date.today().addDays(-1); // YESTERDAY
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query all Outstanding records for yesterday
        String query = 'SELECT Id, OVERDUE_DAYS__c, Amount_Due__c, ATTRIBUTE2__c  ' +
                       'FROM Outstanding__c ' +
                       'WHERE As_on_Date__c = :asOnDate';
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Outstanding__c> scope) {
        // Process in finish method instead
    }
    
    public void finish(Database.BatchableContext bc) {
        // Query all records and calculate buckets in memory
        List<Outstanding__c> records = [
            SELECT Id, OVERDUE_DAYS__c, Amount_Due__c, ATTRIBUTE2__c 
            FROM Outstanding__c
            WHERE As_on_Date__c = :asOnDate
        ];
        
        // Get Current Month Supply data
        Map<String, Decimal> currentMonthSupplyMap = getCurrentMonthSupply();
        
        // Organize data by Business Unit and Bucket
        Map<String, Map<String, Decimal>> dataMap = new Map<String, Map<String, Decimal>>();
        Set<String> allBuckets = new Set<String>();
        
        for (Outstanding__c record : records) {
            String businessUnit = record.ATTRIBUTE2__c  != null ? record.ATTRIBUTE2__c  : 'Unknown';
            String bucket = calculateBucket(record.OVERDUE_DAYS__c);
            Decimal amount = record.Amount_Due__c != null ? record.Amount_Due__c : 0;
            
            // Track all buckets
            allBuckets.add(bucket);
            
            // Initialize business unit map if needed
            if (!dataMap.containsKey(businessUnit)) {
                dataMap.put(businessUnit, new Map<String, Decimal>());
            }
            
            // Initialize bucket amount if needed
            if (!dataMap.get(businessUnit).containsKey(bucket)) {
                dataMap.get(businessUnit).put(bucket, 0);
            }
            
            // Add amount to bucket
            dataMap.get(businessUnit).put(bucket, dataMap.get(businessUnit).get(bucket) + amount);
        }
        
        // Sort buckets
        allBuckets.remove('0'); // Remove '0' from sorting, we'll handle it separately
        List<String> sortedBuckets = sortBuckets(new List<String>(allBuckets));
        
        // Generate HTML email
        String emailBody = generateHTMLTable(dataMap, sortedBuckets, currentMonthSupplyMap);
        
        // Send email
        sendEmail(emailBody);
    }
    
    private Map<String, Decimal> getCurrentMonthSupply() {
        Map<String, Decimal> supplyMap = new Map<String, Decimal>();
        
        // Get first and last day of current month
        Date today = Date.today();
        Date firstDayOfMonth = today.toStartOfMonth();
        Date lastDayOfMonth = firstDayOfMonth.addMonths(1).addDays(-1);
        
        // Query invoices created this month and aggregate by BU
        List<AggregateResult> invoiceResults = [
            SELECT BU_Name__c, SUM(Total_Invoice_Value__c) totalValue
            FROM Invoice__c
            WHERE Tax_Invoice_Date__c >= :firstDayOfMonth
            AND Tax_Invoice_Date__c <= :lastDayOfMonth
            GROUP BY BU_Name__c
        ];
        
        for (AggregateResult ar : invoiceResults) {
            String buName = (String)ar.get('BU_Name__c');
            Decimal totalValue = (Decimal)ar.get('totalValue');
            
            if (buName != null) {
                supplyMap.put(buName, totalValue != null ? totalValue : 0);
            }
        }
        
        return supplyMap;
    }
    
    private String calculateBucket(Decimal overdueDays) {
        if (overdueDays == null || overdueDays <= 0) {
            return '0';
        } else if (overdueDays <= 30) {
            return '1-30';
        } else if (overdueDays <= 60) {
            return '31-60';
        } else if (overdueDays <= 90) {
            return '61-90';
        } else if (overdueDays <= 120) {
            return '91-120';
        } else if (overdueDays <= 150) {
            return '121-150';
        } else if (overdueDays <= 180) {
            return '151-180';
        } else if (overdueDays <= 365) {
            return '181-365';
        } else if (overdueDays <= 730) {
            return '366-730';
        } else if (overdueDays <= 1095) {
            return '731-1095';
        } else {
            return 'More than 1095';
        }
    }
    
    private List<String> sortBuckets(List<String> buckets) {
        // Define the correct order
        List<String> orderedBuckets = new List<String>{
            '1-30', '31-60', '61-90', '91-120', '121-150', '151-180',
            '181-365', '366-730', '731-1095', 'More than 1095'
        };
        
        List<String> sortedList = new List<String>();
        for (String bucket : orderedBuckets) {
            if (buckets.contains(bucket)) {
                sortedList.add(bucket);
            }
        }
        
        return sortedList;
    }
    
    private String generateHTMLTable(Map<String, Map<String, Decimal>> dataMap, 
                                    List<String> sortedBuckets, 
                                    Map<String, Decimal> currentMonthSupplyMap) {
        String html = '<html><head><style>';
        html += 'table { border-collapse: collapse; font-family: Arial, sans-serif; width: 100%; }';
        html += 'th, td { border: 1px solid #ddd; padding: 8px; }';
        html += 'th { background-color: #333; color: white; text-align: center; font-size: 12px; }';
        html += 'td { text-align: right; font-size: 11px; }';
        html += 'td:first-child { text-align: left; font-weight: bold; background-color: #f9f9f9; }';
        html += '.total-row { background-color: #333; color: white; font-weight: bold; }';
        html += '.subtotal { background-color: #f0f0f0; font-weight: bold; }';
        html += '</style></head><body>';
        
        html += '<h2>Currency - INR in Cr.</h2>';
        html += '<h3>As on date: ' + asOnDate.format() + '</h3>';
        html += '<table>';
        
        // Header row
        html += '<tr>';
        html += '<th>Business Unit</th>';
        
        // Add bucket columns
        for (String bucket : sortedBuckets) {
            html += '<th>' + bucket + '</th>';
        }
        
        html += '<th>Due (A)</th>';
        html += '<th>Not Due (B)</th>';
        html += '<th>Total OS (A+B)</th>';
        html += '<th>Current Month Supply</th>';
        html += '</tr>';
        
        // Data rows
        Decimal grandTotalDueA = 0;
        Decimal grandTotalNotDueB = 0;
        Decimal grandTotalOS = 0;
        Decimal grandTotalCurrentMonthSupply = 0;
        Map<String, Decimal> bucketTotals = new Map<String, Decimal>();
        
        // Initialize bucket totals
        for (String bucket : sortedBuckets) {
            bucketTotals.put(bucket, 0);
        }
        
        List<String> businessUnits = new List<String>(dataMap.keySet());
        businessUnits.sort();
        
        for (String businessUnit : businessUnits) {
            Map<String, Decimal> bucketData = dataMap.get(businessUnit);
            
            html += '<tr>';
            html += '<td>' + businessUnit + '</td>';
            
            Decimal rowTotalDueA = 0;
            Decimal rowTotalNotDueB = 0;
            
            // Add bucket values
            for (String bucket : sortedBuckets) {
                Decimal amount = bucketData.containsKey(bucket) ? bucketData.get(bucket) : 0;
                html += '<td>' + formatAmount(amount) + '</td>';
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
            Decimal currentMonthSupply = currentMonthSupplyMap.containsKey(businessUnit) ? 
                                        currentMonthSupplyMap.get(businessUnit) : 0;
            
            html += '<td class="subtotal">' + formatAmount(rowTotalDueA) + '</td>';
            html += '<td class="subtotal">' + formatAmount(rowTotalNotDueB) + '</td>';
            html += '<td class="subtotal">' + formatAmount(rowTotalOS) + '</td>';
            html += '<td>' + formatAmount(currentMonthSupply) + '</td>';
            html += '</tr>';
            
            grandTotalDueA += rowTotalDueA;
            grandTotalNotDueB += rowTotalNotDueB;
            grandTotalOS += rowTotalOS;
            grandTotalCurrentMonthSupply += currentMonthSupply;
        }
        
        // Total row
        html += '<tr class="total-row">';
        html += '<td>Total</td>';
        
        // Display totals for each bucket
        for (String bucket : sortedBuckets) {
            Decimal bucketTotal = bucketTotals.get(bucket);
            html += '<td>' + formatAmount(bucketTotal) + '</td>';
        }
        
        html += '<td>' + formatAmount(grandTotalDueA) + '</td>';
        html += '<td>' + formatAmount(grandTotalNotDueB) + '</td>';
        html += '<td>' + formatAmount(grandTotalOS) + '</td>';
        html += '<td>' + formatAmount(grandTotalCurrentMonthSupply) + '</td>';
        html += '</tr>';
        
        html += '</table>';
        html += '</body></html>';
        
        return html;
    }
    
    private String formatAmount(Decimal amount) {
        if (amount == 0) {
            return '0';
        }
        return amount.setScale(2).format();
    }
    
    private void sendEmail(String emailBody) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        // Set recipient email addresses - UPDATE THIS WITH ACTUAL RECIPIENTS
        String[] toAddresses = new String[] {'praveen@finessedirect.com', 'praveenlog17122001@gmail.com', 'balram@finessedirect.com', 'balramp610@gmail.com' };
        mail.setToAddresses(toAddresses);
        
        // Set subject
        mail.setSubject('Overdue Aging Report - ' + asOnDate.format());
        
        // Set HTML body
        mail.setHtmlBody(emailBody);
        
        // Optional: Set reply-to
        // mail.setReplyTo('noreply@yourcompany.com');
        
        // Send email
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            System.debug('Email sent successfully to: ' + toAddresses);
        } catch (Exception e) {
            System.debug('Error sending email: ' + e.getMessage());
            // Consider logging the error or sending an alert
        }
    }
}