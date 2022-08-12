@RestResource(urlMapping='/Skedulo/AvailableResource/*')
global with sharing class skedRestAvailableResource {
    public static string regionId { get; set; }
    public static string homeId { get; set; }
    public static string suiteId { get; set; }
    public static string roomId { get; set; }
    public static string timezone { get; set; }
    public static String startDate { get; set; }
    public static Integer intStartTime { get; set; }
    public static Integer intEndTime { get; set; }
    public static String endDate { get; set; }
    public static Decimal latitude { get; set; }
    public static Decimal longitude { get; set; }
    public static List<Id> tagIds { get; set; }
    public static List<Id> eventIds { get; set; }
    public static Boolean includeResourceInfo { get; set; }
    public static Integer offsetTime { get; set; }
    public static List<Account> accountList { get; set; }
    public static Integer duration = 60; // as the Duration has to set the duration between the start time and end time(1 hour)
    public static sked__Tag__c tagResult { get; set; }
    
    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        String uri = req.requestURI;
        String reqBody = req.requestBody.toString();
        Integer resStatusCode = res.statusCode; 
        Boolean success = TRUE;
        
        Map<String, Object> body = new Map<String, Object>();
        body = (Map<String, Object>)JSON.deserializeUntyped(reqBody);
        
        //Initialize response object
        resp resp = new resp();
        err errors = new err();
        
        skedJobSchedulingModel.Criteria criteria=new skedJobSchedulingModel.Criteria();
        criteria.regionId = (String)body.get('regionId');
        criteria.homeId = (String)body.get('homeId');
        criteria.suiteId = (String)body.get('suiteId');
        criteria.roomId = (String)body.get('roomId');
        criteria.timezone = (String)body.get('timezone');
        criteria.startDate = (String)body.get('startDate');
        criteria.duration = (Integer)body.get('duration');
        criteria.intStartTime = (Integer)body.get('intStartTime');
        criteria.intEndTime = (Integer)body.get('intEndTime');
        criteria.endDate = (String)body.get('endDate');
        criteria.latitude = (Decimal)body.get('latitude');
        criteria.longitude = (Decimal)body.get('longitude');
        criteria.tagIds = (List<Id>)body.get('tagIds');
        criteria.eventIds = (List<Id>)body.get('eventIds');
        criteria.includeResourceInfo = (Boolean)body.get('includeResourceInfo');
        criteria.offsetTime = (Integer)body.get('offsetTime');
        
        if (string.isBlank(regionId) == NULL) {
            errors.message = 'Missing regionId parameter.';
            errors.type = 'Bad Request';
            errors.code = '400';
            success = FALSE;
        }
        else if (string.isBlank(timezone) == NULL) {
            errors.message = 'Missing TimeZone.';
            errors.type = 'Bad Request';
            errors.code = '400';
            success = FALSE;
        }
        
        if (success == TRUE) {    
            try{
                skedJobSchedulingCtrlHandler sked = new skedJobSchedulingCtrlHandler();
                sked.getAvailableResources(criteria);
            } catch (Exception e) {
                errors.message = 'Error found on API execution ' + e.getMessage();
                errors.type = 'Server Error';
                errors.code = '500';            
                success = FALSE;
            }
        }        
        //Finalize the response object
        if (success) {
            res.statusCode = 200;
        } else {
            resp.error = errors;        
            res.responseBody = Blob.valueOf(JSON.serialize(resp));    
            res.statusCode = Integer.valueOf(errors.code);
        }          
    }
    
    //Main class response
    public class resp {
        public err error { get; set; }                       
    }
    
    //sub class response
    public class err {
        public String message { get; set; }
        public String type { get; set; }
        public String code { get; set; }        
        public String trace_id { get; set; }        
    }   
    
}
