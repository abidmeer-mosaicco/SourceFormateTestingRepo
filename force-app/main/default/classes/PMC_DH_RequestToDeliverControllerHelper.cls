/** 
* @description Helper Class for Controller PMC_DH_RequestToDeliverController
* @author Mosaic Direct Dev
* Created On       :2023-Nov-22
**/
public without sharing class PMC_DH_RequestToDeliverControllerHelper {

    /**
    * @method Name  : getUniqueProtocolNumber
    * @description : Method to get Unique Protocol Numbers
    * @param setRandomNumber
    * @return Set<String>
    **/
    public static Set<String> getUniqueProtocolNumber(Set<String> setRandomNumber) {
        List<CartItem> lstCartItems = [SELECT Id, PMC_DH_ProtocolNumber__c FROM CartItem  where PMC_DH_ProtocolNumber__c in :setRandomNumber WITH SECURITY_ENFORCED] ;
        for(CartItem ci:lstCartItems) {
            if(setRandomNumber.contains(ci.PMC_DH_ProtocolNumber__c)){
                setRandomNumber.remove(ci.PMC_DH_ProtocolNumber__c);
            }
        }
        return setRandomNumber;
    }

    /*************************************************************************
* @method Name  : getProtocolNumbers
* @description : Method to get Protocol Numbers
* @param setKeys
* @param index
* @return map<String, String>
*****************************************************************************/    
    public static map<String, String> getProtocolNumbers(Set<String> setKeys,Integer index){
        set<String> setRandomNumbers = new Set<String>();
        Set<String> uniqueProtoNumbers = new Set<String>();
        List<String> lstRandomNumbers = new List<String>();
        map<String, String> mapSKUShipToProtocolNo = new Map<String, String>();  
        Integer intTotalUniqCartItems = setKeys.size();
        while(uniqueProtoNumbers.size() < intTotalUniqCartItems) {
            setRandomNumbers.clear();
            while(setRandomNumbers.size() < (intTotalUniqCartItems-uniqueProtoNumbers.size())){
                String strRandomKey = 'M' + generateRandomNumber();
                strRandomKey  = strRandomKey.toUpperCase();
                setRandomNumbers.add(strRandomKey);
            }
            uniqueProtoNumbers.addAll(getUniqueProtocolNumber(setRandomNumbers));
        }
        lstRandomNumbers = new List<String>(setRandomNumbers);  
        for(String strKey :setKeys) {
            mapSKUShipToProtocolNo.put(strKey,lstRandomNumbers.get(index));
            index++;
        }
        return mapSKUShipToProtocolNo;
    }
    
    /*************************************************************************
* @method Name  : generateRandomNumber
* @description : Method to generate Random Number
* @return string
*****************************************************************************/    
    public static string generateRandomNumber(){
        Blob blobKey = crypto.generateAesKey(128);
        String key = EncodingUtil.convertToHex(blobKey);
        return key.substring(0,9);
    }    
    /**
* @description createProtocolNumber-for stamping protocol number
* @author Hemant Giri Goswami | hegoswami@deloitte.com | 12-16-2023 
* @param lstCartitems 
**/
    public static void createProtocolNumber(List<CartItem> lstCartitems)
    {   
        Integer index=0;
        Set<String> setKeys = new Set<String>();
        for(CartItem cartI:lstCartitems)
        {
            String strKey = cartI.Product2Id + '' + cartI.PMC_DH_ShipTo__c;
            if(!setKeys.contains(strKey)){
                setKeys.add(strKey);
            }
        }
        map<String, String> mapSKUShipToProtocolNo = getProtocolNumbers(setKeys,index);
        for(CartItem cartI:lstCartitems)
        {
            String strKey = cartI.Product2Id + '' + cartI.PMC_DH_ShipTo__c;
            cartI.PMC_DH_ProtocolNumber__c = mapSKUShipToProtocolNo.get(strKey);
        }
        if(!lstCartitems.isEmpty() && Schema.sObjectType.CartItem.isUpdateable()){
            Update lstCartitems;
        }     
    }
    
    //added to resolve cyc. complexity in PMC_DH_RequestToDeliverController
    /*************************************************************************
* @method Name  : generateProtocolNumber
* @description  : Method to generate protocol number
* @param    lstCartitems
* @param    lstCartWrapper
*****************************************************************************/    
    public static void generateProtocolNumber(List<CartItem> lstCartitems, List<PMC_DH_RequestToDeliverWrapper.CartWrapper> lstCartWrapper){
        if(!lstCartWrapper.isEmpty() && lstCartWrapper[0].boolThirdParty==true) {
            createProtocolNumber(lstCartitems);
        }
    }


    
}