/**
 * An apex page controller that takes the user to the right start page based on credentials or lack thereof
 */
public with sharing class CommunitiesLandingController {
    
    // Code we will invoke on page load.
    public PageReference forwardToStartPage() {
        return Network.communitiesLanding();
    }
    //GSMD-556 Start
    public PageReference forwardToCustomAuthPage() {
        return new PageReference( '/vforcesite/secur/logout.jsp');
    }
    //GSMD-556 End
    
    public CommunitiesLandingController() {}
}