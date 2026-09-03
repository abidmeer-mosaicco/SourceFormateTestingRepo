// Core
  import { LightningElement, api, track, wire } from 'lwc';
  import USER_ID from '@salesforce/user/Id';
  import runAsyncTeamSync from '@salesforce/apex/OppTeamAsyncController.runAsyncTeamSync';


  import { RefreshEvent } from 'lightning/refresh';
  import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

  // Bulk OTM delete (owner-wide and single-opp)
  import bulkDeleteOppTeamMembersForOwner
    from '@salesforce/apex/UserLookupControllerOppTeams.bulkDeleteOppTeamMembersForOwner';
  import bulkDeleteOppTeamMembersOnOpportunity
    from '@salesforce/apex/UserLookupControllerOppTeams.bulkDeleteOppTeamMembersOnOpportunity';

  import upsertDefaultTeamViaFlow
    from '@salesforce/apex/UserLookupControllerOppTeams.upsertDefaultTeamViaFlow';
    
  import bulkUpsertDefaultTeamViaFlowInterviews
    from '@salesforce/apex/UserLookupControllerOppTeams.bulkUpsertDefaultTeamViaFlowInterviews';


  // Apex wrappers to run Autolaunched Flows from Apex

  import deleteDefaultTeamViaFlow
    from '@salesforce/apex/UserLookupControllerOppTeams.deleteDefaultTeamViaFlow';

  // Schema
  import NAME_FIELD from '@salesforce/schema/User.Name';
  import OPP_OWNER from '@salesforce/schema/Opportunity.OwnerId';

  // UI + platform
  import LightningAlert from 'lightning/alert';
  import LightningConfirm from 'lightning/confirm';
  import { ShowToastEvent } from 'lightning/platformShowToastEvent';
  import { CloseActionScreenEvent } from 'lightning/actions';
  import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';

  // Apex: lookups & metadata
  import searchUsers from '@salesforce/apex/UserLookupControllerOppTeams.searchUsers';
  import getOpportunityTeamRoles from '@salesforce/apex/UserLookupControllerOppTeams.getOpportunityTeamRoles';

  // Apex: reads
  import getOpportunityTeamMembers from '@salesforce/apex/UserLookupControllerOppTeams.getOpportunityTeamMembers';
  import getDefaultOppTeam from '@salesforce/apex/UserLookupControllerOppTeams.getDefaultOppTeam';

  // Apex: writes
  import upsertOppTeamMembers from '@salesforce/apex/UserLookupControllerOppTeams.upsertOppTeamMembers';
  import saveDefaultOppTeam from '@salesforce/apex/UserLookupControllerOppTeams.saveDefaultOppTeam';
  import deleteOppTeamMember from '@salesforce/apex/UserLookupControllerOppTeams.deleteOppTeamMember';

  // Façades + diagnostics
  import removeDefaultMemberEverywhere from '@salesforce/apex/UserLookupControllerOppTeams.removeDefaultMemberEverywhere';
  import removeDefaultMemberEverywhereVerbose from '@salesforce/apex/UserLookupControllerOppTeams.removeDefaultMemberEverywhereVerbose';

  export default class DefaultOppTeamAddMembers extends LightningElement {
    @track rows = [];
    @track searchQuery = '';
    @track searchResults = [];
    searchTimer = null;
    searchDelayMs = 300;

    hasLoaded = false;
    @api recordId;

    userName;
    _initialized = false;

    @api ownerUserId;
    @track autoAdd = true;
    @track updateOpenOpps = true;
    @track ownerContextUserId;
    deletedUserIds = new Set();

    roleOptions = [{ label: '--None--', value: '' }];
    userTypeOptions = [{ label: 'User', value: 'User' }];
    accessOptions = [
      { label: 'Read Only', value: 'Read' },
      { label: 'Read/Write', value: 'Edit' }
    ];

    @wire(getOpportunityTeamRoles)
    wiredTeamRoles({ data, error }) {
      if (error) {
        this.roleOptions = [{ label: '--None--', value: '' }];
        // eslint-disable-next-line no-console
        console.error('getOpportunityTeamRoles error', error);
        return;
      }
      if (Array.isArray(data) && data.length) {
        this.roleOptions = [{ label: '--None--', value: '' }].concat(
          data.map(v => ({ label: v, value: v }))
        );
      } else {
        this.roleOptions = [{ label: '--None--', value: '' }];
      }
    }

    // Keep only a single declaration of this token near your fields:
    _searchSeq = 0;

    // Debounce
    scheduleSearch() {
      if (this.searchTimer) clearTimeout(this.searchTimer);
      this.hasSearched = false;
      this.searchTimer = setTimeout(() => {
        try { this.runSearch(); } catch (e) { /* eslint-disable-next-line no-console */ console.error('runSearch throw', e); }
        this.searchTimer = null;
      }, this.searchDelayMs);
    }

    // Runner
    async runSearch() {
      const q = this.searchQuery || '';
      this.hasSearched = false;

      if (q.length < 2) {
        this.isSearching = false;
        this.searchResults = [];
        return;
      }

      const mySeq = ++this._searchSeq;
      this.isSearching = true;

      try {
        const res = await searchUsers({ q, limitSize: 7 });
        if (mySeq !== this._searchSeq) return;

        this.searchResults = Array.isArray(res)
          ? res.map(u => {
              const title = u?.Title || '';
              const dept  = u?.Department || '';
              return {
                Id: u?.Id,
                Name: u?.Name,
                Username: u?.Username || '',
                Title: title,
                Department: dept,
                SmallPhotoUrl: u?.SmallPhotoUrl || '',
                hasTitle: !!title,
                hasDept: !!dept,
                hasTitleAndDept: !!(title && dept),
                hasTitleOrDept: !!(title || dept)
              };
            })
          : [];
      } catch (e) {
        // eslint-disable-next-line no-console
        console.error('searchUsers error:', e);
        if (mySeq === this._searchSeq) {
          this.searchResults = [];
          const msg = e?.body?.message || e?.message || 'Search failed.';
          this.showToast('Search error', msg, 'warning');
        }
      } finally {
        if (mySeq === this._searchSeq) {
          this.isSearching = false;
          this.hasSearched = true;
        }
      }
    }

    // Busy flag (keeps Save button from double-clicks and supports disabled={isBusy})
    isBusy = false;

    // Expose a "save" alias so either onclick={save} or onclick={handleSave} will work
    @api
    save(evt) {
      return this.handleSave(evt);
    }

    // ---------- Wires ----------
    @wire(getRecord, { recordId: '$recordId', fields: [OPP_OWNER] })
    wiredOpp({ data }) {
      if (!data) return;
      const oppOwnerId = getFieldValue(data, OPP_OWNER);
      if (oppOwnerId && oppOwnerId !== this.ownerContextUserId) {
        this.ownerContextUserId = oppOwnerId;
        this.preloadDefaults(oppOwnerId);
        if (this.isOpportunityContext) this.preloadForOpportunity(this.recordId);
        this.hasLoaded = true;
      }
    }

    // ---- dropdown visibility helpers + getter ----
    get hasSearchResults() {
      return Array.isArray(this.searchResults) && this.searchResults.length > 0;
    }

    setActiveRow(uid) {
      if (!uid) return;
      const src = Array.isArray(this.rows) ? this.rows : [];
      this.rows = src.map(r => (r ? { ...r, showResults: String(r.uid) === String(uid) } : r));
    }

    clearActiveRow() {
      const src = Array.isArray(this.rows) ? this.rows : [];
      this.rows = src.map(r => (r ? { ...r, showResults: false } : r));
    }

    // Global error hooks to prevent platform modal
    connectedCallback() {
      if (this._initialized) return;
      this._initialized = true;

      const fallbackUser = this.recordId && String(this.recordId).startsWith('005') ? this.recordId : USER_ID;
      this.ownerContextUserId = this.ownerUserId || fallbackUser;
      if (this.ownerContextUserId && String(this.ownerContextUserId).startsWith('005')) {
        this.preloadDefaults(this.ownerContextUserId);
        this.hasLoaded = true;
      }

      // traps
      this._onWindowError = (msg, src, line, col, err) => {
        // eslint-disable-next-line no-console
        console.error('Window error:', msg, src, line, col, err);
        return true;
      };
      this._onUnhandledRejection = (evt) => {
        // eslint-disable-next-line no-console
        console.error('Unhandled rejection:', evt?.reason);
        evt.preventDefault();
      };
      try { window.addEventListener('error', this._onWindowError); } catch {}
      try { window.addEventListener('unhandledrejection', this._onUnhandledRejection); } catch {}
    }

    disconnectedCallback() {
      try { window.removeEventListener('error', this._onWindowError); } catch {}
      try { window.removeEventListener('unhandledrejection', this._onUnhandledRejection); } catch {}
    }

    // Small helper: only set state when connected, and wrap in try/catch
    safeSetState(mutatorFn) {
      if (!this.isConnected || typeof mutatorFn !== 'function') return;
      try { mutatorFn(); } catch (e) { /* eslint-disable-next-line no-console */ console.error('setState error', e); }
    }

    // ---------- Helpers ----------
    get isOpportunityContext() {
      return this.recordId && String(this.recordId).startsWith('006');
    }
    get isReady() {
      return !!(this.ownerContextUserId && String(this.ownerContextUserId).startsWith('005'));
    }
    get minCharsMet() {
      const q = this.searchQuery || '';
      return q.length >= 2;
    }
    makeNewRow(idx) {
      return {
        uid: 'row_' + idx,
        userType: 'User',
        userId: null,
        userName: '',
        access: 'Read',
        role: null,
        markForDelete: false,
        showResults: false
      };
    }
    getUidFromEvent(e) {
      const el = e?.currentTarget || e?.target;
      const uid = el?.dataset?.uid;
      return uid != null ? String(uid) : '';
    }
    updateRow(uid, updaterFn) {
      if (!uid || typeof updaterFn !== 'function') return;
      const src = Array.isArray(this.rows) ? this.rows : [];
      const uidStr = String(uid);
      const nextRows = [];
      for (let i = 0; i < src.length; i++) {
        const r = src[i];
        if (!r) continue;
        if (String(r.uid) === uidStr) {
          const updated = { ...r };
          try { updaterFn(updated); } catch {}
          nextRows.push(updated);
        } else {
          nextRows.push(r);
        }
      }
      this.rows = nextRows;
    }
    showToast(title, message, variant = 'info') {
      const safe = ['success', 'info', 'warning', 'error'].includes(variant) ? variant : 'info';
      this.dispatchEvent(new ShowToastEvent({ title, message, variant: safe, mode: 'dismissable' }));
    }
    normalizeAccess(accessLabel) {
      if (!accessLabel) return null;
      const s = String(accessLabel).trim();
      if (s === 'Read' || s === 'Read Only') return 'Read';
      if (s === 'Edit' || s === 'Read/Write') return 'Edit';
      return null;
    }

    // ---------- Preload ----------
    async preloadForOpportunity(opportunityId) {
      try {
        if (!opportunityId || !String(opportunityId).startsWith('006')) {
          this.seedEmptyRows();
          return [];
        }

        const list = await getOpportunityTeamMembers({ opportunityId });
        const now = Date.now();

        const prefilled = (list || []).map((m, i) => ({
          uid: `row_opp_${now}_${i}`,
          ownerId: m.ownerId,
          oppTeamMemberId: m.oppTeamMemberId,
          userType: 'User',
          userId: m.userId,
          userName: m.userName,
          access: m.access || 'Read',
          role: m.role || null,
          showResults: false,
          markForDelete: false
        }));

        const extras = [];
        const baseCount = Math.max(5, prefilled.length + 2);
        for (let i = prefilled.length; i < baseCount; i++) extras.push(this.makeNewRow(i));

        this.rows = [...prefilled, ...extras];
        return this.rows;
      } catch (e) {
        this.seedEmptyRows();
        return [];
      }
    }

    async preloadDefaults(ownerId) {
      try {
        if (!ownerId || !String(ownerId).startsWith('005')) {
          this.seedEmptyRows();
          return [];
        }

        const list = await getDefaultOppTeam({ ownerUserId: ownerId });
        const now = Date.now();

        const prefilled = (list || []).map((m, i) => ({
          uid: `row_prefill_${now}_${i}`,
          ownerId: m.ownerId,
          defaultTeamMemberId: m.defaultTeamMemberId,
          userType: 'User',
          userId: m.userId,
          userName: m.userName,
          access: m.access || 'Read',
          role: m.role || null,
          showResults: false,
          markForDelete: false
        }));

        const extras = [];
        const baseCount = Math.max(5, prefilled.length + 2);
        for (let i = prefilled.length; i < baseCount; i++) extras.push(this.makeNewRow(i));

        this.rows = [...prefilled, ...extras];
        return this.rows;
      } catch (e) {
        this.seedEmptyRows();
        return [];
      }
    }

    seedEmptyRows() {
      const arr = [];
      for (let i = 0; i < 5; i++) arr.push(this.makeNewRow(i));
      this.rows = arr;
    }

    // Click on a result to pick it for the row
    handlePickUser(e) {
      const el = e?.currentTarget || e?.target;
      let { uid, id, name } = el?.dataset || {};

      if (!uid || !id) {
        let n = e?.target;
        while (n && !(n.dataset && n.dataset.uid && n.dataset.id)) n = n.parentElement;
        if (n && n.dataset) {
          uid = uid || n.dataset.uid;
          id = id || n.dataset.id;
          name = name || n.dataset.name;
        }
      }

      if (!uid || !id) {
        // eslint-disable-next-line no-console
        console.warn('handlePickUser: missing uid or id on dataset', { uid, id, name });
        return;
      }

      this.updateRow(uid, (row) => {
        row.userId = id;
        row.userName = name || row.userName || '';
        row.showResults = false;
      });

      this.searchResults = [];
      this.searchQuery = '';

      if (typeof this.clearActiveRow === 'function') this.clearActiveRow();
    }

    // Keyboard: select on Enter or Space
    handlePickUserKey(e) {
      if (e?.key === 'Enter' || e?.key === ' ') {
        e.preventDefault();
        this.handlePickUser(e);
      }
    }

    // First actual (non-empty) role configured in the org, or null
    getDefaultRoleValue() {
      const found = (this.roleOptions || []).find(o => o && o.value);
      return found ? found.value : null;
    }

    openResultsForRow(e) {
      try {
        const uid = this.getUidFromEvent(e);
        if (!uid) return;
        this.setActiveRow(uid);

        const row = (this.rows || []).find(r => r && String(r.uid) === String(uid));
        this.searchQuery = row ? (row.userName || '') : '';

        if (this.minCharsMet) this.scheduleSearch();
      } catch (err) { /* eslint-disable-next-line no-console */ console.error('openResultsForRow error', err); }
    }

    handleUserNameChange(e) {
      try {
        const uid = this.getUidFromEvent(e);
        if (!uid) return;
        const value = e?.target?.value || '';
        this.updateRow(uid, (row) => { row.userName = value; });
        this.setActiveRow(uid);
        this.searchQuery = value;
        this.scheduleSearch();
      } catch (err) { /* eslint-disable-next-line no-console */ console.error('handleUserNameChange error', err); }
    }

    handleUserNameKeyup(e) {
      try {
        const uid = this.getUidFromEvent(e);
        if (!uid) return;

        const value = e?.target?.value || '';
        this.setActiveRow(uid);
        this.searchQuery = value;
        this.scheduleSearch();

        if (e?.key === 'Enter') {
          const first = (this.searchResults || [])[0];
          if (first && first.Id) {
            const syntheticEvent = { currentTarget: { dataset: { id: first.Id, name: first.Name, uid } } };
            this.handlePickUser(syntheticEvent);
          } else {
            this.showToast('No match', 'Press Enter after choosing a user from the list.', 'info');
          }
        }
      } catch (err) { /* eslint-disable-next-line no-console */ console.error('handleUserNameKeyup error', err); }
    }

    triggerSearchForRow(e) {
      try {
        const uid = this.getUidFromEvent(e);
        if (!uid) return;
        this.setActiveRow(uid);

        let row = null;
        const source = Array.isArray(this.rows) ? this.rows : [];
        for (let i = 0; i < source.length; i++) {
          const r = source[i];
          if (r && String(r.uid) === String(uid)) { row = r; break; }
        }
        this.searchQuery = row ? (row.userName || '') : '';
        this.runSearch();
      } catch (err) { /* eslint-disable-next-line no-console */ console.error('triggerSearchForRow error', err); }
    }

    // ---------- Row management ----------
    handleAddRow() {
      const maxIdx = (this.rows || []).reduce((max, r) => {
        const n = parseInt(String(r?.uid || '').replace('row_', ''), 10);
        return Number.isFinite(n) && n > max ? n : max;
      }, -1);
      const newRow = this.makeNewRow(maxIdx + 1);
      this.rows = [...(this.rows || []), newRow];
    }
  async handleRemoveRow(e) {
    const uid = this.getUidFromEvent(e);
    if (!uid) return;

    const idx = this.findRowIndexByUid(uid);
    if (idx < 0) return;

    const row = this.rows[idx];
    if (row?.userId) {
      this.deletedUserIds.add(row.userId);
    }

    this.removeRowAt(idx);

    this.showToast(
      'Pending deletion',
      'User will be removed when you click Save.',
      'warning'
    );
  }
    // ---------- Delete handler ----------
  /* async handleRemoveRow(e) {
      
      const uid = this.getUidFromEvent(e);
      if (!uid) return;

      const idx = this.findRowIndexByUid(uid);
      if (idx < 0) return;

      const row = (this.rows || [])[idx];
      if (!row) return;

      const pageOwnerId = this.ownerContextUserId || this.ownerUserId || USER_ID;
      if (!pageOwnerId || !String(pageOwnerId).startsWith('005')) {
        this.showToast('Owner not ready', 'Please wait for the owner to load and try again.', 'info');
        return;
      }

      // Empty row: local only
      if (!row.userId) {
        this.removeRowAt(idx);
        this.showToast('Row removed', 'Empty row has been removed.', 'success');
        return;
      }

      // (1) DEFAULT TEAM delete (UTM via Flow) + CASCADE (OTM)
      if (row.defaultTeamMemberId) {
        const confirmed = await LightningConfirm.open({
          message: `Remove ${row.userName} from the Default Opportunity Team AND from all Opportunities owned by this user?`,
          label: 'Confirm deletion',
          variant: 'default'
        });
        if (!confirmed) return;

        const targetOwnerId = (row.ownerId && String(row.ownerId).startsWith('005')) ? row.ownerId : pageOwnerId;

        const snapshot = { row: { ...row }, index: idx };
        this.removeRowAt(idx);

        try {
          // 1) UTM delete via Flow (from Apex wrapper)
          try {
            await deleteDefaultTeamViaFlow({ ownerUserId: targetOwnerId, memberUserId: row.userId });
          } catch (flowErr) {
            // If Flow deletion blocked by org rules, continue with OTM cascade
            this.showToast('Default Team delete warning', (flowErr?.body?.message || flowErr?.message || 'Flow delete did not complete. Proceeding with Opportunity cascade only.'), 'warning');
          }

          // 2) Cascade OTM delete
          const deletedCount = await removeDefaultMemberEverywhere({
            ownerUserId: targetOwnerId,
            memberUserId: row.userId
          });

          if ((deletedCount || 0) > 0) {
            this.showToast(
              'Removed',
              `${row.userName} removed from Default Team and from ${deletedCount} opportunity team row(s).`,
              'success'
            );
          } else {
            this.showToast(
              'No changes on Opportunities',
              'Default step done (if Flow succeeded). No Opp team entries were removed (none found, or permissions/validations blocked).',
              'warning'
            );
          }
          return;
        } catch (error) {
          this.insertRowAt(snapshot.index, snapshot.row);
          const msg = error?.body?.message || error?.message || 'Could not remove from Default Team / Opportunities.';
          this.showToast('Error', msg, 'error');
          return;
        }
      }

      // (2) SINGLE OPPORTUNITY delete (just this row)
      if (row.oppTeamMemberId) {
        const confirmed = await LightningConfirm.open({
          message: `Remove ${row.userName} from this Opportunity Team?`,
          label: 'Confirm deletion',
          variant: 'default'
        });
        if (!confirmed) return;

        const snapshot = { row: { ...row }, index: idx };
        this.removeRowAt(idx);

        try {
          await deleteOppTeamMember({ memberId: row.oppTeamMemberId });
          this.showToast('Removed', `${row.userName} removed from this Opportunity Team.`, 'success');
          return;
        } catch (error) {
          this.insertRowAt(snapshot.index, snapshot.row);
          const msg = error?.body?.message || error?.message || 'Could not remove from this Opportunity.';
          this.showToast('Error', msg, 'error');
          return;
        }
      }

      // (3) OWNER-WIDE OTM delete only
      const confirmed = await LightningConfirm.open({
        message: `Remove ${row.userName} from all Opportunities owned by this user?`,
        label: 'Confirm deletion',
        variant: 'default'
      });
      if (!confirmed) return;

      const snapshot = { row: { ...row }, index: idx };
      this.removeRowAt(idx);

      try {
        const targetOwnerId = (row.ownerId && String(row.ownerId).startsWith('005')) ? row.ownerId : pageOwnerId;

        const deleted = await removeDefaultMemberEverywhere({
          ownerUserId: targetOwnerId,
          memberUserId: row.userId
        });

        if ((deleted || 0) > 0) {
          this.showToast('Removed', `${row.userName} removed from ${deleted} opportunity team row(s).`, 'success');
        } else {
          this.showToast(
            'No changes on Opportunities',
            'No team entries were removed (none on  Opportunities for this owner, or org rules prevented deletion).',
            'warning'
          );
        }
      } catch (error) {
        this.insertRowAt(snapshot.index, snapshot.row);
        const msg = error?.body?.message || error?.message || 'Could not remove from  Opportunities.';
        this.showToast('Error', msg, 'error');
      }
    }
  */
    // ---------- Save ----------
  /*
  async handleSave(event) {
    try { event?.preventDefault(); } catch {}

    // visible progress
    this.isBusy = true;
    this.showToast('Saving…', 'Updating Default Team and Opportunity Teams. Please wait.', 'info');

    // 1) Validate owner
    const ownerId = this.ownerContextUserId || this.ownerUserId || USER_ID;
    if (!ownerId || !String(ownerId).startsWith('005')) {
      this.showToast('Missing Owner', 'Owner must be a User Id (prefix 005).', 'warning');
      this.isBusy = false;
      return;
    }

    // 2) Gather touched rows (must have userId)
    const touched = (this.rows || []).filter(r => !!r?.userId);
    if (touched.length === 0) {
      this.showToast('No team rows', 'Pick at least one user before saving.', 'warning');
      this.isBusy = false;
      return;
    }

    // 3) Roles — compute default; block only if org has no roles at all and any row is missing a role
    const firstRoleOpt = (this.roleOptions || []).find(o => o && o.value);
    const defaultRole = firstRoleOpt ? firstRoleOpt.value : null;
    const orgHasAnyRole = !!defaultRole;
    if (!orgHasAnyRole && touched.some(r => !r.role)) {
      this.showToast(
        'Team Roles not configured',
        'No Team Roles are available. Add at least one Team Role in Setup → Opportunity Team Settings → Team Roles.',
        'warning'
      );
      this.isBusy = false;
      return;
    }

    try {
      // 4) Default Team save — SEQUENTIAL via Apex wrapper (Flow underneath)
      let anyFailed = false;

      for (const r of touched) {
        const role   = r.role || defaultRole || null;
        const access = this.normalizeAccess(r.access) || 'Read';

        try {
          const newId = await upsertDefaultTeamViaFlow({
            ownerUserId: ownerId,
            memberUserId: r.userId,
            role,
            access
          });

          this.updateRow(r.uid, (row) => {
            if (newId) row.defaultTeamMemberId = newId;
            row.saveError = null;
          });
        } catch (err) {
          anyFailed = true;
          const msg = err?.body?.message || err?.message || 'Could not save this team member.';
          this.updateRow(r.uid, (row) => { row.saveError = msg; });
          this.showToast('Row failed', `${r.userName || r.userId}: ${msg}`, 'error');
          // If you prefer to stop at first failure, uncomment the next line:
          // break;
        }
      }

      if (anyFailed) {
        this.isBusy = false;
        return; // let the user correct rows and re-save
      }

      // 5) Build payloads for Opportunity Team push (unchanged)
      const rowsRaw = touched.map((r) => ({
        userId: r.userId,
        role: r.role || defaultRole || null,
        access: this.normalizeAccess(r.access) || 'Read',
        markForDelete: false
      }));

      const singleOppRows = touched.map((r) => ({
        defaultTeamMemberId: r.defaultTeamMemberId || null,
        userId: r.userId,
        userName: r.userName || '',
        role: r.role || defaultRole || null,
        access: this.normalizeAccess(r.access) || 'Read'
      }));

      // 6) Push to Opportunity Team(s) (unchanged)
      if (this.recordId && String(this.recordId).startsWith('006')) {
        await upsertOppTeamMembers({ opportunityId: this.recordId, rows: singleOppRows });
        this.showToast('Saved', 'Updated this Opportunity’s team from your default team.', 'success');
      } else {
        await saveDefaultOppTeam({
          ownerUserId: ownerId,
          updateOpenOpps: true,
          rowsRaw: rowsRaw,
          replaceExisting: false,
          replaceDefault: false
        });
        this.showToast('Saved', 'Updated all open Opportunities for this owner.', 'success');
      }

      // 7) Finalize — refresh record UI and close the modal
      await this.confirmAndRefresh('Saved', 'Default team and opportunity teams updated.', 'success');
    } catch (outer) {
      const msg = outer?.body?.message || outer?.message || 'Unexpected error during save.';
      this.showToast('Save failed', msg, 'error');
    } finally {
      this.isBusy = false;
    }
  }
  */
  // ---------- Save (Bulk via Apex loop of Flow.Interview) ----------
  /*async handleSave(event) {
    try { event?.preventDefault(); } catch {}

    // visible progress
    this.isBusy = true;
    this.showToast('Saving…', 'Updating Default Team in bulk and Opportunity Teams. Please wait.', 'info');

    // 1) Validate owner
    const ownerId = this.ownerContextUserId || this.ownerUserId || USER_ID;
    if (!ownerId || !String(ownerId).startsWith('005')) {
      this.showToast('Missing Owner', 'Owner must be a User Id (prefix 005).', 'warning');
      this.isBusy = false;
      return;
    }

    // 2) Gather touched rows (must have userId)
    const touched = (this.rows || []).filter(r => !!r?.userId);
    if (touched.length === 0) {
      this.showToast('No team rows', 'Pick at least one user before saving.', 'warning');
      this.isBusy = false;
      return;
    }

    // 3) Roles — compute default; block only if org has no roles at all and any row is missing a role
    const firstRoleOpt = (this.roleOptions || []).find(o => o && o.value);
    const defaultRole = firstRoleOpt ? firstRoleOpt.value : null;
    const orgHasAnyRole = !!defaultRole;
    if (!orgHasAnyRole && touched.some(r => !r.role)) {
      this.showToast(
        'Team Roles not configured',
        'No Team Roles are available. Add at least one Team Role in Setup → Opportunity Team Settings → Team Roles.',
        'warning'
      );
      this.isBusy = false;
      return;
    }

    try {
      // 4) Build parallel arrays
      const memberUserIds = touched.map(r => r.userId);
      const roles    = touched.map(r => (r.role || defaultRole || ''));
      const accesses = touched.map(r => (this.normalizeAccess(r.access) || 'Read'));

      // 5) ONE Apex call; Apex runs N flow interviews (no LWC flow host, no UI timing issues)
      const res = await bulkUpsertDefaultTeamViaFlowInterviews({
        ownerUserId: ownerId,
        memberUserIds,
        roles,
        accesses,
        defaultRole,
        defaultAccess: 'Read'
      });

      const idByUserId    = res?.idByUserId    || {};
      const errorByUserId = res?.errorByUserId || {};
      const errKeys = Object.keys(errorByUserId);

      // Apply per-row results
      for (const r of touched) {
        const err = errorByUserId[r.userId];
        const newId = idByUserId[r.userId];
        if (err) {
          this.updateRow(r.uid, (row) => { row.saveError = err; });
        } else {
          this.updateRow(r.uid, (row) => { if (newId) row.defaultTeamMemberId = newId; row.saveError = null; });
        }
      }

      if (errKeys.length) {
        this.showToast('Some rows failed', `${errKeys.length} row(s) could not be saved.`, 'warning');
        // If you prefer strict all-or-nothing, bail here:
        // this.isBusy = false; return;
      }

      // 6) Build payloads for OTM push (unchanged)
      const rowsRaw = touched.map((r) => ({
        userId: r.userId,
        role: r.role || defaultRole || null,
        access: this.normalizeAccess(r.access) || 'Read',
        markForDelete: false
      }));

      const singleOppRows = touched.map((r) => ({
        defaultTeamMemberId: r.defaultTeamMemberId || null,
        userId: r.userId,
        userName: r.userName || '',
        role: r.role || defaultRole || null,
        access: this.normalizeAccess(r.access) || 'Read'
      }));

      // 7) Push to Opportunity Team(s)
      if (this.recordId && String(this.recordId).startsWith('006')) {
        await upsertOppTeamMembers({ opportunityId: this.recordId, rows: singleOppRows });
        this.showToast('Saved', 'Updated this Opportunity’s team from your default team.', 'success');
      } else {
        await saveDefaultOppTeam({
          ownerUserId: ownerId,
          updateOpenOpps: true,
          rowsRaw: rowsRaw,
          replaceExisting: false,
          replaceDefault: false
        });
        this.showToast('Saved', 'Updated all open Opportunities for this owner.', 'success');
      }
  // 6.1) (Optional) Quote & Account sync from the same action
  try {
    const res = await syncQuoteAndAccountFacade({
      req: {
        // If this LWC is opened **on an Opportunity**, pass it; else null
        opportunityId: this.isOpportunityContext ? this.recordId : null,

        // If you have an existing Account (from page context), pass it; else allow service to create
        accountId:     this.contextAccountId,       // set earlier when loading page (optional)
        accountName:   this.desiredAccountName,     // from your UI (optional)
        accountPhone:  this.desiredAccountPhone,    // from your UI (optional)

        // Quote: update existing or create new
        quoteId:       this.contextQuoteId,         // if editing an existing quote (optional)
        quoteName:     this.desiredQuoteName,       // optional
        quoteExpiry:   this.desiredQuoteExpiry      // optional (Date)
      }
    });

    if (!res?.success) {
      this.showToast('Quote/Account sync failed', (res?.errors || []).join('; '), 'warning');
    } else {
      this.showToast('Quote & Account', 'Synced successfully.', 'success');
    }
  } catch (syncErr) {
    const msg = syncErr?.body?.message || syncErr?.message || 'Quote/Account sync error.';
    this.showToast('Quote/Account sync failed', msg, 'error');
  }
      // 8) Finalize — refresh visible record + close the modal
      await this.confirmAndRefresh('Saved', 'Default team and opportunity teams updated.', 'success');
    } catch (outer) {
      const msg = outer?.body?.message || outer?.message || 'Unexpected error during bulk save.';
      this.showToast('Save failed', msg, 'error');
    } finally {
      this.isBusy = false;
    }
  }
  */
  // ---------- Save (Bulk via Apex loop of Flow.Interview) ----------
  async handleSave(event) {
    try { event?.preventDefault(); } catch {}

    this.isBusy = true;
    this.showToast('Saving…', 'Updating Default Team in bulk and Opportunity Teams. Please wait.', 'info');

    const ownerId = this.ownerContextUserId || this.ownerUserId || USER_ID;
    if (!ownerId || !String(ownerId).startsWith('005')) {
      this.showToast('Missing Owner', 'Owner must be a User Id (prefix 005).', 'warning');
      this.isBusy = false;
      return;
    }

    const touched = (this.rows || []).filter(r => !!r?.userId);
    if (touched.length === 0) {
      this.showToast('No team rows', 'Pick at least one user before saving.', 'warning');
      this.isBusy = false;
      return;
    }

    const firstRoleOpt = (this.roleOptions || []).find(o => o && o.value);
    const defaultRole = firstRoleOpt ? firstRoleOpt.value : null;
    const orgHasAnyRole = !!defaultRole;

    if (!orgHasAnyRole && touched.some(r => !r.role)) {
      this.showToast(
        'Team Roles not configured',
        'No Team Roles are available. Add at least one Team Role in Setup → Opportunity Team Settings → Team Roles.',
        'warning'
      );
      this.isBusy = false;
      return;
    }

    try {
      const memberUserIds = touched.map(r => r.userId);
      const roles    = touched.map(r => (r.role || defaultRole || ''));
      const accesses = touched.map(r => (this.normalizeAccess(r.access) || 'Read'));

      const res = await bulkUpsertDefaultTeamViaFlowInterviews({
        ownerUserId: ownerId,
        memberUserIds,
        roles,
        accesses,
        defaultRole,
        defaultAccess: 'Read'
      });

      const idByUserId    = res?.idByUserId    || {};
      const errorByUserId = res?.errorByUserId || {};
      const errKeys = Object.keys(errorByUserId);

      for (const r of touched) {
        const err = errorByUserId[r.userId];
        const newId = idByUserId[r.userId];
        if (err) {
          this.updateRow(r.uid, (row) => { row.saveError = err; });
        } else {
          this.updateRow(r.uid, (row) => { if (newId) row.defaultTeamMemberId = newId; row.saveError = null; });
        }
      }

      if (errKeys.length) {
        this.showToast('Some rows failed', `${errKeys.length} row(s) could not be saved.`, 'warning');
      }

      const rowsRaw = touched.map((r) => ({
        userId: r.userId,
        role: r.role || defaultRole || null,
        access: this.normalizeAccess(r.access) || 'Read',
        markForDelete: false
      }));

      const singleOppRows = touched.map((r) => ({
        defaultTeamMemberId: r.defaultTeamMemberId || null,
        userId: r.userId,
        userName: r.userName || '',
        role: r.role || defaultRole || null,
        access: this.normalizeAccess(r.access) || 'Read'
      }));

  /*   if (this.recordId && String(this.recordId).startsWith('006')) {
        await upsertOppTeamMembers({ opportunityId: this.recordId, rows: singleOppRows });
        this.showToast('Saved', 'Updated this Opportunity’s team from your default team.', 'success');
      } else {
        await saveDefaultOppTeam({
          ownerUserId: ownerId,
          updateOpenOpps: true,
          rowsRaw: rowsRaw,
          replaceExisting: false,
          replaceDefault: false
        });
      // this.showToast('Saved', 'Updated all Opportunities for this owner.', 'success');
      }*/

      //--------------------------------------------------------------
  // 8) FINALIZE (Queueable only for Opp-level sync)
  //--------------------------------------------------------------

  const userLevels = {};
  touched.forEach(r => {
      userLevels[r.userId] = this.normalizeAccess(r.access) || 'Read';
  });
// ✅ APPLY DELETIONS (DEFAULT TEAM + OTM)
if (this.deletedUserIds.size > 0) {
  for (const memberUserId of this.deletedUserIds) {

    // 1️⃣ REMOVE FROM DEFAULT OPPORTUNITY TEAM (CRITICAL)
    await deleteDefaultTeamViaFlow({
      ownerUserId: ownerId,
      memberUserId
    });

    // 2️⃣ REMOVE FROM OPPORTUNITY TEAM(S)
    if (this.isOpportunityContext) {
      await bulkDeleteOppTeamMembersOnOpportunity({
        opportunityId: this.recordId,
        memberUserIds: [memberUserId]
      });
    } else {
      await bulkDeleteOppTeamMembersForOwner({
        ownerUserId: ownerId,
        memberUserIds: [memberUserId]
      });
    }
  }

  this.deletedUserIds.clear();
}

  await runAsyncTeamSync({
      anchorOppId: this.isOpportunityContext ? this.recordId : null,
      ownerUserId: this.ownerContextUserId || this.ownerUserId,
      userToLevel: userLevels
  });

  // Toast for everyone (User page + Opp page)
  this.showToast(
      'Team Update Scheduled',
      'Your changes were saved. Sharing updates are now running in the background.',
      'success'
  );


  setTimeout(() => {
      location.reload();
  }, 3500);

    } catch (outer) {
      const msg = outer?.body?.message || outer?.message || 'Unexpected error during bulk save.';
      this.showToast('Save failed', msg, 'error');
    } finally {
      this.isBusy = false;
    }
  }
    // Close ONLY the modal; do not navigate
  /* close(event) {
      try { event?.preventDefault(); } catch {}
      try { event?.stopPropagation(); } catch {}
      try { this.dispatchEvent(new CloseActionScreenEvent()); } catch {}
      try { this.dispatchEvent(new CustomEvent('close')); } catch {}
    }*/
    close(event) {
    try { event?.preventDefault(); } catch {}
    try { event?.stopPropagation(); } catch {}

    // 1️⃣ Notify LDS that the record may have changed
    try {
      if (this.recordId) {
        notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
      }
    } catch (e) {
      // swallow safely
    }

    // 2️⃣ Ask the container (record page) to refresh
    try {
      this.dispatchEvent(new RefreshEvent());
    } catch (e) {
      // swallow safely
    }

    // 3️⃣ Close the Quick Action modal
    try {
      this.dispatchEvent(new CloseActionScreenEvent());
    } catch (e) {
      // swallow safely
    }

    // 4️⃣ Optional custom close (if parent listens)
    try {
      this.dispatchEvent(new CustomEvent('close'));
    } catch (e) {
      // swallow safely
    }

    // 5️⃣ ✅ FINAL SAFETY NET — hard refresh
    // Use timeout so modal closes cleanly first
    setTimeout(() => {
      window.location.reload();
    }, 100);
  }

    // Show toast, notify LDS, refresh the record page, then close the modal
    // Show toast, refresh standard UI (incl. related lists), then close the modal
  async confirmAndRefresh(title, message, variant = 'success') {
    // 1) Toast
    this.showToast(title, message, variant);

    // allow toast to render
    await new Promise(r => setTimeout(r, 250));

    // 2) Let LDS know the record changed (helps wired data sources update)
    try {
      if (this.recordId) {
        await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
      }
    } catch (e) {
      // eslint-disable-next-line no-console
      console.warn('notifyRecordUpdateAvailable failed', e);
    }

    // 3) Ask the container to refresh standard UI (related lists, highlights, etc.)
    try {
      this.dispatchEvent(new RefreshEvent());
    } catch (e) {
      // eslint-disable-next-line no-console
      console.warn('RefreshEvent dispatch failed', e);
    }

    // brief microtask; lets the container schedule refresh
    await Promise.resolve();

    // 4) Optionally also tell the record page to refresh its wire cache
    // (kept for completeness; most times RefreshEvent is enough)
    try {
      if (this.recordId) {
        // If you still have getRecordNotifyChange imported, remove it and keep notifyRecordUpdateAvailable above.
        // getRecordNotifyChange is deprecated in favor of notifyRecordUpdateAvailable. [3](https://developer.salesforce.com/docs/platform/lwc/guide/reference-get-record-notify.html)
      }
    } catch (e) {}

    // 5) Close the Quick Action panel and emit a custom 'close' if you use it
    try { this.dispatchEvent(new CloseActionScreenEvent()); } catch {}
    try { this.dispatchEvent(new CustomEvent('close')); } catch {}
  }
    findRowIndexByUid(uid) {
      const arr = Array.isArray(this.rows) ? this.rows : [];
      return arr.findIndex((r) => r && String(r.uid) === String(uid));
    }

    removeRowAt(index) {
      const arr = Array.isArray(this.rows) ? [...this.rows] : [];
      if (index >= 0 && index < arr.length) {
        const [removed] = arr.splice(index, 1);
        this.rows = arr;
        return removed;
      }
      return null;
    }

    insertRowAt(index, row) {
      if (!row) return;
      const arr = Array.isArray(this.rows) ? [...this.rows] : [];
      const i = Math.max(0, Math.min(index, arr.length));
      arr.splice(i, 0, row);
      this.rows = arr;
    }

    // Team Role change (combobox)
    handleRoleChange(e) {
      try {
        const uid = this.getUidFromEvent(e);
        if (!uid) return;

        const value = e?.detail?.value ?? null;
        this.updateRow(uid, (row) => {
          row.role = value;
          row.saveError = null;
        });
      } catch (err) {
        // eslint-disable-next-line no-console
        console.error('handleRoleChange error', err);
      }
    }

    // Opportunity Access change (combobox)
    handleAccessChange(e) {
      try {
        const uid = this.getUidFromEvent(e);
        if (!uid) return;

        const raw = e?.detail?.value ?? null; // 'Read' or 'Edit'
        const access = this.normalizeAccess(raw) || 'Read';

        this.updateRow(uid, (row) => {
          row.access = access;
          row.saveError = null;
        });
      } catch (err) {
        // eslint-disable-next-line no-console
        console.error('handleAccessChange error', err);
      }
    }
    // ---------- Bulk Delete (OTM only; pure Apex, no Flow) ----------
  async handleBulkDeleteSelected(event) {
    try { event?.preventDefault(); } catch {}

    // Collect rows to delete: you can also change this to "selected === true" etc.
    const candidates = (this.rows || []).filter(r => !!r?.userId && r.markForDelete === true);
    if (candidates.length === 0) {
      this.showToast('Nothing to delete', 'Mark one or more rows for deletion and try again.', 'info');
      return;
    }

    // Owner & context
    const ownerId = this.ownerContextUserId || this.ownerUserId || USER_ID;
    if (!ownerId || !String(ownerId).startsWith('005')) {
      this.showToast('Missing Owner', 'Owner must be a User Id (prefix 005).', 'warning');
      return;
    }

    // Confirm
    const names = candidates.map(r => r.userName || r.userId).slice(0, 4).join(', ');
    const more  = candidates.length > 4 ? `, +${candidates.length - 4} more` : '';
    const confirmed = await LightningConfirm.open({
      message: `Remove these member(s) from Opportunity Teams${this.isOpportunityContext ? ' (this Opportunity)' : ' (all Opportunities)'}: ${names}${more}?`,
      label: 'Confirm bulk deletion',
      variant: 'destructive'
    });
    if (!confirmed) return;

    this.isBusy = true;
    this.showToast('Deleting…', 'Removing members from Opportunity Teams. Please wait.', 'info');

    try {
      const memberUserIds = candidates.map(r => r.userId);

      // Choose the correct Apex based on context
      let result;
      if (this.recordId && String(this.recordId).startsWith('006')) {
        // Single-Opportunity bulk delete
        result = await bulkDeleteOppTeamMembersOnOpportunity({
          opportunityId: this.recordId,
          memberUserIds
        });
      } else {
        // Owner-wide bulk delete across open Opps
        result = await bulkDeleteOppTeamMembersForOwner({
          ownerUserId: ownerId,
          memberUserIds
        });
      }

      // Result structure:
      //  - totalDeleted      : Integer
      //  - deletedByUserId   : { [userId]: count }
      //  - errorByUserId     : { [userId]: firstErrorText }
      //  - firstErrors       : [ errorText ... ] (up to 10)
      const totalDeleted    = result?.totalDeleted || 0;
      const errorByUserId   = result?.errorByUserId || {};
      const errorUserIds    = Object.keys(errorByUserId);

      // Update UI rows:
      for (const r of candidates) {
        if (errorByUserId[r.userId]) {
          // Keep in grid; show per-row error and clear the mark
          this.updateRow(r.uid, (row) => { row.saveError = errorByUserId[r.userId]; row.markForDelete = false; });
        } else {
          // Remove the row locally, or just clear mark if you prefer to keep the row visible
          const idx = this.findRowIndexByUid(r.uid);
          if (idx >= 0) this.removeRowAt(idx);
        }
      }

      // Toast summary
      if (errorUserIds.length === 0) {
        this.showToast('Removed', `Deleted ${totalDeleted} opportunity team row(s).`, 'success');
      } else {
        this.showToast(
          'Partially removed',
          `Deleted ${totalDeleted} row(s). ${errorUserIds.length} user(s) had errors (hover rows to see details).`,
          'warning'
        );
      }

      // Optional: refresh current record UI & close modal
      await this.confirmAndRefresh('Updated', 'Opportunity Teams updated.', 'success');
    } catch (outer) {
      const msg = outer?.body?.message || outer?.message || 'Unexpected error during bulk delete.';
      this.showToast('Bulk delete failed', msg, 'error');
    } finally {
      this.isBusy = false;
    }
  }

  }