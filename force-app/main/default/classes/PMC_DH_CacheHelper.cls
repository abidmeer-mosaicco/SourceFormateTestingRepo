/**
 * @description       : 
 * @author            : siddharth.pradhan@mosaicco.com | Digital Hub
 * @group             : 
 * @last modified on  : 09-10-2023
 * @last modified by  : siddharth.pradhan@mosaicco.com | Digital Hub
**/
public with sharing class PMC_DH_CacheHelper {
 
    //private static Cache.OrgPartition orgPart;
    private static String orgPartitionKey='local.DefaultPartition';
    

    /**
    * @description 
    * @author siddharth.pradhan@mosaicco.com | Digital Hub | 09-10-2023 
    * @param key 
    * @param valueToStore 
    * @param intTTL
    **/
    public static void setOrgPartitionCache(String key,Object valueToStore,Integer intTTL) {
        String cacheKey=orgPartitionKey+'.'+key;
        Cache.Org.put(cacheKey,valueToStore,intTTL); 
    }

    /**
    * @description 
    * @author siddharth.pradhan@mosaicco.com | Digital Hub | 09-10-2023 
    * @param key 
    * @return Object 
    **/
    public static Object getOrgPartitionCachebyKey(String key) {
        String cacheKey=orgPartitionKey+'.'+key;
        return Cache.Org.get(cacheKey); 
    }
/**
 * @description iskeyAvailable Method
 * @param key 
 * @author siddharth pradhan
 * @return    `Boolean`
 */
    public static Boolean isKeyAvailable(String key) {
        String cacheKey=orgPartitionKey+'.'+key;
        return(Cache.Org.contains(cacheKey));   
    }
    /**
    * @description 
    * @author siddharth.pradhan@mosaicco.com | Digital Hub | 09-10-2023 
    * @param key 
    * @param valueToStore 
    **/
    public static void setCachePartitionCache(String key,Object valueToStore) {
        Cache.session.put(key,valueToStore); 
    }
    /**
    * @description 
    * @author siddharth.pradhan@mosaicco.com | Digital Hub | 09-10-2023 
    * @param key 
    * @return Object 
    **/
    public static Object getSessionPartitionCachebyKey(String key) {
        return Cache.session.get(key); 
    }
    /**
 * @description iskeyAvailable Method
 * @param key 
 * @author siddharth pradhan
 * @return    `Boolean`
 */
    public static Boolean isSessionKeyAvailable(String key) {
        return(Cache.Session.contains(key));   
    }
}