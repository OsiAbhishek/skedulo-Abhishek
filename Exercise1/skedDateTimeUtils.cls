public class skedDateTimeUtils {

    public static final string DATE_FORMAT = 'MM/dd/yyyy';
    public static final string TIME_FORMAT = 'h:mma';
    public static final string DATE_TIME_FORMAT = 'MM/dd/yyyy hh:mm a';
    public static final string DATE_ISO_FORMAT = 'yyyy-MM-dd';
    public static final string DATE_TIME_ISO_FORMAT = 'yyyy-MM-ddThh:mm:ssZ';
    public static final String INT_TIME_FORMAT = 'Hmm';
    public static final String DATE_YMD_FORMAT = 'yyyy-MM-dd';
    public static final String DATE_DMY_FORMAT = 'dd/MM/yyyy';
    public static final String DATE_TIME_DMY_FORMAT = 'dd/MM/yyyy hh:mm a';
    public static final string DATE_OF_WEEK_FORMAT = 'EEE';

    // Switch DateTime from current user timezone to expected timezone
    public static DateTime toTimezone(DateTime input, string toTimezoneSidId) {
        return switchTimezone(input, UserInfo.getTimeZone().getID(), toTimezoneSidId);
    }

    // Switch DateTime from one timezone to another timezone
    public static DateTime switchTimezone(DateTime input, string fromTimezoneSidId, string toTimezoneSidId) {
        if (fromTimezoneSidId == toTimezoneSidId) {
            return input;
        }
        TimeZone fromTz = Timezone.getTimeZone(fromTimezoneSidId);
        Timezone toTz = Timezone.getTimeZone(toTimezoneSidId);
        integer offsetMinutes = fromTz.getOffset(input) - toTz.getOffset(input);
        offsetMinutes = offsetMinutes / 60000;
        input = addMinutes(input, offsetMinutes, toTimezoneSidId);
        return input;
    }

    public static DateTime addMinutes(DateTime input, integer minutes, string timezoneSidId) {
        DateTime result = input.addMinutes(minutes);
        Timezone tz = Timezone.getTimezone(timezoneSidId);
        integer inputOffset = tz.getOffset(input) / 60000;
        integer resultOffset = tz.getOffset(result) / 60000;
        result = result.addMinutes(inputOffset - resultOffset);

        return result;
    }

    public static DateTime addDays(DateTime input, integer days, string timezoneSidId) {
        DateTime result = input.addDays(days);
        Timezone tz = Timezone.getTimezone(timezoneSidId);
        integer inputOffset = tz.getOffset(input) / 60000;
        integer resultOffset = tz.getOffset(result) / 60000;
        result = result.addMinutes(inputOffset - resultOffset);

        return result;
    }

    public static DateTime addMonths(DateTime input, integer months, string timezoneSidId) {
        DateTime result = input.addMonths(months);
        Timezone tz = Timezone.getTimezone(timezoneSidId);
        integer inputOffset = tz.getOffset(input) / 60000;
        integer resultOffset = tz.getOffset(result) / 60000;
        result = result.addMinutes(inputOffset - resultOffset);

        return result;
    }

    public static DateTime addYears(DateTime input, integer years, string timezoneSidId) {
        DateTime result = input.addYears(years);
        Timezone tz = Timezone.getTimezone(timezoneSidId);
        integer inputOffset = tz.getOffset(input) / 60000;
        integer resultOffset = tz.getOffset(result) / 60000;
        result = result.addMinutes(inputOffset - resultOffset);

        return result;
    }

    public static Date getDate(DateTime input, string timezoneSidId) {
        string dateIsoString = input.format(DATE_ISO_FORMAT, timezoneSidId);
        return getDateFromIsoString(dateIsoString);
    }

    // isoString should have the format yyyy-MM-dd
    public static Date getDateFromIsoString(string isoString) {
        return (Date)Json.deserialize('"' + isoString + '"', Date.class);
    }

    public static DateTime getDateTimeFromIsoString(string isoString) {
        return (DateTime)Json.deserialize('"' + isoString + '"', DateTime.class);
    }

    // Get 12:00:00 am from the input isoString date
    public static DateTime getStartOfDate(String isoString, string timezoneSidId) {
        return getStartOfDate(getDateFromIsoString(isoString), timezoneSidId);
    }

    public static DateTime getStartOfDate(DateTime input, string timezoneSidId) {
        Date inputDate = getDate(input, timezoneSidId);
        return getStartOfDate(inputDate, timezoneSidId);
    }

    public static DateTime getStartOfDate(Date input, string timezoneSidId) {
        DateTime result = DateTime.newInstance(input, time.newInstance(0, 0, 0, 0));
        result = toTimezone(result, timezoneSidId);
        return result;
    }

    // Get 12:00:00 am on next Date, from the input isoString date
    public static DateTime getEndOfDate(String isoString, string timezoneSidId) {
        return getEndOfDate(getDateFromIsoString(isoString), timezoneSidId);
    }

    public static DateTime getEndOfDate(DateTime input, string timezoneSidId) {
        DateTime dateStart = getStartOfDate(input, timezoneSidId);
        return addDays(dateStart, 1, timezoneSidId);
    }

    public static DateTime getEndOfDate(Date input, string timezoneSidId) {
        DateTime dateStart = getStartOfDate(input, timezoneSidId);
        return addDays(dateStart, 1, timezoneSidId);
    }

    // @param inputTime: 730
    // @result: 730 or 07:30, will be considered as 7 hour and 30 minutes so the result should be 7 * 60 + 30 = 450
    public static integer convertTimeNumberToMinutes(integer input) {
        return integer.valueOf(input / 100) * 60 + Math.mod(input, 100);
    }

    // convert integer in minute to Time Number. ex: Minutes 450 -> 730
    public static integer convertMinutesToTimeNumber(integer mins){
    	return math.mod(mins, 60) + Integer.valueOf(mins / 60) * 100;
    }

    public static integer getDifferenteMinutes(DateTime dtime1, DateTime dTime2) {
        if (dtime1 != null && dTime2 != null) {
            return Integer.valueOf((dTime2.getTime() - dtime1.getTime())/60000);
        }
        return NULL;
    }

    public static DateTime newDateTimeInstance(Date dateValue, integer timeInt, string timezoneSidId) {
        if (dateValue != NULL && timeInt != NULL) {
            Integer timeInMinutes = convertTimeNumberToMinutes(timeInt);
            DateTime dateStart = getStartOfDate(dateValue, timezoneSidId);
            DateTime dateTimeValue = addMinutes(dateStart, timeInMinutes, timezoneSidId);
            return dateTimeValue;
        }
        return NULL;
    }

    public static DateTime newDateTimeInstance(string dateStr, integer timeInt, string timezoneSidId) {
        if (dateStr != NULL) {
            Date dateValue = getDateFromIsoString(dateStr);
            return newDateTimeInstance(dateValue, timeInt, timezoneSidId);
        }
        return NULL;
    }

    public static Boolean isSameDate(DateTime dtime1, DateTime dtime2, String timezoneSidId) {
        Boolean result = false;
        if (dtime1 != null && dtime2 != null && String.isNotBlank(timezoneSidId)) {
            result = (getDate(dtime1, timezoneSidId) == getDate(dtime2, timezoneSidId));
        }
        return result;
    }

    public static List<String> convertDatesToIsoStrings(List<Date> inputDates, String timezoneSidId) {
        List<String> results = new List<String>();
        for (Date inputDate : inputDates) {
            String dateIso = getStartOfDate(inputDate, timezoneSidId).format(DATE_YMD_FORMAT, timezoneSidId);
            results.add(dateIso);
        }
        return results;
    }

    public static List<Date> convertIsoStringsToDates(List<String> inputDateIsos) {
        List<Date> results = new List<Date>();
        for (String inputDateIso : inputDateIsos) {
            Date dateValue = getDateFromIsoString(inputDateIso);
            results.add(dateValue);
        }
        return results;
    }

    public static integer getTimeNumber(DateTime input, String timezoneSidId) {
        Integer intTime = Integer.valueOf(input.format('Hmm', timezoneSidId));
        if (intTime > 2400) {
            intTime -= 2400;
        }
        return intTime;
    }
}
