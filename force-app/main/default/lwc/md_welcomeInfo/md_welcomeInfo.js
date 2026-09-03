import { LightningElement, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import FIRST_NAME from '@salesforce/schema/User.FirstName';
import getAccountManagerName from '@salesforce/apex/PMC_DH_AccountDetailController.getAccountManagerName';
import getEffectiveAccountDetails from '@salesforce/apex/PMC_DH_AccountSwitcherController.getEffectiveAccountDetails';

import pmc_home_hello from "@salesforce/label/c.pmc_home_hello";
import pmc_home_welcome from "@salesforce/label/c.pmc_home_welcome";
import pmc_home_accountManager from "@salesforce/label/c.pmc_home_accountManager";

export default class MdWelcomeInfo extends LightningElement {
  accountManagerName;

  labels = {
    pmc_home_hello,
    pmc_home_welcome,
    pmc_home_accountManager
  };

  @wire(getRecord, { recordId: USER_ID, fields: [FIRST_NAME] }) user;

  get firstName() {
    return getFieldValue(this.user.data, FIRST_NAME);
  }

  connectedCallback() {
    // this.loadAccountManager(); // DEPRECATED
  }

  async loadAccountManager() {
    try {
      const account = await getEffectiveAccountDetails();
      if (!account?.strAccountId) return;

      const data = await getAccountManagerName({ strEffAccId: account.strAccountId });
      this.accountManagerName = data?.strData ?? null;
    } catch (e) {
      console.error('Erro ao carregar gerente de contas:', e);
    }
  }
}