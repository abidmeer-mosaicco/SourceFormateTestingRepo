/**
* @description : class for product suggestions
* @author      : Humera Rahath
* @userStory   : GDASF-659
* */
public class PMC_DH_ProductSuggestionsClass {
    public static Boolean boolHandleException=false;
    
    /*************************************************************************
* @method Name: getProductSuggestions
* @description: Method to get product suggestions using connectapi 
* @params     : String strSearchTerm,String strEffectiveAccountId
* @return     : String
*****************************************************************************/

    /**
    * @description 
    * @author @mhumerarahath | 05-19-2023 
    * @param strSearchTerm 
    * @param strEffectiveAccountId 
    * @return PMC_DH_ProductSuggestionListWrapper 
    **/
    @AuraEnabled
    public static PMC_DH_ProductSuggestionListWrapper getProductSuggestions(String strSearchTerm,String strEffectiveAccountId) //changes as part of GDASF-19642
    {
        PMC_DH_Store_Configuration__mdt configLimit = PMC_DH_Store_Configuration__mdt.getInstance('Product_Suggestion_Max_Result');
        Integer intMaxResults=(Integer)configLimit.PMC_DH_Product_Max_Result__c;
        //Wrapper for Product Suggestions
        PMC_DH_ProductSuggestionListWrapper wrpProdSuggestionList = new PMC_DH_ProductSuggestionListWrapper(); //changes as part of GDASF-19642
            List<ProductSuggestionWrapper> lstProdSuggestions=new  List<ProductSuggestionWrapper>();
            ProductSuggestionWrapper prodSuggestion;
            ConnectApi.ProductSearchSuggestionsResults lstsearchresults;
            List<ConnectApi.AbstractSearchSuggestion> lstsearchsuggestion;
        try
        {
            
            //method to get NetworkId of the logged-in user
            String strNetworkId= Network.getNetworkId();
            //method to get WebStoreId of the logged-in user
            String strWebStoreId=PMC_DH_DigitalHubB2BUtils.getWebStoreId(strNetworkId);
            
            
            if(!test.isRunningTest())
            {
                // connect api to get product suggestions
                lstsearchresults=ConnectApi.CommerceSearch.getSuggestions(strWebStoreId,strEffectiveAccountId,strSearchTerm,intMaxResults);
                //contains the list of suggestions
                lstsearchsuggestion=(List<ConnectApi.AbstractSearchSuggestion>)lstsearchresults.recentSearchSuggestions;
            }
            else if(test.isRunningTest() && boolHandleException)
            {
                throw new AuraHandledException(PMC_DH_ConstantClass.TEST_EXCEPTION_MESSAGE);
            }
            else 
            {
                lstsearchresults=new ConnectApi.ProductSearchSuggestionsResults();
                lstsearchsuggestion=new List<ConnectApi.SearchSuggestion>();
                ConnectApi.SearchSuggestion searchSuggest=new ConnectApi.SearchSuggestion();
                searchSuggest.value=PMC_DH_ConstantClass.PRODUCT_SUGGESTION_VALUE;
                lstsearchsuggestion.add(searchSuggest);
            }
            if(!lstsearchsuggestion.isEmpty())
            {
                for(ConnectApi.AbstractSearchSuggestion prodSugg:lstsearchsuggestion)
                {
                    prodSuggestion=new ProductSuggestionWrapper();
                    prodSuggestion.strProductValue=prodSugg.value;
                    lstProdSuggestions.add(prodSuggestion);
                }
              }
            wrpProdSuggestionList.lstProdSuggestions = lstProdSuggestions; //changes as part of GDASF-19642
            wrpProdSuggestionList.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('000', 'ProductSuggestion'); //changes as part of GDASF-19642
        }
        catch(Exception ex)
        {
            wrpProdSuggestionList.statusCodeMessage = PMC_DH_DigitalHubB2BUtils.getMessageForStatusCode('100', 'All'); //changes as part of GDASF-19642
            throw new AuraHandledException(ex.getMessage());
        }
        return wrpProdSuggestionList; //changes as part of GDASF-19642
    }
    
/**
* @description : Wrapper for Product Suggestions
* @author      : Humera Rahath
* @last modified on 2023-05-17
* @last modified by @humera
**/ 
    public class ProductSuggestionWrapper
    {
        /**
        * @description Value of Product Suggestion
        * @return string
        **/ 
        @AuraEnabled
        public string strProductValue{get;set;}
    }

    // added as part of GDASF-19642
    /**
    * @description : Wrapper for List of product suggestions
    * @author      : Nikhilesh Mohanty
    * @last modified on 2024-01-10
    **/ 
    public class PMC_DH_ProductSuggestionListWrapper
    {
        /**
        * @description List of product suggestions
        * @author Nikhilesh
        * @return List<ProductSuggestionWrapper>
        **/ 
        @AuraEnabled
        public List<ProductSuggestionWrapper> lstProdSuggestions{get;set;}

        /**
        * @description Status Code and message
        * @author Nikhilesh
        * @return PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper
        */
        @AuraEnabled
        public PMC_DH_DigitalHubB2BUtils.PMC_DH_StatusCodeMessageWrapper statusCodeMessage{get;set;}
    }
}