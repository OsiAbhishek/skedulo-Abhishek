/**
 * Providing common database query support
 */
public virtual class skedObjectSelector {

    public String REL_NOT_EXIST      = 'Relationship not exist: {0}';

    //sObjectType of the main object
    public SObjectType objectType;
    //No. of records to be returned
    private Integer limitCount;
    //Set the value for 'OFFSET' clause
    private Integer offset;
    //List of filter conditions in 'WHERE' clause of the SOQL query
    //Joined by AND operator by default if the filter logic is not defined
    //The order of the filters are important if the filterLogic is defined
    private list<String> filters;
    // Defines the logic operators for the filter conditions
    //The number of parameters in the filterLogic must be matching with the number of filter conditions
    //The index is starting from 0
    //Sample value: '( {0} OR {1} AND ({2} OR {3}) ) OR {4}'
    private String filterLogic;
    //Set the values for 'ORDER BY' clause
    private List<String> sortFields;
    //Fields to be queried
    private Set<String> fields;
    //A reference to the parent selector
    public skedObjectSelector parent;
    //Used for subqueries
    private Map<Schema.ChildRelationship, skedObjectSelector> mapChildSelectors;
    //A list of lookup or master-detail fields
    private Set<String> parentFields;

    /**
    * Constructor
    */
    public skedObjectSelector(Schema.sObjectType objectType){
        //Get the field mapping
        Map<Schema.sObjectType,Set<String>> mapObjectType2Fields = getFieldMapping();
        this.objectType     = objectType;
        if(mapObjectType2Fields.containsKey(objectType)){
            fields          = mapObjectType2Fields.get(objectType);
        }else{
            //Set defaul fields if the object is not defined in the field mapping
            //NOTES: this can be a problem if the object has no 'Name' field like ContractLineItem object
            fields          = new Set<String>{'Id'};
        }
        mapChildSelectors   = new Map<Schema.ChildRelationship, skedObjectSelector>();
        filters             = new list<String>();
        sortFields          = new List<String>();
        parentFields        = new Set<String>();
    }

    /**
    * Initializes a new instance
    */
    public static skedObjectSelector newInstance(Schema.sObjectType objectType){
        return new skedObjectSelector(objectType);
    }
    //================== VIRTUAL METHOD ==================
    /**
    * Gets the field mapping for all objects
    * This method can be overridden by a subclass to get the field mapping from another source.
    */
    public virtual Map<Schema.sObjectType,Set<String>> getFieldMapping(){
        return new skedObjectSelectorFieldMapping().mapObjectType2Fields;
    }

    //================== QUERY BUILDING METHODS ==================
    /**
    * Adds a lookup/master-detail field to the list
    * An exception is thrown if the relationship does not exist
    */
    public skedObjectSelector parentQuery(String fieldName){
        parentFields.add(fieldName.toLowerCase());
        return this;
    }

    /**
    * Initializes a new selector for the child object and link it to the main selector.
    * Returns the child selector which can be used to add filters, sorting, etc for the subquery
    */
    public skedObjectSelector subQuery(String relationshipName){
        Schema.ChildRelationship cr = getChildRelationship(relationshipName);
        if(cr == null) return null;
        if(mapChildSelectors.containsKey( cr )){
            return mapChildSelectors.get( cr );
        }
        skedObjectSelector childSelector = new skedObjectSelector( cr.getChildSObject() );
        childSelector.parent = this;
        mapChildSelectors.put( cr, childSelector );
        return childSelector;
    }

    /**
    * Initializes a new selectors for a list of child objects
    * Returns the main selector
    */
    public skedObjectSelector subQueries(List<String> relationshipNames){
        for(String relationshipName : relationshipNames){
            subQuery(relationshipName);
        }
        return this;
    }

    /**
    * Adds a new filter condition which can be one or many expression. For example:
    * selector.filter('BalanceValue__c > 0')
    * selector.filter('BalanceValue__c > 0 and IsActive__c = true')
    */
    public skedObjectSelector filter(String whereClause){
        filters.add( '(' + whereClause + ')');
        return this;
    }

    /**
    * Adds a list of filter conditions
    */
    public skedObjectSelector filters(List<String> whereClauses){
        for(String whereClause : whereClauses){
            filter(whereClause);
        }
        return this;
    }

    /**
    * Sets the number of records to be returned
    */
    public skedObjectSelector size(Integer limitCount){
        this.limitCount = limitCount;
        return this;
    }

    /**
    * Sets the OFFSET
    */
    public skedObjectSelector offset(Integer offset){
        this.offset = offset;
        return this;
    }

    /**
    * Add aa 'ORDER BY' field
    */
    public skedObjectSelector sort(String sortField){
        sortFields.add(sortField);
        return this;
    }

    /**
    * Defines the logic operators for the filter conditions
    * The number of parameters in the filterLogic must be matching with the number of filter conditions
    * The index is starting from 0
    * Sample value: '( {0} OR {1} AND ({2} OR {3}) ) OR {4}'
    */
    public skedObjectSelector filterLogic(String filterLogic){
        this.filterLogic = filterLogic;
        return this;
    }

    /**
    * Adds a new field
    */
    public skedObjectSelector field(String fieldName){
        this.fields.add(fieldName);
        return this;
    }

    /**
    * Adds a new field
    */
    public skedObjectSelector fields(List<String> fieldNames){
        this.fields.addAll(fieldNames);
        return this;
    }

    /**
    * reset default fields
    */
    public skedObjectSelector resetFields(){
        this.fields = new Set<String>();
        return this;
    }

    /**
    * Gets a list of SObject
    */
    public List<sObject> toSObjects(){
        return Database.query( getQuery() );
    }

    /**
    * Gets the dynamic SOQL
    */
    public String getQuery(){
        String mainQuery = getObjectQuery( this, this.objectType.getDescribe().getName() );
        //Sub query
        List<String> subQueries = new List<String>();
        for(Schema.ChildRelationship cr : mapChildSelectors.keySet()){
            skedObjectSelector childSelector = mapChildSelectors.get( cr );
            String subQuery = getObjectQuery(childSelector, cr.getRelationshipName());
            subQueries.add('(' + subQuery + ')');
        }
        if ( !subQueries.isEmpty() )
            mainQuery = mainQuery.replace('FROM', ', ' + String.join( subQueries, ',' ) + ' FROM');

        return mainQuery;
    }

    //================== PRIVATE METHODS ==================
    /**
    * Builds the SOQL query for a single object
    * objectName can be either an Object API name or a relationship name
    */
    private String getObjectQuery(skedObjectSelector selector, String objectName){

        addParentFields( selector );

        String query = 'SELECT {0} FROM {1} ';
        String fieldString = String.join( new List<String>(selector.fields), ',' );
        query = String.format( query, new List<String>{ fieldString, objectName } );

        String whereClause = '';
        if(!selector.filters.isEmpty()){
            if(selector.filters.size()==1){
                whereClause     =  selector.filters.get(0);
            }else{
                if(String.isBlank( selector.filterLogic )){//filterLogic is not defined, default to AND
                    whereClause = String.join( selector.filters, ' AND ' );
                }else{
                    whereClause = String.format( selector.filterLogic, selector.filters );
                }
            }
        }

        if(!String.isBlank(whereClause)) query += ' WHERE ' + whereClause;
        //Sorting
        if(!selector.sortFields.isEmpty()){
            query += ' ORDER BY ' + String.join(selector.sortFields, ',');
        }
        //limit
        if(selector.limitCount != null){
            query += ' LIMIT ' + String.valueOf(selector.limitCount);
        }
        if(selector.offset != null){
            query += ' OFFSET ' + String.valueOf(selector.offset);
        }
        return query;
    }

    /**
    * Remove duplidate fields and adds fields of parent objects to the field list
    */
    private void addParentFields(skedObjectSelector selector){
        //Change fields to lower case to avoid querying duplicate fields
        String fieldNames = String.join(new List<String>(selector.fields),',');
        selector.fields.clear();
        for(String fieldName : fieldNames.split(',')){
            selector.fields.add( fieldName.toLowerCase() );
        }
        //add parent object fields
        Map <String, Schema.SObjectField> fieldMap = selector.objectType.getDescribe().fields.getMap();

        for(String fieldName : selector.parentFields){
            if(!fieldMap.containsKey( fieldName.toLowerCase() )) {
                throw new ObjectSelectorException(String.format(REL_NOT_EXIST, new List<String>{ fieldName }));
            }

            Schema.DescribeFieldResult fieldDescribe = fieldMap.get( fieldName.toLowerCase() ).getDescribe();
            List<Schema.SObjectType> objTypes = fieldDescribe.getReferenceTo();
            if(objTypes == null || objTypes.isEmpty()) continue;

            selector.fields.add( fieldDescribe.getName().toLowerCase() );

            String relationshipName = fieldDescribe.getRelationshipName().toLowerCase();
            skedObjectSelector parentSelector = new skedObjectSelector( objTypes.get(0) );
            for(String f : parentSelector.fields){
                selector.fields.add( relationshipName + '.' + f.toLowerCase() );
            }
        }
    }

    /**
    * Get the ChildRelationship from the Table for the relationship name passed in.
    */
    private Schema.ChildRelationship getChildRelationship(String relationshipName){
        for (Schema.ChildRelationship childRow : objectType.getDescribe().getChildRelationships()){
            if (childRow.getRelationshipName() == relationshipName){
                return childRow;
            }
        }
        throw new ObjectSelectorException( String.format(REL_NOT_EXIST, new List<String>{ relationshipName }) );
    }

    //Custom Exception
    public class ObjectSelectorException extends Exception{}
}
