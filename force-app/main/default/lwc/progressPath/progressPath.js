import { LightningElement, api } from 'lwc';
import LABEL_PROGRESS_PATH from '@salesforce/label/c.MassUpdate_Progress_Alt_ProgressPath';
import LABEL_COMPLETE from '@salesforce/label/c.MassUpdate_Progress_Alt_Complete';
import LABEL_STAGE_COMPLETE from '@salesforce/label/c.MassUpdate_Progress_Text_StageComplete';
import LABEL_CURRENT_STAGE from '@salesforce/label/c.MassUpdate_Progress_Text_CurrentStage';
import LABEL_PROGRESS from '@salesforce/label/c.MassUpdate_Progress_Badge_Progress';
import LABEL_STAGE from '@salesforce/label/c.MassUpdate_Progress_Text_Stage';

export default class ProgressPath extends LightningElement {
  labels = {
    progressPath: LABEL_PROGRESS_PATH,
    complete: LABEL_COMPLETE,
    stageComplete: LABEL_STAGE_COMPLETE,
    currentStage: LABEL_CURRENT_STAGE,
    progress: LABEL_PROGRESS,
    stage: LABEL_STAGE
  };
  @api stages = [];
  @api showActionArea = false;
  @api showContent = false;

  /**
   * Normalized stage descriptors enriched with classes & accessibility attributes.
   */
  get normalizedStages() {
    return (this.stages || []).map((s) => {
      const isCurrent = Boolean(s.isCurrent);
      const isComplete = Boolean(s.isComplete) && !isCurrent;
      const classes = ['slds-path__item'];

      if (isCurrent) {
        classes.push('slds-is-current', 'slds-is-active');
      } else if (isComplete) {
        classes.push('slds-is-complete');
      } else {
        classes.push('slds-is-incomplete');
      }

      return {
        ...s,
        isCurrent,
        isComplete,
        classList: classes.join(' '),
        ariaSelected: isCurrent ? 'true' : 'false',
        tabIndex: isCurrent ? '0' : '-1'
      };
    });
  }

  get currentStageLabel() {
    const cur = (this.stages || []).find((s) => s.isCurrent);

    if (cur) {
      return cur.label;
    }

    return '';
  }

  /**
   * Fire event when a stage is clicked (navigation is optional for parent).
   */
  handleStageClick(e) {
    e.preventDefault();
    const label = e.currentTarget.dataset.label;
    console.log('progressPath handleStageClick', label);

    if (label) {
      const eventDetail = { name: label, label };
      console.log('Dispatching stageclick event with detail:', eventDetail);
      this.dispatchEvent(new CustomEvent('stageclick', {
        detail: label,
        bubbles: true,
        composed: true
      }));
    }
  }
}