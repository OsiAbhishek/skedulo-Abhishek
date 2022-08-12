global virtual class skedResourceAvailabilityBase {

    public Map<Id, resourceModel> initializeResourceList(Set<Id> resourceIds, DateTime startTime, DateTime endTime, string timezoneSidId, Set<Id> homeIds) {
        DateTime firstDateStart = skedDateTimeUtils.GetStartOfDate(startTime, timezoneSidId);
        DateTime lastDateEnd = skedDateTimeUtils.GetEndOfDate(endTime, timezoneSidId);
        Date firstDate = skedDateTimeUtils.getDate(startTime, timezoneSidId);
        Date lastDate = skedDateTimeUtils.getDate(endTime, timezoneSidId);
        Map<Id, sked__Resource__c> mapSkedResource = getResourceWithAvailabilities(resourceIds, firstDateStart, lastDateEnd);

        Map<Id, resourceModel> mapResource = new Map<Id, resourceModel>();
        for (sked__Resource__c skedResource : mapSkedResource.values()) {
            resourceModel resource = new resourceModel(skedResource);
            resource.loadResourceTags(skedResource.sked__ResourceTags__r);
            resource.mapDateslot = new Map<string, dateslotModel>();

            DateTime tempDt = firstDateStart;
            while (tempDt < lastDateEnd) {
                dateslotModel dateslot = new dateslotModel();
                dateslot.stringValue = tempDt.format(skedDateTimeUtils.DATE_FORMAT, timezoneSidId);
                dateslot.dateValue = skedDateTimeUtils.getDate(tempDt, timezoneSidId);
                dateslot.weekday = tempDt.format('EEE', timezoneSidId).toUpperCase();
                dateslot.start = tempDt;
                dateslot.finish = skedDateTimeUtils.addDays(dateslot.start, 1, timezoneSidId);
                dateslot.addEvent(dateslot.start, dateslot.finish, 'non-working', false);

                resource.mapDateslot.put(dateslot.stringValue, dateslot);
                tempDt = skedDateTimeUtils.addDays(tempDt, 1, timezoneSidId);
            }
            mapResource.put(resource.Id, resource);
        }

        loadWorkingTime(mapResource, resourceIds, timezoneSidId);


        for (sked__Resource__c skedResource : mapSkedResource.values()) {
			Set<Date> attachedDays = new Set<Date>();
            resourceModel resource = mapResource.get(skedResource.Id);
            loadResourceEvents(skedResource, resource, timezoneSidId, attachedDays);

        }
        return mapResource;
    }

    /**********************************************************Private methods********************************************************************/
    private void loadWorkingTime(Map<Id, resourceModel> mapResource, Set<Id> resourceIds, string timezoneSidId) {
        DateTime currentTime = system.now();

        List<sked__Availability_Template_Resource__c> templateResourceList = [SELECT sked__Resource__c, sked__Availability_Template__c
                                                                              FROM sked__Availability_Template_Resource__c
                                                                              WHERE sked__Resource__c IN :resourceIds];

        Map<Id, Id> map_ResourceId_TemplateId = new Map<Id, Id>();
        for (sked__Availability_Template_Resource__c atr : templateResourceList) {
            map_ResourceId_TemplateId.put(atr.sked__Resource__c, atr.sked__Availability_Template__c);
        }

        Map<Id, sked__Availability_Template__c> mapTemplate
            = new Map<Id, sked__Availability_Template__c>([SELECT Id,
                                                           (SELECT Id, sked__Finish_Time__c, sked__Is_Available__c, sked__Start_Time__c, sked__Weekday__c
                                                            FROM sked__Availability_Template_Entries__r
                                                            WHERE sked__Is_Available__c = true)
                                                           FROM sked__Availability_Template__c
                                                           WHERE Id IN :map_ResourceId_TemplateId.values()]);

        Map<string, Set<Date>> mapHolidays = skedUtils.getMapHolidays();

        for (ResourceModel resource : mapResource.values()) {
            Set<Date> allHolidays = new Set<Date>();
            if (mapHolidays.containsKey(skedConstants.HOLIDAY_GLOBAL)) {
                Set<Date> globalHolidays = mapHolidays.get(skedConstants.HOLIDAY_GLOBAL);
                allHolidays.addAll(globalHolidays);
            }
            if (mapHolidays.containsKey(resource.RegionId)) {
                Set<Date> regionHolidays = mapHolidays.get(resource.RegionId);
                allHolidays.addAll(regionHolidays);
            }

            Id templateId = map_ResourceId_TemplateId.get(resource.Id);
            if (templateId == NULL) {
                continue;
            }
            sked__Availability_Template__c avaiTemplate = mapTemplate.get(templateId);

            Map<string, sked__Availability_Template_Entry__c> mapEntry = new Map<string, sked__Availability_Template_Entry__c>();
            for (sked__Availability_Template_Entry__c entry : avaiTemplate.sked__Availability_Template_Entries__r) {
                mapEntry.put(entry.sked__Weekday__c, entry);
            }

            for (dateslotModel dateslot : resource.mapDateslot.values()) {
                if (!mapEntry.containsKey(dateslot.weekday)) {
                    continue;
                }

                sked__Availability_Template_Entry__c entry = mapEntry.get(dateslot.Weekday);
                integer startWorkingInMinutes = integer.valueOf(integer.valueOf(entry.sked__Start_Time__c) / 100) * 60 + Math.mod(integer.valueOf(entry.sked__Start_Time__c), 100);
                integer endWorkingInMinutes = integer.valueOf(integer.valueOf(entry.sked__Finish_Time__c) / 100) * 60 + Math.mod(integer.valueOf(entry.sked__Finish_Time__c), 100);

                DateTime startWorkingTime = skedDateTimeUtils.addMinutes(dateslot.start, startWorkingInMinutes, timezoneSidId);
                DateTime endWorkingTime = skedDateTimeUtils.addMinutes(dateslot.start, endWorkingInMinutes, timezoneSidId);

                if (!allHolidays.contains(dateslot.dateValue)) {
                    if (currentTime < endWorkingTime) {
                        dateslot.AddEvent(startWorkingTime, endWorkingTime, null, true);
                        if (startWorkingTime < currentTime) {
                            dateslot.AddEvent(startWorkingTime, currentTime, 'uneditable', false);
                        }
                    }
                }
            }
        }
    }

    private void loadResourceEvents(sked__Resource__c skedResource, resourceModel resource, string timezoneSidId,
                                    Set<Date> attachedDays) {

        for (sked__Availability__c availableBlock : skedResource.sked__Availabilities1__r) {
            if (availableBlock.sked__Is_Available__c != TRUE) {
                continue;
            }
            DateTime availableStart = availableBlock.sked__Start__c;
            DateTime availableEnd = availableBlock.sked__Finish__c;
            DateTime currentTime = system.now();

            dateslotModel firstDateSlot = resource.mapDateslot.values().get(0);
            if (availableStart < firstDateSlot.start) {
                availableStart = firstDateSlot.start;
            }
            dateslotModel lastDateSlot = resource.mapDateslot.values().get(resource.mapDateslot.values().size() - 1);
            if (availableEnd > lastDateSlot.finish) {
                availableEnd = lastDateSlot.finish;
            }

            for (dateslotModel dateslot : resource.mapDateslot.values()) {
                if (dateslot.finish <= availableStart || dateslot.start >= availableEnd) {
                    continue;
                }
                else {
                    DateTime tempStart = availableStart < dateslot.start ? dateslot.start : availableStart;
                    DateTime tempEnd = availableEnd > dateslot.finish ? dateslot.finish : availableEnd;
                    if (currentTime < tempEnd) {
                        dateslot.AddEvent(tempStart, tempEnd, null, true);
                        if (tempStart < currentTime) {
                            dateslot.AddEvent(tempStart, currentTime, 'uneditable', false);
                        }
                    }
                }
            }
        }

        Integer END_OF_DAY = 2400;

        for (sked__Availability__c unavailableBlock : skedResource.sked__Availabilities1__r) {
            if (unavailableBlock.sked__Is_Available__c != FALSE) {
                continue;
            }
            DateTime unavailableStart = unavailableBlock.sked__Start__c;
            DateTime unavailableEnd = unavailableBlock.sked__Finish__c;

            for (dateslotModel dateslot : resource.mapDateslot.values()) {
                if (dateslot.finish <= unavailableStart || dateslot.start >= unavailableEnd) {
                    continue;
                }
                else {
                    DateTime tempStart = unavailableStart < dateslot.start ? dateslot.start : unavailableStart;
                    DateTime tempEnd = unavailableEnd > dateslot.finish ? dateslot.finish : unavailableEnd;
                    skedModels.availability availability = new skedModels.availability(unavailableBlock);
                    dateslot.events.add(availability);
                }
            }
        }

        for (sked__Job_Allocation__c skedAllocation : skedResource.sked__Job_Allocations__r) {
            string allocationDateString = skedAllocation.sked__Job__r.sked__Start__c.format(skedDateTimeUtils.DATE_FORMAT, timezoneSidId);

            if (resource.mapDateslot.containsKey(allocationDateString)) {
                dateslotModel dateslot = resource.mapDateslot.get(allocationDateString);
                skedModels.jobAllocation jobAllocation = new skedModels.jobAllocation(skedAllocation);
                dateslot.events.add(jobAllocation);
            }
        }
        //Resource Shifts
        for (sked__Resource_Shift__c skedResourceShift : skedResource.sked__Resource_Shifts__r) {
            
            DateTime unavailableStart = skedResourceShift.sked__Shift__r.sked__Start__c;
            DateTime unavailableEnd = skedResourceShift.sked__Shift__r.sked__End1__c;

            for (dateslotModel dateslot : resource.mapDateslot.values()) {

                if (dateslot.finish <= unavailableStart || dateslot.start >= unavailableEnd) {
                    continue;
                }
                else {
                    DateTime tempStart = unavailableStart < dateslot.start ? dateslot.start : unavailableStart;
                    DateTime tempEnd = unavailableEnd > dateslot.finish ? dateslot.finish : unavailableEnd;
                    skedModels.resourceShift resourceShift = new skedModels.resourceShift(skedResourceShift);
                    dateslot.events.add(resourceShift);
                
            }
            }
        }

        for (sked__Activity__c skedActivity : skedResource.sked__Activities__r) {
            string activityDateString = skedActivity.sked__Start__c.format(skedDateTimeUtils.DATE_FORMAT, timezoneSidId);
            if (resource.mapDateslot.containsKey(activityDateString)) {
                dateslotModel dateslot = resource.mapDateslot.get(activityDateString);
                skedModels.activity activity = new skedModels.activity(skedActivity);
                dateslot.events.add(activity);
            }
        }

        resource.allEvents = new List<skedBaseModels.event>();
        for (dateslotModel dateslot : resource.mapDateslot.values()) {
            dateslot.events.sort();
            resource.allEvents.addAll(dateslot.events);
        }
        resource.allEvents.sort();
    }

    /**********************************************************Protected methods********************************************************************/
    protected virtual Map<Id, sked__Resource__c> getResourceWithAvailabilities(Set<Id> resourceIds, DateTime startTime, DateTime endTime) {
        System.debug('CHECKSTART'+startTime);
        System.debug('CHECKFinish'+endTime);

        return new Map<Id, sked__Resource__c>([SELECT Id, Name, sked__User__r.SmallPhotoUrl, sked__User__c, sked__Category__c, sked__Home_Address__c,
                                               sked__Primary_Region__r.Name, sked__Primary_Region__c, sked__Primary_Region__r.sked__Timezone__c,
                                               sked__GeoLocation__c, sked__GeoLocation__Latitude__s, sked__GeoLocation__Longitude__s,
                                               sked__Rating__c,

                                               (SELECT Id, sked__Tag__c, sked__Tag__r.Name, sked__Resource__c, sked__Expiry_Date__c
                                                FROM sked__ResourceTags__r),

                                               (SELECT Id, Name, sked__Job__c, sked__Job__r.Name, sked__Job__r.sked__Type__c, sked__Job__r.sked__Start__c,
                                                sked__Job__r.sked__Finish__c, sked__Job__r.sked__Timezone__c, sked__Job__r.sked__GeoLocation__c, sked__Resource__c
                                                FROM sked__Job_Allocations__r
                                                WHERE sked__Status__c NOT IN (:skedConstants.JOB_ALLOCATION_STATUS_DELETED, :skedConstants.JOB_ALLOCATION_STATUS_DECLINED)
                                                AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
                                                AND sked__Job__r.sked__Start__c < :endTime AND sked__Job__r.sked__Finish__c > :startTime
                                                ORDER BY sked__Job__r.sked__Start__c ASC),

                                               (SELECT Id, Name, sked__Start__c, sked__Finish__c, sked__Is_Available__c, sked__Status__c, sked__Timezone__c
                                                FROM sked__Availabilities1__r
                                                WHERE sked__Start__c < :endTime AND sked__Finish__c > :startTime
                                                AND sked__Status__c = :skedConstants.AVAILABILITY_STATUS_APPROVED
                                                ORDER BY sked__Start__c ASC),

                                               (SELECT Id, Name, sked__Start__c, sked__End__c, sked__Address__c, sked__GeoLocation__c, sked__Timezone__c
                                                FROM sked__Activities__r
                                                WHERE sked__Start__c < :endTime AND sked__End__c > :startTime
                                                ORDER BY sked__Start__c ASC),

                                                (SELECT Id, sked__Shift__c, Name, sked__Shift__r.sked__Start__c, sked__Shift__r.sked__End1__c, 
                                                sked__Resource__c, sked__Resource__r.sked__Primary_Region__r.sked__Timezone__c
                                                FROM sked__Resource_Shifts__r  WHERE sked__Shift__r.sked__Start__c < :endTime 
                                                AND sked__Shift__r.sked__End1__c > :startTime
                                                ORDER BY sked__Actual_Start__c ASC)

                                               FROM sked__Resource__c
                                               WHERE Id IN :resourceIds]);
    }

    /**********************************************************Nested classes********************************************************************/
    global class resourceModel extends skedModels.resource {
        public transient Map<string, dateslotModel> mapDateslot {get;set;}
        public transient List<skedBaseModels.event> allEvents {get;set;}

        public resourceModel(sked__Resource__c skedResource) {
            super(skedResource);
            this.mapDateslot = new Map<string, dateslotModel>();
        }
    }

    global class dateslotModel {
        public string stringValue {get;set;}
        public Date dateValue {get;set;}
        public DateTime start {get;set;}
        public DateTime finish {get;set;}
        public string weekday {get;set;}
        public List<skedBaseModels.event> events {get;set;}

        public dateslotModel() {
            this.events = new List<skedBaseModels.event>();
        }

        public skedBaseModels.event addEvent(DateTime startTime, DateTime endTime, string eventType, boolean isAvailable) {
            return addEvent(startTime, endTime, eventType, isAvailable, null);
        }

        public skedBaseModels.event addEvent(DateTime startTime, DateTime endTime, string eventType, boolean isAvailable, string relatedId) {
            if (isAvailable == true) {
                addAvailableBlock(startTime, endTime);
            }
            else {
                skedBaseModels.event newEvent = new skedBaseModels.event();
                newEvent.start = startTime;
                newEvent.finish = endTime;
                newEvent.eventType = eventType;
                this.events.add(newEvent);
                return newEvent;
            }
            return null;
        }

        private void addAvailableBlock(DateTime startTime, DateTime endTime) {
            List<skedBaseModels.event> newEvents = new List<skedBaseModels.event>();
            Set<DateTime> removedEvents = new Set<DateTime>();

            for (skedBaseModels.event eventItem : this.events) {
                if (eventItem.start < startTime && startTime < eventItem.finish) {
                    if (endTime < eventItem.finish) {
                        skedBaseModels.event newEvent = new skedBaseModels.event();
                        newEvent.start = endTime;
                        newEvent.finish = eventItem.finish;
                        newEvent.eventType = eventItem.eventType;
                        newEvents.add(newEvent);
                    }
                    eventItem.finish = startTime;
                }
                else if (startTime <= eventItem.start) {
                    if (endTime >= eventItem.finish) {
                        removedEvents.add(eventItem.start);
                    }
                    else if (eventItem.start < endTime && endTime < eventItem.finish) {
                        eventItem.start = endTime;
                    }
                }
            }

            for (integer i = this.events.size() - 1; i >= 0; i--) {
                skedBaseModels.event eventItem = this.events.get(i);
                if (removedEvents.contains(eventItem.start)) {
                    this.events.remove(i);
                }
            }

            this.events.addAll(newEvents);
        }
    }
}
