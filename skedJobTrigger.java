trigger skedJobTrigger on sked__Job__c (after insert,after update) {
    try {
        if (trigger.isAfter) {
            if (trigger.isInsert) skedJobTriggerHandler.onAfterInsert(trigger.new);
            if (trigger.isUpdate) skedJobTriggerHandler.onAfterUpdate(trigger.new, trigger.oldMap);
        }
    } catch(DmlException e) {
        System.debug('The following exception has occurred: ' + e.getMessage());
    }
}