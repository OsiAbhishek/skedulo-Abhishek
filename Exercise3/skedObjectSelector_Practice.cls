@isTest
private class skedObjectSelector_Practice {
    @isTest
    static void practiceObjectSelector() {
        String brisbaneTimezone = 'Australia/Brisbane';
        Set<Id> resourceIds = new Set<Id>();
        
        DateTime currentTime = DateTime.now();
        DateTime next7DaysTime = currentTime.addDays(7);
        
        Integer duration = 60;
        DateTime start = DateTime.now();
        DateTime finish = start.addMinutes(duration);
        
        
        // Data set up
        
        sked__region__c region = new sked__region__c(
            Name = 'Sydney',
            sked__Timezone__c = 'brisbaneTimezone',
            sked__Country_Code__c = 'AU'
        );
        insert region;
        
        Account acc = new Account(
            Name = 'Test',
            BillingCity = 'Minnetonka',
            BillingCountry = 'US',
            BillingPostalCode = '55343',
            BillingState = 'OR',
            BillingStreet = '5995 Opus Parkway',
            Phone = '(716) 219-2400'
        );
        insert acc;
        sked__job__c job = new sked__job__c(
            sked__type__c = 'Initial Nursing Visit',
            sked__start__c = start,
            sked__finish__c = finish,
            sked__region__c = region.id,
            sked__Duration__c = duration,
            sked__job_status__c = 'In Progress',
            sked__account__c = acc.id
        );
        insert job;
        sked__Resource__c resource = new sked__Resource__c(
            name 					= 'Test',
            sked__Resource_Type__c 	= 'Person',
            sked__Primary_Region__c = region.Id,
            sked__Category__c 		= 'Customer Service',
            sked__Country_Code__c 	= 'AU',
            sked__Is_Active__c      = True,
            sked__Home_Address__c 	= '24 Tuckett Rd, Salisbury, Queensland, AUS'
        );
        sked__Resource__c notRelevantResource = resource.clone();
        insert new List<sked__Resource__c>{resource, notRelevantResource};
            resourceIds.add(resource.Id);
        
        // Create first activity in the past
        sked__Activity__c firstActivity = new sked__Activity__c(
            sked__Address__c 	= '28 Tuckett Rd, Salisbury, Queensland, AUS',
            sked__Type__c 		= 'Meal Break',
            sked__Start__c 		= currentTime.addDays(-7),
            sked__End__c 		= currentTime.addDays(-7).addMinutes(120),
            sked__Resource__c 	= resource.Id
        );
        insert new List<sked__Activity__c>{firstActivity};
            
            sked__job_allocation__c joballocation = new sked__job_allocation__c(
                sked__job__c = job.id,
                sked__resource__c = resource.id,
                sked__status__c = 'In Progress'
            );
        insert joballocation;
        // sub query for the sked__Activities__c list based on the record ID
        List<sked__Resource__c> resourceActivityList = [SELECT id, (SELECT id
                                                                    FROM sked__Activities__r) FROM sked__Resource__c 
                                                        WHERE Id IN :resourceIds AND sked__Is_Active__c = true];
        Test.startTest();
        // Init new selector
        skedObjectSelector resourceSelector = skedObjectSelector.newInstance(sked__Resource__c.SObjectType);
        //-----------------------Add the code below this line-----------------------
        //A sample resources query
        List<sked__Resource__c> resources = Database.query(
            skedObjectSelector.newInstance(sked__Resource__c.SObjectType) //Get an instance of skedObjectSelector for Resource object
            .filter('sked__Is_Active__c = true') //Retrieves active resources
            .filter('Id IN :resourceIds') //Another filter condition
            .subQuery('sked__Job_Allocations__r') //Returns an instance of skedObjectSelector for Job Allocation object
            .filter('sked__Job__r.sked__Start__c =: start') //First filter of the subquery 
            .filter('sked__Job__r.sked__Finish__c =:finish') //Second filter of the subquery
            .filterLogic('{0} OR {1}') //Defines filter logic of the subquery - using OR instead of AND (default)
            .sort('Name') //Firstly, sorting by Name in ascending order
            .sort('sked__Job__r.sked__Start__c DESC') //Secondly, sorting by Job's Start in descending order */
            .parent //Back to the main query
            .parentQuery('sked__Primary_Region__c') //Queries all fields of related Region defined in the field mapping
            .size(10) //Only retrieves 10 records
            .getQuery() //Generates dynamic SOQL query 
        );
        
        System.debug('resources--->'+resources.size());
        
        Test.stopTest();
        
        System.assertEquals(1, resources.size());
        System.assertEquals(region.name, resources[0].sked__Primary_Region__r.Name);
        System.assertEquals(region.sked__Timezone__c, resources[0].sked__Primary_Region__r.sked__Timezone__c);
        System.assertEquals(1, resourceActivityList[0].sked__Activities__r.size());
    }
}
