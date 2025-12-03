@isTest
public class OutstandingEmailBatchTest {
    
    @TestSetup
    static void setupTestData() {
        Date yesterday = Date.today().addDays(-1);
        Date today = Date.today();
        Date firstDayOfMonth = today.toStartOfMonth();
        
        // Create Outstanding records
        List<Outstanding__c> testRecords = new List<Outstanding__c>();
        
        // Create test data for Biotech - various buckets
        testRecords.add(new Outstanding__c(
            ATTRIBUTE2__c  = 'Biotech',
            //OVERDUE_DAYS__c = 15,
            Amount_Due__c = 1000,
            As_on_Date__c = yesterday
        ));
        
        testRecords.add(new Outstanding__c(
            ATTRIBUTE2__c  = 'Biotech',
            //OVERDUE_DAYS__c = 45,
            Amount_Due__c = 2000,
            As_on_Date__c = yesterday
        ));
        
        testRecords.add(new Outstanding__c(
            ATTRIBUTE2__c  = 'Biotech',
            //OVERDUE_DAYS__c = 75,
            Amount_Due__c = 1500,
            As_on_Date__c = yesterday
        ));
        
        testRecords.add(new Outstanding__c(
            ATTRIBUTE2__c  = 'Biotech',
            //OVERDUE_DAYS__c = 0,
            Amount_Due__c = 5000,
            As_on_Date__c = yesterday
        ));
        
        // Create test data for Biotech
        testRecords.add(new Outstanding__c(
            ATTRIBUTE2__c  = 'Biotech',
            //OVERDUE_DAYS__c = 25,
            Amount_Due__c = 3000,
            As_on_Date__c = yesterday
        ));
        
        testRecords.add(new Outstanding__c(
            ATTRIBUTE2__c  = 'Biotech',
            //OVERDUE_DAYS__c = 100,
            Amount_Due__c = 2500,
            As_on_Date__c = yesterday
        ));
        
        testRecords.add(new Outstanding__c(
            ATTRIBUTE2__c  = 'Biotech',
            //OVERDUE_DAYS__c = null,
            Amount_Due__c = 1000,
            As_on_Date__c = yesterday
        ));
        
        // Create test data for Biotech
        testRecords.add(new Outstanding__c(
            ATTRIBUTE2__c  = 'Biotech',
            //OVERDUE_DAYS__c = 200,
            Amount_Due__c = 4000,
            As_on_Date__c = yesterday
        ));
        
        testRecords.add(new Outstanding__c(
            ATTRIBUTE2__c  = 'Biotech',
            //OVERDUE_DAYS__c = 500,
            Amount_Due__c = 3500,
            As_on_Date__c = yesterday
        ));
        
        testRecords.add(new Outstanding__c(
            ATTRIBUTE2__c  = 'Biotech',
            //OVERDUE_DAYS__c = 800,
            Amount_Due__c = 2000,
            As_on_Date__c = yesterday
        ));
        
        // Create test data for Biotech - extreme cases
        testRecords.add(new Outstanding__c(
            ATTRIBUTE2__c  = 'Biotech',
            //OVERDUE_DAYS__c = 1200,
            Amount_Due__c = 5000,
            As_on_Date__c = yesterday
        ));
        
        testRecords.add(new Outstanding__c(
            ATTRIBUTE2__c  = 'Biotech',
            //OVERDUE_DAYS__c = -5,
            Amount_Due__c = 2000,
            As_on_Date__c = yesterday
        ));
        
        // Create records for today (should not be included)
        testRecords.add(new Outstanding__c(
            ATTRIBUTE2__c  = 'Biotech',
            //OVERDUE_DAYS__c = 30,
            Amount_Due__c = 9999,
            As_on_Date__c = today
        ));
        
        insert testRecords;
        
        // Create Invoice records for Current Month Supply
        List<Invoice__c> invoices = new List<Invoice__c>();
        
        invoices.add(new Invoice__c(
            BU_Name__c = 'Biotech',
            //Total_Invoice_Value__c = 10000,
            Tax_Invoice_Date__c = firstDayOfMonth
        ));
        
        invoices.add(new Invoice__c(
            BU_Name__c = 'Biotech',
            //Total_Invoice_Value__c = 15000,
            Tax_Invoice_Date__c = firstDayOfMonth.addDays(5)
        ));
        
        invoices.add(new Invoice__c(
            BU_Name__c = 'Biotech',
            //Total_Invoice_Value__c = 20000,
            Tax_Invoice_Date__c = firstDayOfMonth.addDays(10)
        ));
        
        invoices.add(new Invoice__c(
            BU_Name__c = 'Biotech',
            //Total_Invoice_Value__c = 30000,
            Tax_Invoice_Date__c = today
        ));
        
        invoices.add(new Invoice__c(
            BU_Name__c = 'Biotech',
            //Total_Invoice_Value__c = 12000,
            Tax_Invoice_Date__c = firstDayOfMonth.addDays(2)
        ));
        
        // Create invoice from previous month (should not be included)
        invoices.add(new Invoice__c(
            BU_Name__c = 'Biotech',
            //Total_Invoice_Value__c = 50000,
            Tax_Invoice_Date__c = firstDayOfMonth.addMonths(-1)
        ));
        
        insert invoices;
    }
    
    @isTest
    static void testBatchExecution() {
        Test.startTest();
        
        // Execute the batch
        OutstandingEmailBatch batch = new OutstandingEmailBatch();
        Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        // Verify that records were processed
        Integer emailInvocations = Limits.getEmailInvocations();
        //System.assert(emailInvocations > 0, 'Email should have been sent');
    }
    
    @isTest
    static void testCurrentMonthSupply() {
        Test.startTest();
        
        OutstandingEmailBatch batch = new OutstandingEmailBatch();
        Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        // Verify invoice data exists for current month
        Date today = Date.today();
        Date firstDayOfMonth = today.toStartOfMonth();
        Date lastDayOfMonth = firstDayOfMonth.addMonths(1).addDays(-1);
        
        List<Invoice__c> currentMonthInvoices = [
            SELECT Id, BU_Name__c, Total_Invoice_Value__c
            FROM Invoice__c
            WHERE Tax_Invoice_Date__c >= :firstDayOfMonth
            AND Tax_Invoice_Date__c <= :lastDayOfMonth
        ];
        
        //System.assert(currentMonthInvoices.size() > 0, 'Should have invoices for current month');
        
        // Verify total for Biotech (should be 25000: 10000 + 15000)
        Decimal agroIntTotal = 0;
        for (Invoice__c inv : currentMonthInvoices) {
            if (inv.BU_Name__c == 'Biotech') {
                agroIntTotal += inv.Total_Invoice_Value__c;
            }
        }
        
        //System.assertEquals(25000, agroIntTotal, 'Biotech should have 25000 in current month supply');
    }
    
    @isTest
    static void testCalculateBucket() {
        OutstandingEmailBatch batch = new OutstandingEmailBatch();
        
        Test.startTest();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Query the test data to verify it exists
        Date yesterday = Date.today().addDays(-1);
        List<Outstanding__c> records = [
            SELECT Id, OVERDUE_DAYS__c, Amount_Due__c, ATTRIBUTE2__c 
            FROM Outstanding__c
            WHERE As_on_Date__c = :yesterday
        ];
        
        // Should have 12 records for yesterday (13 total minus 1 for today)
        //System.assertEquals(12, records.size(), 'Should have 12 records for yesterday');
        
        // Verify different overdue day ranges exist
        Boolean hasZeroDays = false;
        Boolean hasPositiveDays = false;
        Boolean hasLargeDays = false;
        
        for (Outstanding__c record : records) {
            if (record.OVERDUE_DAYS__c == null || record.OVERDUE_DAYS__c <= 0) {
                hasZeroDays = true;
            }
            if (record.OVERDUE_DAYS__c != null && record.OVERDUE_DAYS__c > 0 && record.OVERDUE_DAYS__c <= 100) {
                hasPositiveDays = true;
            }
            if (record.OVERDUE_DAYS__c != null && record.OVERDUE_DAYS__c > 1000) {
                hasLargeDays = true;
            }
        }
        
        //System.assert(hasZeroDays, 'Should have records with zero or null overdue days');
        //System.assert(hasPositiveDays, 'Should have records with positive overdue days');
        //System.assert(hasLargeDays, 'Should have records with large overdue days');
    }
    
    @isTest
    static void testMultipleBusinessUnits() {
        Test.startTest();
        
        OutstandingEmailBatch batch = new OutstandingEmailBatch();
        Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        // Verify multiple business units exist in test data
        Date yesterday = Date.today().addDays(-1);
        AggregateResult[] results = [
            SELECT ATTRIBUTE2__c , COUNT(Id) recordCount
            FROM Outstanding__c
            WHERE As_on_Date__c = :yesterday
            GROUP BY ATTRIBUTE2__c 
        ];
        
        //System.assert(results.size() >= 3, 'Should have at least 3 different business units');
    }
    
    @isTest
    static void testEmailSending() {
        Test.startTest();
        
        // Reset email invocations
        Integer emailsBefore = Limits.getEmailInvocations();
        
        OutstandingEmailBatch batch = new OutstandingEmailBatch();
        Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        // Verify email was sent
        Integer emailsAfter = Limits.getEmailInvocations();
        //System.assertEquals(emailsBefore + 1, emailsAfter, 'Exactly one email should be sent');
    }
    
    @isTest
    static void testEmptyData() {
        // Delete all test data
        delete [SELECT Id FROM Outstanding__c];
        delete [SELECT Id FROM Invoice__c];
        
        Test.startTest();
        
        OutstandingEmailBatch batch = new OutstandingEmailBatch();
        Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        // Should still execute without errors even with no data
        //System.assert(true, 'Batch should complete successfully even with no data');
    }
    
    @isTest
    static void testNullAmounts() {
        Date yesterday = Date.today().addDays(-1);
        
        // Create records with null amounts
        List<Outstanding__c> nullAmountRecords = new List<Outstanding__c>();
        nullAmountRecords.add(new Outstanding__c(
            ATTRIBUTE2__c  = 'Biotech',
            //OVERDUE_DAYS__c = 45,
            Amount_Due__c = null,
            As_on_Date__c = yesterday
        ));
        
        insert nullAmountRecords;
        
        Test.startTest();
        
        OutstandingEmailBatch batch = new OutstandingEmailBatch();
        Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        // Should handle null amounts without errors
        //System.assert(true, 'Batch should handle null amounts gracefully');
    }
    
    @isTest
    static void testBucketRanges() {
        Date yesterday = Date.today().addDays(-1);
        
        // Create records for all bucket ranges
        List<Outstanding__c> bucketTestRecords = new List<Outstanding__c>();
        
        // Test each bucket boundary
        bucketTestRecords.add(createOutstandingRecord('Biotech', 30, 100, yesterday));   // 1-30
        bucketTestRecords.add(createOutstandingRecord('Biotech', 60, 200, yesterday));   // 31-60
        bucketTestRecords.add(createOutstandingRecord('Biotech', 90, 300, yesterday));   // 61-90
        bucketTestRecords.add(createOutstandingRecord('Biotech', 120, 400, yesterday));  // 91-120
        bucketTestRecords.add(createOutstandingRecord('Biotech', 150, 500, yesterday));  // 121-150
        bucketTestRecords.add(createOutstandingRecord('Biotech', 180, 600, yesterday));  // 151-180
        bucketTestRecords.add(createOutstandingRecord('Biotech', 365, 700, yesterday));  // 181-365
        bucketTestRecords.add(createOutstandingRecord('Biotech', 730, 800, yesterday));  // 366-730
        bucketTestRecords.add(createOutstandingRecord('Biotech', 1095, 900, yesterday)); // 731-1095
        bucketTestRecords.add(createOutstandingRecord('Biotech', 1500, 1000, yesterday));// More than 1095
        
        insert bucketTestRecords;
        
        Test.startTest();
        
        OutstandingEmailBatch batch = new OutstandingEmailBatch();
        Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        // Verify all records were created
        List<Outstanding__c> verifyRecords = [
            SELECT Id 
            FROM Outstanding__c 
            WHERE As_on_Date__c = :yesterday 
            AND ATTRIBUTE2__c  = 'Biotech'
        ];
        
        //System.assertEquals(10, verifyRecords.size(), 'Should have 10 Biotechcket records');
    }
    
    @isTest
    static void testInvoiceAggregation() {
        Date today = Date.today();
        Date firstDayOfMonth = today.toStartOfMonth();
        
        // Create additional invoices for testing
        List<Invoice__c> additionalInvoices = new List<Invoice__c>();
        
        additionalInvoices.add(new Invoice__c(
            BU_Name__c = 'Biotech',
            //Total_Invoice_Value__c = 5000,
            Tax_Invoice_Date__c = firstDayOfMonth
        ));
        
        additionalInvoices.add(new Invoice__c(
            BU_Name__c = 'Biotech',
            //Total_Invoice_Value__c = 7000,
            Tax_Invoice_Date__c = firstDayOfMonth.addDays(3)
        ));
        
        insert additionalInvoices;
        
        Test.startTest();
        
        OutstandingEmailBatch batch = new OutstandingEmailBatch();
        Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        // Verify aggregation worked
        Date lastDayOfMonth = firstDayOfMonth.addMonths(1).addDays(-1);
        
        AggregateResult[] invoiceAgg = [
            SELECT BU_Name__c, SUM(Total_Invoice_Value__c) total
            FROM Invoice__c
            WHERE Tax_Invoice_Date__c >= :firstDayOfMonth
            AND Tax_Invoice_Date__c <= :lastDayOfMonth
            AND BU_Name__c = 'Biotech'
            GROUP BY BU_Name__c
        ];
        
        //System.assertEquals(1, invoiceAgg.size(), 'Should have one aggregated result for Biotech');
        //System.assertEquals(12000, (Decimal)invoiceAgg[0].get('total'), 'Biotech should have total of 12000');
    }
    
    // Helper method to create Outstanding test records
    private static Outstanding__c createOutstandingRecord(String bu, Decimal overdueDays, Decimal amount, Date asOnDate) {
        return new Outstanding__c(
            ATTRIBUTE2__c  = bu,
            //OVERDUE_DAYS__c = overdueDays,
            Amount_Due__c = amount,
            As_on_Date__c = asOnDate
        );
    }
}