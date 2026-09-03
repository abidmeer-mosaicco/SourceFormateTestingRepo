/**
 * @description This trigger is created on CommerceEntitlementProduct object.
 * @author Rohan Undale
 * @storynumber GDASF-14334
 */
trigger PMC_DH_CommerceEntitlementProductTrigger on CommerceEntitlementProduct (after insert, after delete) {
    new PMC_DH_CommerceEntitlementProductHandler().run();
}