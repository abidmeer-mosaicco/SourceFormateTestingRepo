/**
* @description       : System Utility Methods For Digital Hub
* @author            : siddharth.pradhan@mosaicco.com | Digital Hub
* @group             : 
* @last modified on  : 02-27-2024
* @last modified by  : Mosaic Direct | Dev Team
**/
public without sharing class PMC_DH_CommonSystemUtils {
    public static final String BASE64MAP = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    
    /**
* @description this utility provides the profile names and their correspoinding Ids (This is Only applicable for External Profiles)
* @author siddharth.pradhan@mosaicco.com | Digital Hub | 06-17-2023 
* @param searchTerm 
* @return Map<String, Id> 
* @example Digital Hub Super Buyer ==> ProfileId
**/
    
    public static Map<String,Id> getExternalProfileIds(String searchTerm) {
        
        // instanitate map with String and Id as parameters
        Map<String, Id> mapExternalProfileIds = new Map<String, Id>();
        // Apex PMD doesn't recognise SYSTEM_MODE or USER_MODE at this point 
        List<Profile> lstProfiles = [SELECT id,name from profile where name like '%Digital Hub%' AND UserType='PowerPartner' WITH SYSTEM_MODE];
        if (!lstProfiles.isEmpty()) {
            for (Profile prof : lstProfiles) {
                mapExternalProfileIds.put(prof.Name,prof.Id);
            }  
        }
        return mapExternalProfileIds;
    }
    /*************************************************************************
* @method Name  : getUserRegion
* @description  : Method to get User Region
* @param       	strUserCountry 
* @return       : String
*****************************************************************************/
    public static String getUserRegion(String strUserCountry){
        Map<String,Set<String>> mapUserRegion =new Map<String,Set<String>>();
        Set<STRING> setUS=new set<string>{'North America','Canada','United States'};
            set<String> setBR=new set<String>{'Brazil'};
                
                mapUserRegion.put('NA',setUS );
        mapUserRegion.put('BR',setBR );
        String strRegion='';
        for(String str:mapUserRegion.keySet()){
            
            if(mapUserRegion.get(str).contains(strUserCountry)){
                strRegion=str; 
            }
        }
        return strRegion;
    }
    
    
    /**
* @description 
* @author  | Digital Hub | 09-21-2023 
* @param dependentField 
* @return Map<String, List<String>> 
**/
    public static Map<String,List<Schema.PicklistEntry>> getDependentPicklistValues(Schema.sObjectField dependentField){
        Map<String,List<Schema.PicklistEntry>> dependentPicklistValues = new Map<String,List<Schema.PicklistEntry>>();
        Schema.DescribeFieldResult dependentFieldResult = dependentField.getDescribe();
        Schema.sObjectField controllerField = dependentFieldResult.getController();
        if(controllerField == null){
            return null;
        } 
        Schema.DescribeFieldResult controllerFieldResult = controllerField.getDescribe();
        List<Schema.PicklistEntry> controllerValues = (controllerFieldResult.getType() == Schema.DisplayType.Boolean ? null : controllerFieldResult.getPicklistValues());
        
        
        for (Schema.PicklistEntry entry : dependentFieldResult.getPicklistValues()){
            if (entry.isActive() && String.isNotEmpty(String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')))){
                getPicklistValues(controllerValues,dependentPicklistValues,entry);
            }
        }
        
        return dependentPicklistValues;
    }
    
    /**
* @description method to fetch reasons list
* @return Map<String,List<String>>
* @param controllerValues
* @param dependentPicklistValues
* @param entry
*/
    private static Map<String,List<Schema.PicklistEntry>> getPicklistValues(List<Schema.PicklistEntry> controllerValues,Map<String,List<Schema.PicklistEntry>> dependentPicklistValues,Schema.PicklistEntry entry){
        List<String> base64chars = String.valueOf(((Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
        for (Integer i = 0; i < controllerValues.size(); i++) {
            Object controllerValue = (controllerValues == null ? (Object) (i == 1) : (Object) (controllerValues.get(i).isActive() ? controllerValues.get(i).getLabel() : null));
            
            Integer bitIndex = i / 6;
            Integer bitShift = 5 - Math.mod(i, 6);
            
            if (controllerValue == null || (BASE64MAP.indexOf(base64chars.get(bitIndex)) & (1 << bitShift)) == 0) {
                continue;
            }
            
            String controllerValueString = String.valueOf(controllerValue);
            
            if (!dependentPicklistValues.containsKey(controllerValueString)) {
                dependentPicklistValues.put(controllerValueString, new List<Schema.PicklistEntry>());
            }
            
            dependentPicklistValues.get(controllerValueString).add(entry);
        }
        return dependentPicklistValues;
    }

    /**
* @method Name getTranslatedValForPicklist
* @description Method to Get Translated label from the selected picklist value
* @param fieldResult Schema.DescribeFieldResult
* @param selectedVal String
* @return String
* @author Manisha Singh
* @date 2024-05-20
 */
public static String getTranslatedValForPicklist(Schema.DescribeFieldResult fieldResult,String selectedVal) {
    List<PMC_DH_PicklistWrapper> lstPickList = PMC_DH_DigitalHubB2BUtils.getPicklistFromSchema(fieldResult);
    for(PMC_DH_PicklistWrapper wrap : lstPickList) {
        if(wrap.value == selectedVal) {
            return wrap.label;
        }
    }
    return '';
}

      /**
      * @description 
      * @author Mosaic Direct | Dev Team | 02-27-2024 
      * @param strDeveloperName 
      * @return List<String> 
      **/
      public static List<String> getListStoreConfigbyFeature(String strDeveloperName) {
        PMC_DH_Store_Configuration__mdt strFieldAPINames=PMC_DH_Store_Configuration__mdt.getInstance(strDeveloperName);
        return strFieldAPINames.PMC_DH_FieldsAPIName__c.split(',');
        
      }
}