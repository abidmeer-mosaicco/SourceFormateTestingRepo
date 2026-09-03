@IsTest
public class MD_MenuServiceTest {
    
    @IsTest
    static void testGetMenuItemsAsAdmin() {
        MD_MenuConfig__mdt mockSam = new MD_MenuConfig__mdt(
            MasterLabel = 'SAM Test',
            DeveloperName = 'MD_SAM_MENU',
            URL__c = '/sam'
        );
        MD_MenuConfig__mdt mockNam = new MD_MenuConfig__mdt(
            MasterLabel = 'NAM Test',
            DeveloperName = 'MD_NAM_MENU',
            URL__c = '/nam'
        );
        MD_MenuConfig__mdt mockSamChild = new MD_MenuConfig__mdt(
            MasterLabel = 'SAM Child',
            DeveloperName = 'MD_SAM_CHILD',
            URL__c = '/child',
            ParentMenu__c = 'MD_SAM_MENU'
        );
        MD_MenuService.mockConfigs = new List<MD_MenuConfig__mdt>{ mockSam, mockNam, mockSamChild };

        MD_MenuService.forceAdminForTest = true;
        
        Test.startTest();
        MD_MenuService.MenuDataWrapper result = MD_MenuService.getMenuItems();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Service execution should cleanly return the payload wrapper');
        System.assertEquals(true, result.regionalMenus.containsKey('SAM'), 'SAM array must be grouped');
        System.assertEquals(true, result.regionalMenus.containsKey('NAM'), 'NAM array must be grouped');
        System.assert(result.isAdmin, 'Menu should recognize the test force admin variable');
    }

    @IsTest
    static void testGetMenuItemsAsStandardUser() {
        MD_MenuService.mockConfigs = new List<MD_MenuConfig__mdt>();
        MD_MenuService.forceAdminForTest = false;

        Test.startTest();
        MD_MenuService.MenuDataWrapper result = MD_MenuService.getMenuItems();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Service execution should cleanly return the payload wrapper even if configs empty');
        System.assertEquals(false, result.isAdmin, 'User without admin rights or force admin config should return false');
    }
    
    @IsTest
    static void testMenuWrapperConstruct() {
        Test.startTest();
        MD_MenuService.MenuDataWrapper rawWrapper = new MD_MenuService.MenuDataWrapper();
        MD_MenuService.MD_MenuItemWrapper itemWrapper = new MD_MenuService.MD_MenuItemWrapper('Label Test', '/route', 'MD_CUSTOM_KEY', new List<MD_MenuService.MD_MenuItemWrapper>());
        Test.stopTest();
        
        System.assertEquals(false, rawWrapper.isAdmin, 'Admin param initializes false by default');
        System.assertEquals('Label Test', itemWrapper.label, 'Injected constructor string must populate class property');
        System.assertEquals('/route', itemWrapper.url, 'Injected constructor string must populate class property');
    }
}