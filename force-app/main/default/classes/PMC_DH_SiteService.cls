/**
* @description : Mock class for PMC_DH_MockSiteService
* @author      : Sugunakar
* @userStory   : GDPH-167
**/
public virtual with sharing class PMC_DH_SiteService
{
    static PMC_DH_SiteService service = new PMC_DH_SiteService();
    /*************************************************************************
* @method Name   : login
* @description   : Method to assign the authenticated user to login
* @param       userName
* @param       passWord
* @param       redirectUrl
* @return        pageReference
*****************************************************************************/
    public static pageReference login(String userName, String passWord, String redirectUrl)
    {
        return service.shadowLogin(userName, passWord, redirectUrl);
    }

    @TestVisible static void setMock(PMC_DH_SiteService mock) { service = mock; }

    @TestVisible virtual pageReference shadowLogin(String userName, String passWord, String redirectUrl)
    {
        return Site.login(userName, passWord, redirectUrl);
    }
}