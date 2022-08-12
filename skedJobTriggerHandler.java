public class skedJobTriggerHandler {
    
    public static void onAfterInsert(List<sked__job__c> jobList) {
        sendJobCompletionSMS(jobList, null);
    }
    
    public static void onAfterUpdate(List<sked__job__c> jobList, Map<id, sked__job__c> map_id_old) {
        sendJobCompletionSMS(jobList,map_id_old);
    } 
    
    public static void sendJobCompletionSMS(List<sked__job__c> jobList, Map<id, sked__job__c> map_id_old) {
        Set<Id> conIds = new Set<Id>();
        for (sked__Job__c job : jobList) {
            if (map_id_old != null) {
                if (job.sked__Job_Status__c != map_id_old.get(job.Id).sked__Job_Status__c && job.sked__Job_Status__c == 'Complete' && !String.isBlank(job.sked__Contact__c)) {
                    conIds.add(job.sked__Contact__c);
                }
            } else if (job.sked__Job_Status__c == 'Complete' && !String.isBlank(job.sked__Contact__c)) {
                conIds.add(job.sked__Contact__c);
            }
        }
        onCalloutResponse(conIds);
    }
    
    @future (callout=true) 
    public static void onCalloutResponse(Set<Id> conIds) {
        
        try {
            List<Contact> conDetailList = [SELECT id, Phone,LastName FROM Contact WHERE Id IN : conIds LIMIT 1];
            if (conDetailList.size() > 0) {
                String phone = conDetailList[0].Phone;
                String countryCode = 'IN';
                String message = 'Working on the exercise 2.1';
                sked.ApiResult.Sms response = sked.SkeduloAPI.sms(phone, countryCode, message);
                if (response.isSuccess()) {
                    System.debug('Message sent--->'+response); 
                } else {
                    System.debug('Error: ' + response.getError());
                } 
            }
        } catch(Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        
    }
}