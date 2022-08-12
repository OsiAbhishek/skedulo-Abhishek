global class skedModels {

    public virtual class job extends skedBaseModels.job {
        public List<job> followups {get;set;}
        public List<jobAllocation> allocations {get;set;}

        public integer noOfQualifiedResources {get;set;}
        public integer noOfAvailableResources {get;set;}

        public job() {}

        public job(sked__Job__c skedJob) {
            super(skedJob);
            this.allocations = new List<jobAllocation>();
            this.followups = new List<job>();
        }
    }

    public virtual class availability extends skedBaseModels.availability {
        public availability(sked__Availability__c skedAvailability) {
            super(skedAvailability);
        }
    }

    public virtual class resourceShift extends skedBaseModels.resourceShift {
        public resourceShift(sked__Resource_Shift__c skedResourceShift) {
            super(skedResourceShift);
        }
    }

    public virtual class activity extends skedBaseModels.activity {
        public activity(sked__Activity__c skedActivity) {
            super(skedActivity);
        }
    }

    public virtual class jobAllocation extends skedBaseModels.jobAllocation {
        public skedBaseModels.geometry startFromLocation {get;set;}
        public decimal distance {get;set;}
        public decimal distanceInMiles {get;set;}
        public integer travelTime {get;set;}
        public boolean isQualified {get;set;}
        public boolean isAvailable {get;set;}
        public string conflictDetails {get;set;}
        public boolean noHomeAddress {get;set;}

        public string action {get;set;}

        public transient job job {get;set;}
        public resource resource {get;set;}

        public transient skedBaseModels.event previousEvent {get;set;}
        public transient skedBaseModels.event nextEvent {get;set;}

        public jobAllocation() {
            this.isQualified = true;
            this.isAvailable = true;
            this.noHomeAddress = false;
        }

        public jobAllocation(sked__Job_Allocation__c skedAllocation) {
            super(skedAllocation);
            this.isQualified = true;
            this.isAvailable = true;
            this.noHomeAddress = false;
        }
    }

    global virtual class resource extends skedBaseModels.resource {
        public resource() {

        }

        public resource(sked__Resource__c skedResource) {
            super(skedResource);
        }
    }

    public virtual class selectOption {
        public string id {get;set;}
        public string label {get;set;}
        public boolean selected {get;set;}

        public selectOption(string value, string text) {
            this.id = value;
            this.label = text;
            this.selected = false;
        }

        public selectOption(string value, string text, boolean selected) {
            this.id = value;
            this.label = text;
            this.selected = selected;
        }
    }

    public virtual class cancellationOption extends selectOption{
        public boolean requireComments {get;set;}

        public cancellationOption(string value, string text) {
            super(value, text);
            this.requireComments = false;
        }
        public cancellationOption(string value, string text, boolean selected) {
            super(value, text, selected);
            this.requireComments = false;
        }
    }

    public virtual class customLocation {
        public String timeZoneId;
        public String timeZoneName;
        public String regionId;
        public String placeId;
        public String city;
        public String state;
        public String zip;
        public String territory;
        public String fullAddress;
        public decimal latitude {get;set;}
        public decimal longitude {get;set;}

        public customLocation() {

        }

        public customLocation(Location loc) {
            this.latitude = loc.getLatitude();
            this.longitude = loc.getLongitude();
        }
    }

    public class DateModel {
        public string dateISO {get;set;}//YYYY-MM-DD
        public string dayOfWeek {get;set;}//SUN -
        public boolean isHoliday {get;set;}
        public List<TimeSlotModel> timeSlots {get;set;}

        public DateModel(){
            this.timeSlots = new List<TimeSlotModel>();
            this.isHoliday = false;
        }
    }

    public class TimeSlotModel {
        public Integer numOfAvailableResources {get;set;}
        public integer startTime {get;set;}
        public integer endTime {get;set;}
        public List<jobAllocation> availableResources {get;set;}
        public Integer totalResources {get;set;}
        public DateTime startTimeValue {get;set;}
        public DateTime endTimeValue {get;set;}
        public string dateISO {get;set;}
        // Decription: has a tour was scheduled on this time slot
        public boolean tourBooked {get;set;}

        public TimeSlotModel() {
            this.numOfAvailableResources = 0;
            this.totalResources = 0;
            this.availableResources = new List<jobAllocation>();
            this.tourBooked = false;
        }
    }

    public class skedCoreException extends System.Exception {

    }
}
