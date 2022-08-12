global virtual class skedJobSchedulingModel {
    public class ConfigData {
        public List<skedModels.selectOption> jobTypes;
        public List<skedModels.cancellationOption> cancellationReasons;
        public List<skedBaseModels.region> regions;
        public List<ColorSettingModel> statusColorSettings;
        public List<ColorSettingModel> statusGridColorSettings;
        public String jobURL;
        public Integer defaultDuration;
        public Integer minDuration;
        public Integer intStartTime;
        public Integer intEndTime;
        public Integer stabilizedHomeScheduledTime;
        public Integer specialStabilizedHomeScheduledTime;
        public List<String> specialRegion;

        public ConfigData() {
            skedConfigs__c configs = skedConfigs.getSkedConfigsSettings();
            this.regions = new List<skedBaseModels.region>();

            // Build job Types
            this.jobTypes = skedUtils.getPicklistValues('sked__Job__c', 'sked__Type__c');
            //setDefaultType(this.jobTypes, configs.Default_Job_Type__c);

            // regions
            for (sked__Region__c region : [SELECT Id, Name, sked__Timezone__c FROM sked__Region__c Order By Name ASC]) {
                this.regions.add(new skedBaseModels.region(region));
            }

            Integer stabHomeScheTime = 24;
            Integer chicagoStabHomeScheTime = 48;
            if (configs != null) {
                this.jobURL = configs.Global_Job_URL__c;
                this.defaultDuration = configs.Default_Job_Duration__c == null ? null : (Integer)configs.Default_Job_Duration__c;
                this.minDuration = configs.Minimum_Job_Duration__c == null ? null : (Integer)configs.Minimum_Job_Duration__c;
                this.intStartTime = configs.Start_Working_Time__c == null ? null : (Integer)configs.Start_Working_Time__c;
                this.intEndTime = configs.End_Working_Time__c == null ? null : (Integer)configs.End_Working_Time__c;
                //this.stabilizedHomeScheduledTime = configs.StabilizedHomeScheduledTime__c == null ? stabHomeScheTime : (Integer)configs.StabilizedHomeScheduledTime__c;
                //this.specialStabilizedHomeScheduledTime = configs.ChicagoStabilizedHomeScheduledTime__c == null ? chicagoStabHomeScheTime : (Integer)configs.ChicagoStabilizedHomeScheduledTime__c;
                //this.specialRegion = configs.Schedule_Within_48h_Region__c == null ? null : configs.Schedule_Within_48h_Region__c.split(';');
            }

            this.statusColorSettings = new List<ColorSettingModel>();
            List<skedColorSetting__c> colorSettings = skedColorSetting__c.getall().values();
            for (skedColorSetting__c colorSetting : colorSettings) {
                this.statusColorSettings.add(new ColorSettingModel(colorSetting));
            }

            // Color for Booking Grid
            this.statusGridColorSettings = new List<ColorSettingModel>();
            List<skedGridColorSetting__c> colorGridSettings = skedGridColorSetting__c.getall().values();
            for (skedGridColorSetting__c colorSetting : colorGridSettings) {
                this.statusGridColorSettings.add(new ColorSettingModel(colorSetting));
            }
        }

        private void setDefaultType(List<skedModels.selectOption> types, String defaultType) {
            if (String.isNotBlank(defaultType)) {
                for (skedModels.selectOption t : types) {
                    if (defaultType.equalsIgnoreCase(t.id)) {
                        t.selected = true;
                        break;
                    }
                }
            }
        }
    }

    global class Job extends skedModels.job {
        public skedModels.customLocation jobLocation;
        public integer endTime {get;set;}
        public String description;
        public String dateOfEvent;
        public String tourId;
        public string tourType;
        //COM-83 revert
        public Integer offsetTime;

        public skedBaseModels.region region;
        public skedBaseModels.ObjectModel account;
        public skedBaseModels.ObjectModel contact;
        public skedBaseModels.ObjectModel opportunity;
        public HomeModel home;
        public skedBaseModels.ObjectModel suite;
        public skedBaseModels.ObjectModel room;

        public Job() {

        }

        public Job (sked__Job__c skedJob) {
            super(skedJob);
            this.endTime = this.finishTime;
            //this.offsetTime = skedJob.sked_Off_Set_Time__c == null ? 0 : integer.valueOf(skedJob.sked_Off_Set_Time__c);
            //this.description = skedJob.sked_Custom_Description__c;

            this.jobLocation = new skedModels.customLocation();
            jobLocation.fullAddress = this.address;
            jobLocation.latitude = this.lat;
            jobLocation.longitude = this.lng;

            this.dateOfEvent = skedJob.sked__Start__c.format(skedDateTimeUtils.DATE_ISO_FORMAT, this.timezoneSidId);
            this.region = new skedBaseModels.region(skedJob.sked__Region__r);

            if (skedJob.sked__Account__c != null) {
                this.account = new skedBaseModels.ObjectModel(skedJob.sked__Account__r);
            }

            if (skedJob.sked__Contact__c != null) {
                this.contact = new skedBaseModels.ObjectModel(skedJob.sked__Contact__r);
            }

            if (skedJob.sked__Job_Allocations__r != null && !skedJob.sked__Job_Allocations__r.isEmpty()) {
                loadJobAllocations(skedJob.sked__Job_Allocations__r);
            }
        }

        public sked__Job__c getSkedJob() {
            DateTime startOfDay = skedDateTimeUtils.getStartOfDate(this.dateOfEvent, this.region.timezoneSidId);
            Integer startHourInMinutes = skedDateTimeUtils.ConvertTimeNumberToMinutes(this.startTime);
            DateTime dtStartTime = skedDateTimeUtils.addMinutes(startOfDay, startHourInMinutes, this.region.timezoneSidId);
            DateTime dtEndTime = skedDateTimeUtils.addMinutes(dtStartTime, this.duration, this.region.timezoneSidId);

            sked__Job__c skedJob = new sked__Job__c(
                sked__Type__c = this.jobType,
                sked__GeoLocation__latitude__s = this.jobLocation.latitude,
                sked__GeoLocation__longitude__s = this.jobLocation.longitude,
                sked__Address__c = this.jobLocation.fullAddress,
                sked__Region__c = this.region.Id,
                sked__Account__c = this.account == null ? null : this.account.Id,
                sked__Contact__c = this.contact == null ? null : this.contact.Id,
                sked__Start__c = dtStartTime,
                sked__Finish__c = dtEndTime,
                sked__Duration__c = this.duration,
                sked__Can_Be_Declined__c = false
            );

            return skedJob;
        }

        public void loadJobAllocations(List<sked__Job_Allocation__c> jobAllocations) {
            this.allocations = new List<skedModels.jobAllocation>();
            skedModels.jobAllocation jobAll;
            for (sked__Job_Allocation__c ja : jobAllocations) {
                jobAll = new skedModels.jobAllocation();
                jobAll.Id = ja.Id;
                jobAll.Name = ja.Name;
                jobAll.status = ja.sked__Status__c;

                skedModels.resource resource = new skedModels.resource();
                resource.Id = ja.sked__Resource__c;
                resource.Name = ja.sked__Resource__r.Name;
                if (ja.sked__Resource__r.sked__User__c != null) {
                    resource.photoUrl = ja.sked__Resource__r.sked__User__r.SmallPhotoUrl;
                }
                jobAll.resource = resource;

                this.allocations.add(jobAll);
            }
        }
    }

    /**
    *@description Model for filtering available resources
    *
    */
    global class Criteria {
        public string regionId;
        public string homeId;
        public string suiteId;
        public string roomId;
        public string timezone;
        public String startDate;
        public Integer duration;
        public Integer intStartTime;
        public Integer intEndTime;
        public String endDate;
        public Decimal latitude;
        public Decimal longitude;
        public List<Id> tagIds;
        public List<Id> eventIds;
        public Boolean includeResourceInfo;
        public Integer offsetTime;

        public Criteria() {}
    }

    public class SuggestedAddressModel {
        public String fullAddress;
        public String placeId;

        public SuggestedAddressModel(String fullAddress, String placeId) {
            this.fullAddress = fullAddress;
            this.placeId = placeId;
        }
    }

    public class OpportunityModel extends skedBaseModels.ObjectModel {
        public skedBaseModels.ObjectModel account;
        public skedBaseModels.ObjectModel contact;
        public skedBaseModels.ObjectModel region;


        public OpportunityModel(Opportunity opp) {
            super(opp);
            if (String.isNotBlank(opp.AccountId)) {
                this.account = new skedBaseModels.ObjectModel(opp.AccountId, opp.Account.Name);
            }

            if (String.isNotBlank(opp.sked_Region__c)) {
                this.region = new skedBaseModels.ObjectModel(opp.sked_Region__c, opp.sked_Region__r.Name);
            }
        }
    }

     public class AccountModel extends skedBaseModels.ObjectModel {
        public skedBaseModels.ObjectModel contact;
        public skedBaseModels.region region;
        public skedModels.customLocation jobLocation;

        public AccountModel(Account acc) {
            super(acc);

            if (String.isNotBlank(acc.sked_Region__c)) {
                this.region = new skedBaseModels.region(acc.sked_Region__r);
            }

            if (acc.Contacts != null && !acc.Contacts.isEmpty()) {
				this.contact = new skedBaseModels.ObjectModel(acc.Contacts[0].Id, acc.Contacts[0].Name);
            }
            this.jobLocation = new skedModels.customLocation();
        }
    }

    public class HomeModel extends skedBaseModels.ObjectModel {
        public skedModels.customLocation address;
        public String status;

        public HomeModel(sObject home) {
            super(home);
            address = new skedModels.customLocation();
        }
    }

    public class ColorSettingModel {
        public String id;
        public String backgroundColor;
        public String color;

        public ColorSettingModel(skedColorSetting__c colorSetting) {
            this.id = colorSetting.Name__c;
            this.backgroundColor = colorSetting.Background_Color__c;
            this.color = colorSetting.Color__c;
        }

        public ColorSettingModel(skedGridColorSetting__c colorSetting) {
            this.id = colorSetting.Name__c;
            this.backgroundColor = colorSetting.Background_Color__c;
            this.color = colorSetting.Color__c;
        }
    }
}
