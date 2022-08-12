@isTest
private class skedDateTimeUtils_Practice {
    @isTest
    static void practiceDateTimeUtils() {
        
        DateTime currentDateTime = DateTime.now();
        //setting up the timzone
        String vnTimezone = 'Asia/Saigon';
        String sydneyTimezone = 'Australia/Sydney';
        
        //Initainlize the datetime
        DateTime dateInstance = datetime.newInstance(2023, 10, 03,09,00,00); // O9:00 AM time
        DateTime sydneyStartOfDateTime = datetime.newInstance(2023, 10, 03,12,00,00); // 12:00 AM time
        
        DateTime sydney9amStartDate = skedDateTimeUtils.toTimezone(sydneyStartOfDateTime,sydneyTimezone);
        
        DateTime vn9am = skedDateTimeUtils.toTimezone(dateInstance,vnTimezone);
        DateTime sydney9am = skedDateTimeUtils.toTimezone(dateInstance,sydneyTimezone);
        DateTime sydneyStartOfDate = skedDateTimeUtils.getStartOfDate(sydney9amStartDate,sydneyTimezone); // Get the start day of time based on SydneyTimezone
        DateTime sydneyNextDate = skedDateTimeUtils.addDays(sydneyStartOfDate, 1, sydneyTimezone);
        
        //-----------------------System.Assert to check for the condition-----------------------
         System.assertEquals('03/10/2023 09:00 AM', vn9am.format(skedDateTimeUtils.DATE_TIME_DMY_FORMAT, vnTimezone));
         System.assertEquals('03/10/2023 09:00 AM', sydney9am.format(skedDateTimeUtils.DATE_TIME_DMY_FORMAT, sydneyTimezone));
         System.assertEquals('03/10/2023 12:00 AM', sydneyStartOfDate.format(skedDateTimeUtils.DATE_TIME_DMY_FORMAT, sydneyTimezone));
         System.assertEquals('04/10/2023 12:00 AM', sydneyNextDate.format(skedDateTimeUtils.DATE_TIME_DMY_FORMAT, sydneyTimezone));
    }
}
