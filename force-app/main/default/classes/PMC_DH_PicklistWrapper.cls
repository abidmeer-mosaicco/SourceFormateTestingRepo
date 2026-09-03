/**
* @description Wrapper class for value label picklist
* @author @rravindraundale 
* @last modified on 05-11-2023
* @last modified by @rravindraundale
**/

public class PMC_DH_PicklistWrapper{
    /**
     * @description Label
     * @return Label value
     */
     @AuraEnabled
    public String label{get;set;}
    /**
     * @description value
     * @return value
     */
     @AuraEnabled
    public String value{get;set;}
}