public class DateFormatProceedController {
	public static Integer getMonthIndex(Date fiscalStartDate, String monthName) {
        system.debug('monthName-->'+monthName);
        Map<String, Integer> monthNames = new Map<String, Integer>{
            'JANUARY' => 1,
            'FEBRUARY' => 2,
            'MARCH' => 3,
            'APRIL' => 4,
            'MAY' => 5,
            'JUNE' => 6,
            'JULY' => 7,
            'AUGUST' => 8,
            'SEPTEMBER' => 9,
            'OCTOBER' => 10,
            'NOVEMBER' => 11,
            'DECEMBER' => 12
        };
        
        Integer targetMonth = monthNames.get(monthName);
        
        Integer fiscalYearStartMonth = fiscalStartDate.month();
        system.debug('fiscalYearStartMonth--'+fiscalYearStartMonth);
        Integer fiscalYearStartYear = fiscalStartDate.year();
        system.debug('fiscalYearStartYear--'+fiscalYearStartYear);
        system.debug('targetMonth--'+targetMonth);
        Integer i = 0;
        if (targetMonth < fiscalYearStartMonth) {
            
            i = (targetMonth + 12) - fiscalYearStartMonth;
            system.debug('if --'+i);
        } else {
           
            i = targetMonth - fiscalYearStartMonth;
            system.debug('else --'+i);
            
        }
        return i;
    }

    public static Date getStartDateOfMonth(Date fiscalStartDate, String month) {
        Integer monthIndex = getMonthIndex(fiscalStartDate, month);
        return fiscalStartDate.addMonths(monthIndex).toStartOfMonth();
    }

    public static Date getEndDateOfMonth(Date fiscalStartDate, String month) {
        Date startDate = getStartDateOfMonth(fiscalStartDate, month);
        return startDate.toStartOfMonth().addMonths(1).addDays(-1);
    }
}