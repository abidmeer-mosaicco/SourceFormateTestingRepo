/**
* @description : Test class for PMC_DH_SignInControllerTest
* @author      : Lohitha Sai
* @userStory   : GDPH-167
**/
@isTest
    public class PMC_DH_MockSiteService extends PMC_DH_SiteService
    {
        public override PageReference shadowLogin(String userName, String passWord, String redirectUrl)
        {
            PageReference pg;
            if(String.isBlank(passWord)){
                pg = null;
                //pg = new PageReference('/login');
            }else{
                pg = new PageReference(redirectUrl);
            }
            return pg;
        }
    }