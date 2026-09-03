/**
* @description       : Batch Helper Class for Delegated Account Access
* @created on        : 11-21-2023
* @author            : Rohan Undale
 * @last modified on : 02-13-2024
 * @last modified by : Rohan Undale
**/
public with sharing class PMC_DH_DelegatedAccountAccessBatchHelper {
    /**
    * @description Execute helper method for PMC_DH_DelegatedAccountAccessBatch
    * @created on 11-21-2023
    * @author Rohan Undale
    * @param lstAccountContactRelation 
    **/
    public static void executeHelper(List<AccountContactRelation> lstAccountContactRelation){
        try{
            Map<Id, List<User>> mapAccountUser = getAccountUserMap(lstAccountContactRelation);
            createDelegatedAccountAccess(mapAccountUser);
            updateAccountContactRelation(lstAccountContactRelation);
        }
        Catch(Exception ex){
            //System.debug(ex.getLineNumber()+ex.getMessage()+ex.getStackTraceString()+ex.getCause());
            throw new AuraHandledException(ex.getMessage()+ex.getStackTraceString());
        }
    }

    private static Map<Id, List<User>> getAccountUserMap(List<AccountContactRelation> lstAccountContactRelation){
        Map<Id, List<User>> mapAccountUser = new Map<Id, List<User>>();
        Set<Id> setContactIds = new Set<Id>();
        for(AccountContactRelation acr : lstAccountContactRelation){
            setContactIds.add(acr.ContactId);
        }

        List<User> lstUser = [SELECT Id, AccountId, ContactId
                              FROM User
                              WHERE ContactId IN :setContactIds
                              WITH USER_MODE];

        for(AccountContactRelation acr : lstAccountContactRelation){
            User objUser = new User();
            for(User usr : lstUser){
                if(usr.ContactId == acr.ContactId){
                    objUser = usr;
                    break;
                }
            }
            if(objUser.Id != null){
                if(!mapAccountUser.containsKey(acr.AccountId)){
                    mapAccountUser.put(acr.AccountId, new List<User>());
                }
                mapAccountUser.get(acr.AccountId).add(objUser);
            }
        }

        return mapAccountUser;
    }

    private static void createDelegatedAccountAccess(Map<Id, List<User>> mapAccountUser){
        List<DelegatedAccount> lstDelegatedAccount = new List<DelegatedAccount>();
        Set<Id> setAccountId = mapAccountUser.keySet();
        for(Id accId : setAccountId){
            List<User> lstUser = mapAccountUser.get(accId);
            for(User objUser : lstUser){
                DelegatedAccount objDelegatedAccount = new DelegatedAccount();
                objDelegatedAccount.Name = 'Account '+ accId + objUser.Id;
                objDelegatedAccount.TargetId = accId;
                objDelegatedAccount.ManagedById = objUser.Id;
                objDelegatedAccount.AccessBuyFor = true;
                objDelegatedAccount.AccessManageUsers = true;
                lstDelegatedAccount.add(objDelegatedAccount);
            }
        }

        if(!lstDelegatedAccount.isEmpty() && Schema.sObjectType.DelegatedAccount.isCreateable()){
            Database.insert(lstDelegatedAccount, false);
        }
    }

    private static void updateAccountContactRelation(List<AccountContactRelation> lstAccountContactRelation){
        for(AccountContactRelation acr : lstAccountContactRelation){
            acr.PMC_DH_isProcessed__c = true;
        }
        if(Schema.sObjectType.AccountContactRelation.isUpdateable()){
            Database.update(lstAccountContactRelation, false);
        }
    }
    /**
    * @description finish helper method for PMC_DH_DelegatedAccountAccessBatch
    * @created on 11-22-2023
    * @author Rohan Undale 
    **/
    /*public static void finishHelper(){
        List<AccountContactRelation> lstAccountContactRelation = [SELECT Id, AccountId, ContactId
                                                                  FROM AccountContactRelation
                                                                  WITH USER_MODE];

        Map<Id, List<User>> mapAccountUser = getAccountUserMap(lstAccountContactRelation);

        List<DelegatedAccount> lstDelegatedAccount = [SELECT Id, ParentId, TargetId, ManagedById 
                                                      FROM DelegatedAccount
                                                      WITH USER_MODE];
        
        deleteInvalidDelegatedAccountAccess(mapAccountUser, lstDelegatedAccount);
    }

    private static void deleteInvalidDelegatedAccountAccess(Map<Id, List<User>> mapAccountUser, List<DelegatedAccount> lstDelegatedAccount){
        List<DelegatedAccount> lstDelegatedAccountToDelete = new List<DelegatedAccount>();
        for(DelegatedAccount objDelegatedAccount : lstDelegatedAccount){
            DelegatedAccount da = new DelegatedAccount();
            List<User> lstUser = new List<User>();
            if(mapAccountUser.ContainsKey(objDelegatedAccount.TargetId)){
                lstUser = mapAccountUser.get(objDelegatedAccount.TargetId);
            }
            
            for(User objUser : lstUser){
                if(objDelegatedAccount.ParentId == objUser.AccountId &&
                   objDelegatedAccount.ManagedById == objUser.Id){
                    da = objDelegatedAccount;
                    break;
                }
            }
            if(String.isBlank(da.Id)){
                lstDelegatedAccountToDelete.add(objDelegatedAccount);
            }
        }
        if(!lstDelegatedAccountToDelete.isEmpty() && Schema.sObjectType.DelegatedAccount.isDeletable()){
            Database.delete(lstDelegatedAccountToDelete, false);
        }
    }*/
}