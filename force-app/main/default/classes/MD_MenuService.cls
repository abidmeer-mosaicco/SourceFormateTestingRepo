public without sharing class MD_MenuService {

    @TestVisible private static Boolean forceAdminForTest = false;
    @TestVisible private static List<MD_MenuConfig__mdt> mockConfigs = null;

    @AuraEnabled(cacheable=true)
    public static MenuDataWrapper getMenuItems() {
        MenuDataWrapper result = new MenuDataWrapper();

        Boolean isAdmin = Test.isRunningTest() ? forceAdminForTest : FeatureManagement.checkPermission('MD_ADMIN');
        result.isAdmin = isAdmin;

        List<MD_MenuConfig__mdt> allConfigs;
        if (mockConfigs != null) {
            allConfigs = mockConfigs;
        } else {
            User currentUser = [SELECT LanguageLocaleKey FROM User WHERE Id = :UserInfo.getUserId()];

            allConfigs = [
                SELECT MasterLabel, DeveloperName, PermissionSetAPI__c, URL__c, ParentMenu__c, Order__c
                FROM MD_MenuConfig__mdt
                WHERE Language__c = :currentUser.LanguageLocaleKey AND IsActive__c = true
                ORDER BY Order__c ASC
            ];
        }

        if (!isAdmin) {
            result.defaultMenu = buildMenuTree(allConfigs, false);
            return result;
        }

        Map<String, List<MD_MenuConfig__mdt>> configsByRegion = new Map<String, List<MD_MenuConfig__mdt>>();
        List<MD_MenuConfig__mdt> sharedConfigs = new List<MD_MenuConfig__mdt>();

        for (MD_MenuConfig__mdt conf : allConfigs) {
            List<String> parts = conf.DeveloperName.split('_');

            if (parts.size() >= 3 && parts[0].equalsIgnoreCase('MD')) {
                String region = parts[1].toUpperCase();

                if (!configsByRegion.containsKey(region)) {
                    configsByRegion.put(region, new List<MD_MenuConfig__mdt>());
                }

                configsByRegion.get(region).add(conf);
            } else {
                sharedConfigs.add(conf);
            }
        }

        for (String region : configsByRegion.keySet()) {
            List<MD_MenuConfig__mdt> regionConfigs = new List<MD_MenuConfig__mdt>();
            regionConfigs.addAll(configsByRegion.get(region));
            regionConfigs.addAll(sharedConfigs);
            result.regionalMenus.put(region, buildMenuTree(regionConfigs, true));
        }

        return result;
    }

    private static List<MD_MenuItemWrapper> buildMenuTree(List<MD_MenuConfig__mdt> configs, Boolean bypassCheck) {
        List<MD_MenuItemWrapper> menu = new List<MD_MenuItemWrapper>();
        menu.add(new MD_MenuItemWrapper('Home', '/', null, null));

        Map<String, MD_MenuItemWrapper> itemMap = new Map<String, MD_MenuItemWrapper>();
        Map<String, MD_MenuConfig__mdt> configMap = new Map<String, MD_MenuConfig__mdt>();
        List<MD_MenuItemWrapper> rootItems = new List<MD_MenuItemWrapper>();

        for (MD_MenuConfig__mdt conf : configs) {
            String url = String.isNotBlank(conf.URL__c) ? conf.URL__c : '#';

            itemMap.put(conf.DeveloperName, new MD_MenuItemWrapper(
                conf.MasterLabel,
                url,
                conf.DeveloperName,
                new List<MD_MenuItemWrapper>()
            ));

            configMap.put(conf.DeveloperName, conf);
        }

        for (MD_MenuConfig__mdt conf : configs) {
            MD_MenuItemWrapper item = itemMap.get(conf.DeveloperName);

            if (String.isNotBlank(conf.ParentMenu__c) && itemMap.containsKey(conf.ParentMenu__c)) {
                itemMap.get(conf.ParentMenu__c).children.add(item);
            } else {
                rootItems.add(item);
            }
        }

        List<MD_MenuItemWrapper> finalRootItems = new List<MD_MenuItemWrapper>();
        for (MD_MenuItemWrapper root : rootItems) {
            if (filterNode(root, bypassCheck, configMap)) {
                finalRootItems.add(root);
            }
        }

        menu.addAll(finalRootItems);
        return menu;
    }

    private static Boolean filterNode(MD_MenuItemWrapper node, Boolean bypassCheck, Map<String, MD_MenuConfig__mdt> confMap) {
        MD_MenuConfig__mdt conf = confMap.get(node.featureKey);
        Boolean isVisible = false;

        if (bypassCheck || (conf != null && String.isNotBlank(conf.PermissionSetAPI__c) && FeatureManagement.checkPermission(conf.PermissionSetAPI__c))) {
            isVisible = true;
        }

        if (node.children != null && !node.children.isEmpty()) {
            List<MD_MenuItemWrapper> validChildren = new List<MD_MenuItemWrapper>();
            for (MD_MenuItemWrapper child : node.children) {
                if (filterNode(child, bypassCheck, confMap)) {
                    validChildren.add(child);
                }
            }

            node.children = validChildren.isEmpty() ? null : validChildren;

            if (node.children != null) {
                isVisible = true;
            }
        } else {
            node.children = null;
        }

        return isVisible;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Boolean> getActiveRouteGuards() {
        Map<String, Boolean> routeAccessMap = new Map<String, Boolean>();

        Boolean isAdmin = Test.isRunningTest() ? forceAdminForTest : FeatureManagement.checkPermission('MD_ADMIN');

        List<MD_MenuConfig__mdt> allConfigs;
        if (mockConfigs != null) {
            allConfigs = mockConfigs;
        } else {
            allConfigs = [SELECT PermissionSetAPI__c, URL__c, IsActive__c FROM MD_MenuConfig__mdt WHERE URL__c != null];
        }

        for (MD_MenuConfig__mdt conf : allConfigs) {
            Boolean hasAccess = conf.IsActive__c == true
                ? isAdmin || (String.isNotBlank(conf.PermissionSetAPI__c) && FeatureManagement.checkPermission(conf.PermissionSetAPI__c))
                : isAdmin;
            routeAccessMap.put(conf.URL__c, hasAccess);
        }

        return routeAccessMap;
    }

    public class MenuDataWrapper {
        @AuraEnabled public Boolean isAdmin { get; set; }
        @AuraEnabled public List<MD_MenuItemWrapper> defaultMenu { get; set; }
        @AuraEnabled public Map<String, List<MD_MenuItemWrapper>> regionalMenus { get; set; }

        public MenuDataWrapper() {
            this.isAdmin = false;
            this.defaultMenu = new List<MD_MenuItemWrapper>();
            this.regionalMenus = new Map<String, List<MD_MenuItemWrapper>>();
        }
    }

    public class MD_MenuItemWrapper {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String url { get; set; }
        @AuraEnabled public String featureKey { get; set; }
        @AuraEnabled public List<MD_MenuItemWrapper> children { get; set; }

        public MD_MenuItemWrapper(String label, String url, String featureKey, List<MD_MenuItemWrapper> children) {
            this.label = label;
            this.url = url;
            this.featureKey = featureKey;
            this.children = children;
        }
    }
}