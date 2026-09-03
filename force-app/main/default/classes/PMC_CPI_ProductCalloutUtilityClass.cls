public with sharing class PMC_CPI_ProductCalloutUtilityClass implements Database.AllowsCallouts {
    
    public static HttpRequest request = new HttpRequest();
    public static String strExceptionMsg; 
	public static String strIndustrySector;
	public static String strProductId;
	public static String strINDUS = '';
	public static String strMSTDV;
	public static String strMATNR = '';
    public static String strPRGRP = '';
    public static String strPRCTR = '';

    /** 
     * @description This method will make a callout to CPI.
     * @param strMethod - Method for external callout. eg. GET, POST, PATCH
     * @param strCalloutEndpoint - Concatenation of named credential and specific endpoint
     * @param strSerializedBody - Product Data.
     * @return response - Http Response.
     * @return null - If no response is returned.
     */    
    public static HttpResponse sendCalloutRequest(String strMethod, String strCalloutEndpoint, String strSerializedBody)
    {
        String strIntegrationSettingsRecord = 'PMC_CPQ_IntegrationAutoRetrySettings';
        Integer intTimeoutValue = Integer.valueOf(PMC_CPQ_IntegrationSettings__mdt.getInstance(strIntegrationSettingsRecord).PMC_CPQ_SettingTwoValueNumber_c__c);
        request = new HttpRequest();
        HttpResponse response;
        Http http = new Http();
        String strContentType = 'Content-Type';
        String strContentTypeValue = 'application/xml;charset=UTF-8';
        try
        {          
            request.setMethod(strMethod);
            request.setHeader(strContentType,strContentTypeValue);
            request.setEndpoint(strCalloutEndpoint);
            request.setBody(strSerializedBody);
            request.setTimeout(intTimeoutValue);
            response = http.send(request); 
            return response;
        }
        catch(Exception objException)
        {
            PMC_ErrorLogClass.processException(objException);
            strExceptionMsg = objException.getMessage();
            return null;
        }
    }

    public static String createProductPayload(ID strProductId) {
        
        try 
        {            
            List<PMC_CPQ_ProductLocation__c> lstProductLocation = [SELECT PMC_CPQ_LocationType__c,
													   PMC_CPQ_Location__c,
													   PMC_CPQ_Location__r.Name, 
													   PMC_CPQ_Location__r.PMC_CPQ_Plant__c,
                                                       PMC_CPQ_Location__r.PMC_CPQ_Country__c,
													   PMC_CPQ_Location__r.PMC_CPQ_SalesOrg__c,
                                                       PMC_CPQ_Location__r.PMC_CPQ_Profit_Center__c,
													   PMC_CPQ_ProductLocationSAPIdentifier__c,
													   PMC_CPQ_ProductName__c, 
													   PMC_CPQ_ProductName__r.Name 
													   FROM PMC_CPQ_ProductLocation__c 
													   WHERE PMC_CPQ_ProductName__c=:strProductId];
            
            Product2 objProduct = [SELECT Name,PMC_CPQ_Basic_Material__c,PMC_CPQ_Basic_Text__c, PMC_CPQ_Basic_Text_ES__c, PMC_CPQ_Control_Code__c,
                                   PMC_CPQ_Date_from__c,PMC_CPQ_External_Material_Group__r.Name,PMC_CPQ_SAPProductCode__c,PMC_CPQ_MaterialGroup__c,
                                   PMC_CPQ_Material_Type__c,PMC_CPQ_Mat_Grp_Packaging_Materials__c,PMC_CPQ_Product_Hierarchy__c,PMC_CPQ_Sales_Org__c,
                                   PMC_CPQ_QuantityUnitOfMeasure__c,PMC_CPQ_Nitrogen__c,PMC_CPQ_Phosphorous__c,PMC_CPQ_Phosphorous_PH2O__c,
                                   PMC_CPQ_Potassium__c,PMC_CPQ_Magnesium__c,PMC_CPQ_Calcium__c,PMC_CPQ_Zinc__c,PMC_CPQ_Copper__c,PMC_CPQ_Sulfur__c,
                                   PMC_CPQ_Planning_Group__c,PMCPlanning_Material__c,PMC_CPQ_Sulfur_SO4__c,PMC_CPQ_Boron__c,PMC_CPQ_Cobalt__c,
                                   PMC_CPQ_Iron__c,PMC_CPQ_Manganese__c,PMC_CPQ_Molybdenum__c,PMC_CPQ_Chlorine__c,PMC_CPQ_Silicone__c,
                                   PMC_CPQ_Registration_in_the_Ministry__c,PMC_CPQ_Period_of_Validity__c,PMC_CPQ_Family_to_O9__c,PMC_CPQ_Group_Name_to_O9__c,
                                   PMC_CPQ_Product_Resource_to_O9__c,PMC_CPQ_Senave__c,PMC_CPQ_Libre_Venta__c,PMC_CPQ_Cross_distribution__c,
                                   Standard_Price__c,Material_Group__c,Material_Usage__c,Material_Origin__c,PMC_CPQ_Produced_In_House__c 
                                   FROM Product2 Where Id=:strProductId];
            
            IF (objProduct.PMC_CPQ_Date_from__c != null) {
                Datetime dtMSTDV = objProduct.PMC_CPQ_Date_from__c;
                strMSTDV = dtMSTDV.format('yyyyMMdd');
            } else {
                strMSTDV = ''; // Default value if date is null
            }

            IF (objProduct.PMC_CPQ_SAPProductCode__c != null) {
                strMATNR = objProduct.PMC_CPQ_SAPProductCode__c;
                strMATNR = strMATNR.leftPad(18,'0'); // Ensure MATNR is 18 characters long
            }

            Datetime dtKeyDate = Datetime.now();
            final String strKeyDate = dtKeyDate.format('yyyyMMdd');

            XMLStreamWriter xmlStreamWriter = new XmlStreamWriter();
            xmlStreamWriter.writeStartElement(null, 'ROOT', null);
            xmlStreamWriter.writeStartElement(null, 'MATMAS05', null);
            xmlStreamWriter.writeStartElement(null, 'IDOC', null);
            xmlStreamWriter.writeStartElement(null, 'E1MARAM', null);
            xmlStreamWriter.writeStartElement(null, 'MATNR', null);
                xmlStreamWriter.writeCharacters(strMATNR);
            xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeStartElement(null, 'MTART', null);
                xmlStreamWriter.writeCharacters(objProduct.PMC_CPQ_Material_Type__c ?? '');
            xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeStartElement(null, 'MBRSH', null);
                xmlStreamWriter.writeCharacters('C');
            xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeStartElement(null, 'MATKL', null);
                xmlStreamWriter.writeCharacters(objProduct.Material_Group__c ?? '');
            xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeStartElement(null, 'MEINS', null);
                xmlStreamWriter.writeCharacters(objProduct.PMC_CPQ_QuantityUnitOfMeasure__c ?? '');
            xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeStartElement(null, 'WRKST', null);
                xmlStreamWriter.writeCharacters(objProduct.PMC_CPQ_Basic_Material__c ?? '');
            xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeStartElement(null, 'BRGEW', null);
                xmlStreamWriter.writeCharacters('1.000');
            xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeStartElement(null, 'NTGEW', null);
                xmlStreamWriter.writeCharacters('1.000');
            xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeStartElement(null, 'GEWEI', null);
                xmlStreamWriter.writeCharacters(objProduct.PMC_CPQ_QuantityUnitOfMeasure__c ?? '');
            xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeStartElement(null, 'RAUBE', null);
                xmlStreamWriter.writeCharacters('Z1');
            xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeStartElement(null, 'IPRKZ', null);
                xmlStreamWriter.writeCharacters('');
            xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeStartElement(null, 'TRAGR', null);
                xmlStreamWriter.writeCharacters('0003');
            xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeStartElement(null, 'PRDHA', null);
                xmlStreamWriter.writeCharacters(objProduct.PMC_CPQ_Product_Hierarchy__c	 ?? '');
            xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeStartElement(null, 'VABME', null);
                xmlStreamWriter.writeCharacters('1');
            xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeStartElement(null, 'KZKFG', null);
                xmlStreamWriter.writeCharacters('X');
            xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeStartElement(null, 'MAGRV', null);
                xmlStreamWriter.writeCharacters(objProduct.PMC_CPQ_Mat_Grp_Packaging_Materials__c ?? '');
            xmlStreamWriter.writeEndElement();          
            xmlStreamWriter.writeStartElement(null, 'EXTWG', null);
				xmlStreamWriter.writeCharacters(objProduct.PMC_CPQ_External_Material_Group__r.Name ?? '');
            xmlStreamWriter.writeEndElement();

     /* EIDGT-2455 Remove fields MSTAV and MSTDV from integration.
//            xmlStreamWriter.writeStartElement(null, 'MSTDV', null);
//                xmlStreamWriter.writeCharacters(strMSTDV);
//            xmlStreamWriter.writeEndElement();
//            xmlStreamWriter.writeStartElement(null, 'MSTAV', null);
//                xmlStreamWriter.writeCharacters(objProduct.PMC_CPQ_Cross_distribution__c ?? '');
//            xmlStreamWriter.writeEndElement();
     */ 
            xmlStreamWriter.writeStartElement(null, 'MTPOS_MARA', null);
                xmlStreamWriter.writeCharacters('0002');
            xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeStartElement(null, 'E1MAKTM', null);
                xmlStreamWriter.writeStartElement(null, 'SPRAS', null);
                xmlStreamWriter.writeCharacters('S');
                xmlStreamWriter.writeEndElement();
                xmlStreamWriter.writeStartElement(null, 'MAKTX', null);
                xmlStreamWriter.writeCharacters(objProduct.Name ?? '');
                xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeStartElement(null, 'E1MAKTM', null);
                xmlStreamWriter.writeStartElement(null, 'SPRAS', null);
                xmlStreamWriter.writeCharacters('P');
                xmlStreamWriter.writeEndElement();
                xmlStreamWriter.writeStartElement(null, 'MAKTX', null);
                xmlStreamWriter.writeCharacters(objProduct.Name ?? '');
                xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeStartElement(null, 'E1MAKTM', null);
                xmlStreamWriter.writeStartElement(null, 'SPRAS', null);
                xmlStreamWriter.writeCharacters('E');
                xmlStreamWriter.writeEndElement();
                xmlStreamWriter.writeStartElement(null, 'MAKTX', null);
                xmlStreamWriter.writeCharacters(objProduct.Name ?? '');
                xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeEndElement();

            for (PMC_CPQ_ProductLocation__c curProductLocation : lstProductLocation) 
            {
                IF (curProductLocation.PMC_CPQ_Location__r.PMC_CPQ_Country__c == 'BR') {
                    strINDUS = '00';
                } 
                IF (objProduct.PMCPlanning_Material__c != null) {
                    strPRGRP = objProduct.PMCPlanning_Material__c;
                    strPRGRP = strPRGRP.leftPad(18,'0'); // Ensure PRGRP is 18 characters long
                }
                IF (curProductLocation.PMC_CPQ_Location__r.PMC_CPQ_Profit_Center__c != null) {
                    strPRCTR = curProductLocation.PMC_CPQ_Location__r.PMC_CPQ_Profit_Center__c;
                    strPRCTR = strPRCTR.leftPad(10,'0'); // Ensure PRCTR is 10 characters long
                }
                xmlStreamWriter.writeStartElement(null, 'E1MARCM', null);
                    xmlStreamWriter.writeStartElement(null, 'WERKS', null);
                    xmlStreamWriter.writeCharacters(curProductLocation.PMC_CPQ_Location__r.PMC_CPQ_Plant__c ?? '');
                    xmlStreamWriter.writeEndElement();
                    xmlStreamWriter.writeStartElement(null, 'DISMM', null);
                    xmlStreamWriter.writeCharacters('PD');
                    xmlStreamWriter.writeEndElement();
                    xmlStreamWriter.writeStartElement(null, 'DISPO', null);
                    xmlStreamWriter.writeCharacters('001');
                    xmlStreamWriter.writeEndElement();
                    xmlStreamWriter.writeStartElement(null, 'PERKZ', null);
                    xmlStreamWriter.writeCharacters('M');
                    xmlStreamWriter.writeEndElement();		
                    xmlStreamWriter.writeStartElement(null, 'DISLS', null);
                    xmlStreamWriter.writeCharacters('MB');
                    xmlStreamWriter.writeEndElement();	
                    xmlStreamWriter.writeStartElement(null, 'BESKZ', null);
                    xmlStreamWriter.writeCharacters('X');
                    xmlStreamWriter.writeEndElement();			
                    xmlStreamWriter.writeStartElement(null, 'SBDKZ', null);
                    xmlStreamWriter.writeCharacters('2');
                    xmlStreamWriter.writeEndElement();	
                    xmlStreamWriter.writeStartElement(null, 'RGEKZ', null);
                    xmlStreamWriter.writeCharacters('1');
                    xmlStreamWriter.writeEndElement();	
                    xmlStreamWriter.writeStartElement(null, 'UEETO', null);
                    xmlStreamWriter.writeCharacters('');
                    xmlStreamWriter.writeEndElement();	
                    xmlStreamWriter.writeStartElement(null, 'UNETO', null);
                    xmlStreamWriter.writeCharacters('');
                    xmlStreamWriter.writeEndElement();			
                    xmlStreamWriter.writeStartElement(null, 'UEETK', null);
                    xmlStreamWriter.writeCharacters('X');
                    xmlStreamWriter.writeEndElement();
                    xmlStreamWriter.writeStartElement(null, 'LADGR', null);
                    xmlStreamWriter.writeCharacters('ZLG1');
                    xmlStreamWriter.writeEndElement();
                    xmlStreamWriter.writeStartElement(null, 'MTVFP', null);
                    xmlStreamWriter.writeCharacters('KP');
                    xmlStreamWriter.writeEndElement();		
                    xmlStreamWriter.writeStartElement(null, 'KAUTB', null);
                    xmlStreamWriter.writeCharacters('X');
                    xmlStreamWriter.writeEndElement();	
                    xmlStreamWriter.writeStartElement(null, 'PRCTR', null);
                    xmlStreamWriter.writeCharacters(strPRCTR);
                    xmlStreamWriter.writeEndElement();			
                    xmlStreamWriter.writeStartElement(null, 'LGPRO', null);
                    xmlStreamWriter.writeCharacters('R001');
                    xmlStreamWriter.writeEndElement();	
                    xmlStreamWriter.writeStartElement(null, 'STRGR', null);
                    xmlStreamWriter.writeCharacters('25');
                    xmlStreamWriter.writeEndElement();			
                    xmlStreamWriter.writeStartElement(null, 'INDUS', null);
                    xmlStreamWriter.writeCharacters(strINDUS);
                    xmlStreamWriter.writeEndElement();	
                    xmlStreamWriter.writeStartElement(null, 'STEUC', null);
                    xmlStreamWriter.writeCharacters(objProduct.PMC_CPQ_Control_Code__c ?? '');
                    xmlStreamWriter.writeEndElement();
                    xmlStreamWriter.writeStartElement(null, 'PPSKZ', null);
                    xmlStreamWriter.writeCharacters('X');
                    xmlStreamWriter.writeEndElement();	                    
                    xmlStreamWriter.writeStartElement(null, 'E1MARC1', null);
                        xmlStreamWriter.writeStartElement(null, 'SCM_RRP_TYPE', null);
                        xmlStreamWriter.writeCharacters('4');
                        xmlStreamWriter.writeEndElement();	
                        xmlStreamWriter.writeStartElement(null, 'SCM_HEUR_ID', null);
                        xmlStreamWriter.writeCharacters('SAP_PP_002');
                        xmlStreamWriter.writeEndElement();	
                        xmlStreamWriter.writeStartElement(null, 'SCM_WHATBOM', null);
                        xmlStreamWriter.writeCharacters('5');
                        xmlStreamWriter.writeEndElement();	
                        xmlStreamWriter.writeStartElement(null, 'SCM_RRP_SEL_GROUP', null);
                        xmlStreamWriter.writeCharacters(objProduct.PMC_CPQ_Planning_Group__c ?? '');
                        xmlStreamWriter.writeEndElement();							
                    xmlStreamWriter.writeEndElement();					
                    xmlStreamWriter.writeStartElement(null, 'E1MARDM', null);	
                        xmlStreamWriter.writeStartElement(null, 'LGORT', null);
                        xmlStreamWriter.writeCharacters('R001');
                        xmlStreamWriter.writeEndElement();							
                    xmlStreamWriter.writeEndElement();					
                    xmlStreamWriter.writeStartElement(null, 'E1MPGDM', null);
                        xmlStreamWriter.writeStartElement(null, 'PRGRP', null);
                        xmlStreamWriter.writeCharacters(strPRGRP);
                        xmlStreamWriter.writeEndElement();	
                        xmlStreamWriter.writeStartElement(null, 'PRWRK', null);
                        xmlStreamWriter.writeCharacters(curProductLocation.PMC_CPQ_Location__r.PMC_CPQ_Plant__c ?? '');
                        xmlStreamWriter.writeEndElement();	
                        xmlStreamWriter.writeStartElement(null, 'UMREF', null);
                        xmlStreamWriter.writeCharacters('1');
                        xmlStreamWriter.writeEndElement();							
                    xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeEndElement();
            
                xmlStreamWriter.writeStartElement(null, 'E1MBEWM', null);
                    xmlStreamWriter.writeStartElement(null, 'BWKEY', null);
                    xmlStreamWriter.writeCharacters(curProductLocation.PMC_CPQ_Location__r.PMC_CPQ_Plant__c ?? '');
                    xmlStreamWriter.writeEndElement();
                    xmlStreamWriter.writeStartElement(null, 'VPRSV', null);
                    xmlStreamWriter.writeCharacters('S');
                    xmlStreamWriter.writeEndElement();
                    xmlStreamWriter.writeStartElement(null, 'STPRS', null);
                    xmlStreamWriter.writeCharacters(String.valueOf(objProduct.Standard_Price__c) ?? '1.00');
                    xmlStreamWriter.writeEndElement();
                    xmlStreamWriter.writeStartElement(null, 'PEINH', null);
                    xmlStreamWriter.writeCharacters('1');
                    xmlStreamWriter.writeEndElement();		
                    xmlStreamWriter.writeStartElement(null, 'BKLAS', null);
                    xmlStreamWriter.writeCharacters('7920');
                    xmlStreamWriter.writeEndElement();	
                    xmlStreamWriter.writeStartElement(null, 'VMBKL', null);
                    xmlStreamWriter.writeCharacters('7920');
                    xmlStreamWriter.writeEndElement();	
                    xmlStreamWriter.writeStartElement(null, 'VMVPR', null);
                    xmlStreamWriter.writeCharacters('S');
                    xmlStreamWriter.writeEndElement();	
                    xmlStreamWriter.writeStartElement(null, 'VJVPR', null);
                    xmlStreamWriter.writeCharacters('S');
                    xmlStreamWriter.writeEndElement();	
                    xmlStreamWriter.writeStartElement(null, 'XLIFO', null);
                    xmlStreamWriter.writeCharacters('X');
                    xmlStreamWriter.writeEndElement();	
                    xmlStreamWriter.writeStartElement(null, 'MLMAA', null);
                    xmlStreamWriter.writeCharacters('X');
                    xmlStreamWriter.writeEndElement();	
                    xmlStreamWriter.writeStartElement(null, 'MLAST', null);
                    xmlStreamWriter.writeCharacters('3');
                    xmlStreamWriter.writeEndElement();					
                    xmlStreamWriter.writeStartElement(null, 'VJBKL', null);
                    xmlStreamWriter.writeCharacters('7920');
                    xmlStreamWriter.writeEndElement();	
                    xmlStreamWriter.writeStartElement(null, 'MTUSE', null);
                    xmlStreamWriter.writeCharacters(String.valueOf(objProduct.Material_Usage__c) ?? '');
                    xmlStreamWriter.writeEndElement();	
                    xmlStreamWriter.writeStartElement(null, 'MTORG', null);
                    xmlStreamWriter.writeCharacters(String.valueOf(objProduct.Material_Origin__c) ?? '');
                    xmlStreamWriter.writeEndElement();					
                    xmlStreamWriter.writeStartElement(null, 'OWNPR', null);
                    xmlStreamWriter.writeCharacters(objProduct.PMC_CPQ_Produced_In_House__c ? 'X' : '');
                    xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeEndElement();
            }

            xmlStreamWriter.writeStartElement(null, 'E1MARMM', null);
                xmlStreamWriter.writeStartElement(null, 'MEINH', null);
                xmlStreamWriter.writeCharacters('L86');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'UMREZ', null);
                xmlStreamWriter.writeCharacters('1');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'UMREN', null);
                xmlStreamWriter.writeCharacters('1');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'GEWEI', null);
                xmlStreamWriter.writeCharacters(objProduct.PMC_CPQ_QuantityUnitOfMeasure__c ?? '');
                xmlStreamWriter.writeEndElement();										
            xmlStreamWriter.writeEndElement();	

            xmlStreamWriter.writeStartElement(null, 'E1MVKEM', null);
                xmlStreamWriter.writeStartElement(null, 'VKORG', null);
                xmlStreamWriter.writeCharacters(objProduct.PMC_CPQ_Sales_Org__c ?? '');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'VTWEG', null);
                xmlStreamWriter.writeCharacters('00');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'MTPOS', null);
                xmlStreamWriter.writeCharacters('0002');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'KTGRM', null);
                xmlStreamWriter.writeCharacters('Z1');
                xmlStreamWriter.writeEndElement();										
            xmlStreamWriter.writeEndElement();	
            
            xmlStreamWriter.writeStartElement(null, 'E1MLANM', null);
                xmlStreamWriter.writeStartElement(null, 'ALAND', null);
                xmlStreamWriter.writeCharacters('PY');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'TATY1', null);
                xmlStreamWriter.writeCharacters('ZPVA');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'TAXM1', null);
                xmlStreamWriter.writeCharacters('1');
                xmlStreamWriter.writeEndElement();											
            xmlStreamWriter.writeEndElement();	
            
            xmlStreamWriter.writeStartElement(null, 'E1MLANM', null);
                xmlStreamWriter.writeStartElement(null, 'ALAND', null);
                xmlStreamWriter.writeCharacters('BR');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'TATY1', null);
                xmlStreamWriter.writeCharacters('IBRX');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'TAXM1', null);
                xmlStreamWriter.writeCharacters('1');
                xmlStreamWriter.writeEndElement();											
            xmlStreamWriter.writeEndElement();	
            
            xmlStreamWriter.writeStartElement(null, 'E1MTXHM', null);
                xmlStreamWriter.writeStartElement(null, 'TDOBJECT', null);
                xmlStreamWriter.writeCharacters('MATERIAL');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'TDID', null);
                xmlStreamWriter.writeCharacters('GRUN');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'TDSPRAS', null);
                xmlStreamWriter.writeCharacters('P');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'E1MTXLM', null);
                    xmlStreamWriter.writeStartElement(null, 'TDLINE', null);
                    xmlStreamWriter.writeCharacters(objproduct.PMC_CPQ_Basic_Text__c ?? '');
                    xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeEndElement();											
            xmlStreamWriter.writeEndElement();				 
            
            xmlStreamWriter.writeStartElement(null, 'E1MTXHM', null);
                xmlStreamWriter.writeStartElement(null, 'TDOBJECT', null);
                xmlStreamWriter.writeCharacters('MATERIAL');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'TDID', null);
                xmlStreamWriter.writeCharacters('GRUN');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'TDSPRAS', null);
                xmlStreamWriter.writeCharacters('S');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'E1MTXLM', null);
                    xmlStreamWriter.writeStartElement(null, 'TDLINE', null);
                    xmlStreamWriter.writeCharacters(objProduct.PMC_CPQ_Basic_Text_ES__c ?? '');
                    xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeEndElement();											
            xmlStreamWriter.writeEndElement();	
            
            xmlStreamWriter.writeStartElement(null, 'E1MTXHM', null);
                xmlStreamWriter.writeStartElement(null, 'TDOBJECT', null);
                xmlStreamWriter.writeCharacters('MATERIAL');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'TDID', null);
                xmlStreamWriter.writeCharacters('PRUE');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'TDSPRAS', null);
                xmlStreamWriter.writeCharacters('P');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'E1MTXLM', null);
                    xmlStreamWriter.writeStartElement(null, 'TDLINE', null);
                    xmlStreamWriter.writeCharacters('FERTILIZANTE MINERAL MISTO');
                    xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeEndElement();											
            xmlStreamWriter.writeEndElement();	
            
            xmlStreamWriter.writeStartElement(null, 'E1MTXHM', null);
                xmlStreamWriter.writeStartElement(null, 'TDOBJECT', null);
                xmlStreamWriter.writeCharacters('MATERIAL');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'TDID', null);
                xmlStreamWriter.writeCharacters('PRUE');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'TDSPRAS', null);
                xmlStreamWriter.writeCharacters('S');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'E1MTXLM', null);
                    xmlStreamWriter.writeStartElement(null, 'TDLINE', null);
                    xmlStreamWriter.writeCharacters('FERTILIZANTE MINERAL MIXTO');
                    xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeEndElement();											
            xmlStreamWriter.writeEndElement();	
            
            xmlStreamWriter.writeEndElement(); // E1MARAM
            xmlStreamWriter.writeEndElement(); // IDOC
            xmlStreamWriter.writeEndElement(); // MATMAS05
            
            xmlStreamWriter.writeStartElement(null, 'CLFMAS02', null);
            xmlStreamWriter.writeStartElement(null, 'IDOC', null);
            xmlStreamWriter.writeStartElement(null, 'E1OCLFM', null);
            xmlStreamWriter.writeStartElement(null, 'OBTAB', null);
                xmlStreamWriter.writeCharacters('MARA');
            xmlStreamWriter.writeEndElement();	
            xmlStreamWriter.writeStartElement(null, 'OBJEK', null);
                xmlStreamWriter.writeCharacters(strMATNR);
            xmlStreamWriter.writeEndElement();	
            xmlStreamWriter.writeStartElement(null, 'KLART', null);
                xmlStreamWriter.writeCharacters('001');
            xmlStreamWriter.writeEndElement();	
            xmlStreamWriter.writeStartElement(null, 'MAFID', null);
                xmlStreamWriter.writeCharacters('O');
            xmlStreamWriter.writeEndElement();	
            xmlStreamWriter.writeStartElement(null, 'E1KSSKM', null);
                xmlStreamWriter.writeStartElement(null, 'CLASS', null);
                xmlStreamWriter.writeCharacters('IBP_PLANNING');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'STATU', null);
                xmlStreamWriter.writeCharacters('1');
                xmlStreamWriter.writeEndElement();	
            xmlStreamWriter.writeEndElement();	
            xmlStreamWriter.writeStartElement(null, 'E1KSSKM', null);
                xmlStreamWriter.writeStartElement(null, 'CLASS', null);
                xmlStreamWriter.writeCharacters('Z_NPK_VALUE');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'STATU', null);
                xmlStreamWriter.writeCharacters('1');
                xmlStreamWriter.writeEndElement();	
            xmlStreamWriter.writeEndElement();	
            // Add Nitrogen value
			if (objProduct.PMC_CPQ_Nitrogen__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('Z_NITROGEN');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Nitrogen__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();
			}
            // Add Phosphorus value
			if (objProduct.PMC_CPQ_Phosphorous__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('Z_PHOSPHATE');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Phosphorous__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();	
			}
            // Add Potassium value
			if (objProduct.PMC_CPQ_Potassium__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('Z_POTASH');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Potassium__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();
			}
            // Add Magnesium value
			if (objProduct.PMC_CPQ_Magnesium__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('Z_MAGNESIUM');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Magnesium__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();
			}
            // Add Sulphur value
			if (objProduct.PMC_CPQ_Sulfur__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('Z_SULPHUR');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Sulfur__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();
			}
            // Add Calcium value
			if (objProduct.PMC_CPQ_Calcium__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('Z_CALCIUM');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Calcium__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();	
			}
            // Add Boron value
			if (objProduct.PMC_CPQ_Boron__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('Z_BORON');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Boron__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();
			}
            // Add Zinc value
			if (objProduct.PMC_CPQ_Zinc__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('Z_ZINC');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Zinc__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();
			}
            // Add Copper value
			if (objProduct.PMC_CPQ_Copper__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('Z_COPPER');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Copper__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();
			}
            // Add N value
			if (objProduct.PMC_CPQ_Nitrogen__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('N');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Nitrogen__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();
			}
            // Add P value
			if (objProduct.PMC_CPQ_Phosphorous__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('P');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Phosphorous__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();	
			}
            // Add PH2O value
			if (objProduct.PMC_CPQ_Phosphorous_PH2O__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('PH2O');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Phosphorous_PH2O__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();
			}
            // Add K value
			if (objProduct.PMC_CPQ_Potassium__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('K');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Potassium__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();
			}
            // Add CA value
			if (objProduct.PMC_CPQ_Calcium__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('CA');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Calcium__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();
			}
            // Add S value
			if (objProduct.PMC_CPQ_Sulfur__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('S');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Sulfur__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();
			}
            // Add SO4 value
			if (objProduct.PMC_CPQ_Sulfur_SO4__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('SO4');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Sulfur_SO4__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();
			}
            // Add MG value
			if (objProduct.PMC_CPQ_Magnesium__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('MG');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Magnesium__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();
			}
            // Add ZN value
			if (objProduct.PMC_CPQ_Zinc__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('ZN');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Zinc__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();	
			}
            // Add B value
			if (objProduct.PMC_CPQ_Boron__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('B');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Boron__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();
			}
            // Add CO value
			if (objProduct.PMC_CPQ_Cobalt__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('CO');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Cobalt__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();
			}
            // Add CU value
			if (objProduct.PMC_CPQ_Copper__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('CU');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Copper__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();
			}
            // Add FE value
			if (objProduct.PMC_CPQ_Iron__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('FE');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Iron__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();
			}
            // Add MN value
			if (objProduct.PMC_CPQ_Manganese__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('MN');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Manganese__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();	
			}
            // Add MO value
			if (objProduct.PMC_CPQ_Molybdenum__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('MO');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Molybdenum__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();
			}
            // Add CL value
			if (objProduct.PMC_CPQ_Chlorine__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('CL');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Chlorine__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();
			}
            // Add SI value
			if (objProduct.PMC_CPQ_Silicone__c > 0) {
				xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
					xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
					xmlStreamWriter.writeCharacters('SI');
					xmlStreamWriter.writeEndElement();	
					xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
					xmlStreamWriter.writeCharacters(String.valueOf(objProduct.PMC_CPQ_Silicone__c));
					xmlStreamWriter.writeEndElement();
					xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
					xmlStreamWriter.writeCharacters('1');
					xmlStreamWriter.writeEndElement();
				xmlStreamWriter.writeEndElement();
			}
            // Add Z_BR_LIM_INF value
            xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
                xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
                xmlStreamWriter.writeCharacters('Z_BR_LIM_INF');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
                xmlStreamWriter.writeCharacters('');
                xmlStreamWriter.writeEndElement();
                xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
                xmlStreamWriter.writeCharacters('1');
                xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeEndElement();
            // Add Z_BR_LIM_SUP value
            xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
                xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
                xmlStreamWriter.writeCharacters('Z_BR_LIM_SUP');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
                xmlStreamWriter.writeCharacters('');
                xmlStreamWriter.writeEndElement();
                xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
                xmlStreamWriter.writeCharacters('1');
                xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeEndElement();
            // Add Z_BR_LIM_1000 value
            xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
                xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
                xmlStreamWriter.writeCharacters('Z_BR_LIM_1000');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
                xmlStreamWriter.writeCharacters('');
                xmlStreamWriter.writeEndElement();
                xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
                xmlStreamWriter.writeCharacters('1');
                xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeEndElement();
            // Add Z_BR_REG_MINIST value
            xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
                xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
                xmlStreamWriter.writeCharacters('Z_BR_REG_MINIST');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'ATWRT', null);
                xmlStreamWriter.writeCharacters(objProduct.PMC_CPQ_Registration_in_the_Ministry__c ?? '');
                xmlStreamWriter.writeEndElement();
                xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
                xmlStreamWriter.writeCharacters('1');
                xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeEndElement();
            // Add Z_BR_GRP_MAT_VALIDADE value
            xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
                xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
                xmlStreamWriter.writeCharacters('Z_BR_GRP_MAT_VALIDADE');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'ATWRT', null);
                xmlStreamWriter.writeCharacters(objProduct.PMC_CPQ_Period_of_Validity__c ?? '');
                xmlStreamWriter.writeEndElement();
                xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
                xmlStreamWriter.writeCharacters('1');
                xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeEndElement();
            // Add Z_BR_GRP_FAMILY value
            xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
                xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
                xmlStreamWriter.writeCharacters('Z_BR_GRP_FAMILY');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'ATWRT', null);
                xmlStreamWriter.writeCharacters(objProduct.PMC_CPQ_Family_to_O9__c ?? '');
                xmlStreamWriter.writeEndElement();
                xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
                xmlStreamWriter.writeCharacters('1');
                xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeEndElement();
            // Add Z_BR_GRP_NAME value
            xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
                xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
                xmlStreamWriter.writeCharacters('Z_BR_GRP_NAME');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'ATWRT', null);
                xmlStreamWriter.writeCharacters(objProduct.PMC_CPQ_Group_Name_to_O9__c ?? '');
                xmlStreamWriter.writeEndElement();
                xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
                xmlStreamWriter.writeCharacters('1');
                xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeEndElement();
            // Add Z_BR_PROD_O9 value
            xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
                xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
                xmlStreamWriter.writeCharacters('Z_BR_PROD_O9');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'ATWRT', null);
                xmlStreamWriter.writeCharacters(objProduct.PMC_CPQ_Product_Resource_to_O9__c ?? '');
                xmlStreamWriter.writeEndElement();
                xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
                xmlStreamWriter.writeCharacters('1');
                xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeEndElement();
            // Add Z_BR_FERTILIZ value
            xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
                xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
                xmlStreamWriter.writeCharacters('Z_BR_FERTILIZ');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'ATWRT', null);
                xmlStreamWriter.writeCharacters('X');
                xmlStreamWriter.writeEndElement();
                xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
                xmlStreamWriter.writeCharacters('1');
                xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeEndElement();
            // Add Z_BR_CLASS_MINER value
            xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
                xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
                xmlStreamWriter.writeCharacters('Z_BR_CLASS_MINER');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'ATWRT', null);
                xmlStreamWriter.writeCharacters('FERTILIZANTE MINERAL MISTO');
                xmlStreamWriter.writeEndElement();
                xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
                xmlStreamWriter.writeCharacters('1');
                xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeEndElement();
            // Add Z_BR_REG_SENAVE value
            xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
                xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
                xmlStreamWriter.writeCharacters('Z_BR_REG_SENAVE');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
                xmlStreamWriter.writeCharacters(objProduct.PMC_CPQ_Senave__c ?? '');
                xmlStreamWriter.writeEndElement();
                xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
                xmlStreamWriter.writeCharacters('1');
                xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeEndElement();
            // Add Z_BR_REG_VTLIBRE value
            xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
                xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
                xmlStreamWriter.writeCharacters('Z_BR_REG_VTLIBRE');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'ATFLV', null);
                xmlStreamWriter.writeCharacters(objProduct.PMC_CPQ_Libre_Venta__c ?? '');
                xmlStreamWriter.writeEndElement();
                xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
                xmlStreamWriter.writeCharacters('1');
                xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeEndElement();
            // Add Z_BR_CLASSIF_BLOCK_K value
            xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
                xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
                xmlStreamWriter.writeCharacters('Z_BR_CLASSIF_BLOCK_K');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'ATWRT', null);
                xmlStreamWriter.writeCharacters('04');
                xmlStreamWriter.writeEndElement();
                xmlStreamWriter.writeStartElement(null, 'ATWRT_LONG', null);
                xmlStreamWriter.writeCharacters('04');
                xmlStreamWriter.writeEndElement();
                xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
                xmlStreamWriter.writeCharacters('1');
                xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeEndElement();
            // Add Z_BR_NAT_FIS value
            xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
                xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
                xmlStreamWriter.writeCharacters('Z_BR_NAT_FIS');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'ATWRT', null);
                xmlStreamWriter.writeCharacters('MISTURA DE GRANULOS');
                xmlStreamWriter.writeEndElement();
                xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
                xmlStreamWriter.writeCharacters('1');
                xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeEndElement();
            // Add Z_PY_NAT_FIS value
            xmlStreamWriter.writeStartElement(null, 'E1AUSPM', null);
                xmlStreamWriter.writeStartElement(null, 'ATNAM', null);
                xmlStreamWriter.writeCharacters('Z_PY_NAT_FIS');
                xmlStreamWriter.writeEndElement();	
                xmlStreamWriter.writeStartElement(null, 'ATWRT', null);
                xmlStreamWriter.writeCharacters('MEZCLA DE GRANOS');
                xmlStreamWriter.writeEndElement();
                xmlStreamWriter.writeStartElement(null, 'ATCOD', null);
                xmlStreamWriter.writeCharacters('1');
                xmlStreamWriter.writeEndElement();
            xmlStreamWriter.writeEndElement();
            // Add Date value
            xmlStreamWriter.writeStartElement(null, 'E1DATEM', null);
                xmlStreamWriter.writeStartElement(null, 'KEY_DATE', null);
                xmlStreamWriter.writeCharacters(strKeyDate);
                xmlStreamWriter.writeEndElement();	
            xmlStreamWriter.writeEndElement();
            
            xmlStreamWriter.writeEndElement(); // E1OCLFM
            xmlStreamWriter.writeEndElement(); // IDOC
            xmlStreamWriter.writeEndElement(); // CLFMAS02
            xmlStreamWriter.writeEndElement(); // ROOT
            
            String strSerializedBody = xmlStreamWriter.getXmlString();
            xmlStreamWriter.close();
            
            system.debug (strSerializedBody);
            return strSerializedBody;    
        }
        catch(Exception objException)
        {
            PMC_ErrorLogClass.processException(objException);
            strExceptionMsg = objException.getMessage();
            return null;
        }
        
    }
    
     /** 
     * @description This method will determine if auto retrigger is needed for queueable apex.
     * @param intStackDepth - Stack depth of queueable apex.
     * @param strErrorMsg - Error Message
     * @return true - If Auto-Retrigger is needed.
     * @return false - If Auto-Retrigger is not needed.
     */
    public static Boolean autoRetryQueueableApex(Integer intStackDepth, String strErrorMsg)
    {
        String strIntegrationAutoRetrySettingsLabel = 'PMC_CPQ_IntegrationAutoRetrySettings';
        PMC_CPQ_IntegrationSettings__mdt strIntegrationAutoRetrySettings = PMC_CPQ_IntegrationSettings__mdt.getInstance(strIntegrationAutoRetrySettingsLabel);
        String strIntegrationMsgCSV = strIntegrationAutoRetrySettings.PMC_CPQ_SettingValueLongTextArea__c;
        
        Integer intIntegrationRetryCount = Integer.valueOf(strIntegrationAutoRetrySettings.PMC_CPQ_SettingValueNumber__c);
        List<String> lstStringErrorMessages = strIntegrationMsgCSV.split('&');
        
        if(intStackDepth <= intIntegrationRetryCount && lstStringErrorMessages.contains(strErrorMsg))
        {
            return true;  
        }
        return false;
    }

}