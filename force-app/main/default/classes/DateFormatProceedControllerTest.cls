@isTest
private class DateFormatProceedControllerTest {
    
    @isTest
    static void testGetMonthIndex() {
        // Define a sample fiscal start date (e.g., April 1, 2024)
        Date fiscalStartDate = Date.newInstance(2024, 4, 1); // Fiscal year starts in April

        // Call the method with different months
        Integer index1 = DateFormatProceedController.getMonthIndex(fiscalStartDate, 'JUNE');
        Integer index2 = DateFormatProceedController.getMonthIndex(fiscalStartDate, 'APRIL');
        Integer index3 = DateFormatProceedController.getMonthIndex(fiscalStartDate, 'JANUARY');

        // Debug logs to verify values
        System.debug('Index for JUNE: ' + index1);
        System.debug('Index for APRIL: ' + index2);
        System.debug('Index for JANUARY: ' + index3);
    }

    @isTest
    static void testGetStartDateOfMonth() {
        // Define a sample fiscal start date
        Date fiscalStartDate = Date.newInstance(2024, 4, 1); // Fiscal starts in April
        
        // Call the method with different months
        Date startJune = DateFormatProceedController.getStartDateOfMonth(fiscalStartDate, 'JUNE');
        Date startApril = DateFormatProceedController.getStartDateOfMonth(fiscalStartDate, 'APRIL');
        Date startJanuary = DateFormatProceedController.getStartDateOfMonth(fiscalStartDate, 'JANUARY');

        // Debug logs to verify values
        System.debug('Start date for JUNE: ' + startJune);
        System.debug('Start date for APRIL: ' + startApril);
        System.debug('Start date for JANUARY: ' + startJanuary);
    }

    @isTest
    static void testGetEndDateOfMonth() {
        // Define a sample fiscal start date
        Date fiscalStartDate = Date.newInstance(2024, 4, 1); // Fiscal starts in April

        // Call the method with different months
        Date endJune = DateFormatProceedController.getEndDateOfMonth(fiscalStartDate, 'JUNE');
        Date endApril = DateFormatProceedController.getEndDateOfMonth(fiscalStartDate, 'APRIL');
        Date endJanuary = DateFormatProceedController.getEndDateOfMonth(fiscalStartDate, 'JANUARY');

        // Debug logs to verify values
        System.debug('End date for JUNE: ' + endJune);
        System.debug('End date for APRIL: ' + endApril);
        System.debug('End date for JANUARY: ' + endJanuary);
    }
}