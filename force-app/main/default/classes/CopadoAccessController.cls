/**
* @File Name : CopadoAccessController.cls
* @Description : LWC-safe controller for creating Copado Access Requests and sending notifications via an Email Template.
*              - Creates Copado_Access_Request__c from user input
*              - Sends one templated email to recipients defined in label `Copado_Admin_Users`
*              - Optionally uses an Org-Wide Email Address from label `Copado_OWD`
*              - Resolves Email Template using label `Copado_Access_Email_Template` (DeveloperName)
* @Author :
* @Last Modified By :
* @Last Modified On : August 28, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 28, 2025 |   | Initial Version
**/

public without sharing class CopadoAccessController {

	/**
     * @description Creates a Copado_Access_Request__c record and triggers notification email(s).
     * @param fullName     Full name of the requester.
     * @param email        Requester email address.
     * @param projectName  Project name for which Copado access is requested.
     * @param copadoRole   Desired Copado role (picklist value).
     * @param environment  Target environment (picklist value).
     * @param reason       Business justification for access.
     * @param managerEmail Approver/manager email (informational field on the record).
     * @return The Id of the created Copado_Access_Request__c record.
     * @throws AuraHandledException If email fails to send after record creation.
     */
    @AuraEnabled
    public static Id createCopadoAccessRequest(
        String fullName, String email,  String salesforceUserName,
        String projectName, String copadoRole,
        String reason, String managerEmail
    ) {
        Copado_Access_Request__c req = new Copado_Access_Request__c();
        req.Full_Name__c     = fullName;
        req.Email__c         = email;
        req.Project_Name__c  = projectName;
        req.Copado_Role__c   = copadoRole;
        req.Reason__c        = reason;
        req.Manager_Email__c = managerEmail;
        req.Salesforce_UserName__c = salesforceUserName;
        req.Status__c        = 'New';

        insert req;
        sendNotificationEmails(req.Id);
        return req.Id;
    }

	/**
     * @description Returns label values for the Environment__c picklist on Copado_Access_Request__c.
     * @return List of picklist labels for Environment__c.
     */
    // @AuraEnabled(cacheable=true)
    // public static List<String> getEnvironmentPicklistValues() {
    //     return getPicklistValues(Copado_Access_Request__c.Environment__c);
    // }

	/**
     * @description Returns label values for the Copado_Role__c picklist on Copado_Access_Request__c.
     * @return List of picklist labels for Copado_Role__c.
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getCopadoRolePicklistValues() {
        return getPicklistValues(Copado_Access_Request__c.Copado_Role__c);
    }

    /**
     * @description Sends a single templated email to all recipients from the `Copado_Admin_Users` label.
     *              Uses EmailTemplate resolved by DeveloperName from label `Copado_Access_Email_Template`.
     *              Sets WhatId to the newly created Copado_Access_Request__c for merge fields.
     * @param requestId The Id of the Copado_Access_Request__c to merge into the Email Template.
     * @throws AuraHandledException If Messaging.sendEmail returns an error.
     * @notes - A merge Contact/Lead is required by the email template engine; the method picks any Contact.
     *        - If `Copado_OWD` is set and matches an allowed Org-Wide Address, it is used as the From address.
     */
    private static void sendNotificationEmails(Id requestId) {
        // 1) Recipients from label (comma/semicolon supported)
        List<String> toList = new List<String>();
        if (!String.isBlank(Label.Copado_Admin_Users)) {
            for (String s : Label.Copado_Admin_Users.split('[,;]')) {
                s = s != null ? s.trim() : null;
                if (!String.isBlank(s)) toList.add(s);
            }
        }
        if (toList.isEmpty()) return;

        // 2) Template by DeveloperName (or store Id in a label if you prefer)
        Id templateId = [SELECT Id FROM EmailTemplate
            WHERE DeveloperName = :Label.Copado_Access_Email_Template LIMIT 1].Id;

        Id mergeContactId = [Select Id From Contact Limit 1].id;

        // 5) Build & send
        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
        msg.setTemplateId(templateId);
        msg.setTargetObjectId(mergeContactId);      // Contact/Lead required for templates
        msg.setTreatTargetObjectAsRecipient(false); // don’t send to merge contact
        msg.setWhatId(requestId);                   // record merge (fills {{{CAR fields}}})
        msg.setSaveAsActivity(true);
        msg.setToAddresses(toList);

        // Optional: From address via label Copado_OWD
        Id owea = getOrgWideEmailAddressIdByLabel();
        if (owea != null) msg.setOrgWideEmailAddressId(owea);

        Messaging.SendEmailResult[] res = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { msg }, false);
        if (res.isEmpty() || !res[0].isSuccess()) {
            String err = (res.isEmpty() || res[0].getErrors().isEmpty())
                ? 'Unknown email send error.'
                : res[0].getErrors()[0].getMessage();
            throw new AuraHandledException('Email not sent: ' + err);
        }
    }

	/**
     * @description Looks up an OrgWideEmailAddress by exact email value stored in label `Copado_OWD`.
     *              Only returns an address that is allowed for all profiles (IsAllowAllProfiles = true).
     * @return OrgWideEmailAddress.Id when found; otherwise null.
     */
    private static Id getOrgWideEmailAddressIdByLabel() {
        if (String.isBlank(Label.Copado_OWD)) return null;
        List<OrgWideEmailAddress> rows = [
            SELECT Id FROM OrgWideEmailAddress
            WHERE Address = :Label.Copado_OWD AND IsAllowAllProfiles = true
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0].Id;
    }

    /**
     * @description Returns the user-visible labels for a given picklist field.
     * @param f Picklist field token (Schema.SObjectField) to describe.
     * @return List of picklist entry labels in declared order.
     */
    private static List<String> getPicklistValues(Schema.SObjectField f) {
        List<String> out = new List<String>();
        for (Schema.PicklistEntry pe : f.getDescribe().getPicklistValues()) out.add(pe.getLabel());
        return out;
    }
}