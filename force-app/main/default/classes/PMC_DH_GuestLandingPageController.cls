/**
* @description : Class to get data on landing page.
* @author      : Ajeet
* @Created On  : 09/05/2023
* @last modified on 
* @last modified by 
* */
public with sharing class PMC_DH_GuestLandingPageController {
    private static final String BANNER_CONTENT_KEY = 'MCA4GP7BIP4VE4XFUPANUDMH55OI';
    private static final String COLLECTION_CONTENT_KEY = 'MCML2AQ3BB65FOHF2ZZL4BSTDI3A';
    @TestVisible
    private static String strSiteId; // = [SELECT Id, Name FROM Site WHERE Name='Mosaic_Direct2' LIMIT 1].Id??'';
    
      private PMC_DH_GuestLandingPageController() {
       List<Site> siteName=[SELECT Id, Name FROM Site WHERE Name='Mosaic_Direct1' WITH USER_MODE];
       if(siteName.isEmpty())
       {
       	 strSiteId='';
       }
          else{
              strSiteId=siteName[0].Id;
          }
      
    }
/**
    * @description : Wrapper Class for List of Icons and text
    * @author @Ajeet | 04-10-2023 
    **/
    public with sharing class LandingPageWrapper{
        /**
    * @description :Hero banner detail
    * @return HeroBannerWrapper
    **/
        @AuraEnabled
        public HeroBannerWrapper heroBannerDetail{get;set;}
        /**
    * @description : icon list details
    * @return IconDetailWrapper
    **/
        @AuraEnabled
        public List<IconDetailWrapper> lstIconDetail{get;set;}

    /**
     * @description Status Code and message
     * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
     */
    @AuraEnabled
    public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}

    }

    /**
    * @description : Wrapper Class for Hero Banner and its contents
    * @author @Ajeet | 05-10-2023 
    **/
    public with sharing class HeroBannerWrapper{
        /**
    * @description : Title of hero banner
    * @return string
    **/
        @AuraEnabled
        public String strTitle{get;set;}
        /**
    * @description : Description of hero banner
    * @return String
    **/
        @AuraEnabled
        public String strDescription{get;set;}
        /**
    * @description : Url of hero banner
    * @return String
    **/
        @AuraEnabled
        public String imageUrl{get;set;}
    }

    /**
    * @description Wrapper Class for List of Icons and text
    * @author @Ajeet | 05-10-2023 
    **/
    public with sharing class IconDetailWrapper{
        /**
    * @description : Title of Icons
    * @return string
    **/
        @AuraEnabled
        public String strTitle{get;set;}
        /**
    * @description : Url of icons
    * @return String
    **/
        @AuraEnabled
        public String iconUrl{get;set;}
        /**
    * @description Sequence order for icons
    * @return String
    **/
        @AuraEnabled
        public Integer intSequence{get;set;}
    }

    private static String getLanguage(String strLanguage){
        String lang = '';
        if(strLanguage == 'English'){
            lang = 'en_US';
        }else if(strLanguage == 'Portuguese'){
            lang = 'pt_BR';
        }else if(strLanguage == 'Spanish'){
            lang = 'es';
        }
        return lang;
    }
/**
    * @description 
    * @author Ajeet
    * @return String
    **/
    public static String getSiteId(){
        return (Test.isRunningTest()) ? strSiteId : Site.getSiteId();
    }
    /**
    * @description 
    * @author Ajeet
    * @param strLanguage
    * @return LandingPageWrapper
    **/
    @AuraEnabled
    public static LandingPageWrapper getLandingPageData(String strLanguage){
        String lang = getLanguage(strLanguage);
        LandingPageWrapper landingPageWraper = new LandingPageWrapper();
        try {
            PMC_DH_DigitalHubB2BUtils.throwTestExceptionForTest();
            ConnectApi.ManagedContentDeliveryDocument bannerData = getContentData(BANNER_CONTENT_KEY, lang);
            HeroBannerWrapper heroBannerDetail = new HeroBannerWrapper();
            if(bannerData!=null){
               	Map<String, Object> mapBannerContentBody = (Map<String, Object>) ConnectApi.ConnectUtilities.unwrapApexWrapper(bannerData.contentBody);
                Map<String,Object> mapBannerImage = (Map<String,Object>)ConnectApi.ConnectUtilities.unwrapApexWrapper(mapBannerContentBody.get('image'));
                heroBannerDetail.strTitle = bannerData.title;
                heroBannerDetail.strDescription = (String) mapBannerContentBody.get('description');
                heroBannerDetail.imageUrl = string.valueOf(mapBannerImage.get('url'));
                
            }

            List<IconDetailWrapper> lstIconDetails = new List<IconDetailWrapper>();
            ConnectApi.ManagedContentCollectionItems lstIconData = getContentCollection(COLLECTION_CONTENT_KEY,lang);
            if(!lstIconData.items.isEmpty()){
                for (ConnectApi.ManagedContentCollectionItem item : lstIconData.items) {
                    ConnectApi.ManagedContentDeliveryDocument iconData = getContentData(item.Id, lang); 
                    Map<String, Object> mapIconContentBody = (Map<String, Object>) ConnectApi.ConnectUtilities.unwrapApexWrapper(iconData.contentBody);
                Map<String,Object> mapIconImage = (Map<String,Object>)ConnectApi.ConnectUtilities.unwrapApexWrapper(mapIconContentBody.get('image'));
                    IconDetailWrapper iconDetails = new IconDetailWrapper();
                    iconDetails.strTitle = iconData.title;
                    iconDetails.iconUrl = String.valueOf(mapIconImage.get('url'));
                    iconDetails.intSequence = Integer.valueOf(mapIconContentBody.get('orderSequence'));
                    lstIconDetails.add(iconDetails);
                }
            }
            if(heroBannerDetail!=null){
            	landingPageWraper.heroBannerDetail = heroBannerDetail;
            }
            if(lstIconDetails!=null){
            	landingPageWraper.lstIconDetail = lstIconDetails;
            }
            landingPageWraper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'LandingPageInfo'); 
        }catch(Exception e) {
            landingPageWraper.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All'); 
            //throw new AuraHandledException(e.getMessage() + e.getLineNumber());
        }
        return landingPageWraper;
    }

    private static ConnectApi.ManagedContentDeliveryDocument getContentData(String contentKey, String lang){
        String siteId = getSiteId();  
        ConnectApi.ManagedContentDeliveryDocument bannerData;
        if(Test.isRunningTest()){
            bannerData = new ConnectApi.ManagedContentDeliveryDocument();
            bannerData.title = 'Banner';
            String strJSONMap = '{"orderSequence":"3", "description":"testDescription", "image" : { "source" : { "ref" : {"contentKey" : "MC23AB6HUBRRDULFHRAYI2BMDUT4"}, "type" : "imageReference"}, "url" : "https://globaldigitalacceleration--devp1.sandbox.my.site.com/vforcesite/sfsites/c/cms/delivery/media/MC23AB6HUBRRDULFHRAYI2BMDUT4?channelId=0apDT000000D4p4"}}';
            Map<String, Object> mapContentBody = (Map<String, Object>) JSON.deserializeUntyped(strJSONMap);
            bannerData.contentBody = mapContentBody;
        }else{
            bannerData = ConnectApi.ManagedContentDelivery.getManagedContentForSite(siteId,contentKey,lang, true); 
        }
        return bannerData;
    }

    private static ConnectApi.ManagedContentCollectionItems getContentCollection(String collectionKey, String lang){
        String siteId = getSiteId();  
        ConnectApi.ManagedContentCollectionItems lstIconData;
        if(Test.isRunningTest()){
            lstIconData = new ConnectApi.ManagedContentCollectionItems();
            lstIconData.title = 'Collection';
            List<ConnectApi.ManagedContentCollectionItem> lstItems = new List<ConnectApi.ManagedContentCollectionItem>();
            ConnectApi.ManagedContentCollectionItem item = new ConnectApi.ManagedContentCollectionItem();
            item.name = 'Items';
            item.Id = '7665653';
            lstItems.add(item);
            lstIconData.items = lstItems;
        }else{
            lstIconData = ConnectApi.ManagedContentDelivery.getCollectionItemsForSite(siteId,collectionKey,lang);
        }
        return lstIconData;
    }

}