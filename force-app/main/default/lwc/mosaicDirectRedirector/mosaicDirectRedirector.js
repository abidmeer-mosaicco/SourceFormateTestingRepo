import { LightningElement, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import USER_ID from "@salesforce/user/Id";
import { getRecord } from "lightning/uiRecordApi";
import basePath from "@salesforce/community/basePath";

const PROFILE_NAME_FIELD = "User.Profile.Name";
const REDIRECT_PROFILES = new Set(["Mosaic Direct Partner Community", "Mosaic Direct Partner Community Read Only"]);

export default class MosaicDirectRedirector extends NavigationMixin(LightningElement) {
  redirected = false;

  @wire(getRecord, { recordId: USER_ID, fields: [PROFILE_NAME_FIELD] })
  wiredUser({ data, error }) {
    if (this.redirected) return;

    if (data) {
      const rel = data.fields?.Profile;
      const profileName = rel?.displayValue || rel?.value?.fields?.Name?.value || "";

      if (REDIRECT_PROFILES.has(profileName)) {
        this.redirected = true;
        let url;

        if (profileName == 'Mosaic Direct Partner Community') {
          url = `${basePath}/NAM/placeorder`;
        }

        if (profileName == 'Mosaic Direct Partner Community Read Only') {
          url = `${basePath}/NAM/documents`;
        }

        window.location.assign(url);
      }
    } else if (error) {
      console.log("Error fetching user profile:", error);
    }
  }
}