import { LightningElement, api } from 'lwc';

export default class Pmc_dh_progressBarTracker extends LightningElement {
  @api steps = [];
  @api isStepperText;
  get stepClasses() {
    let activeStepIndex = -1;
    const classes = this.steps.map((step, index) => {
      if (step.complete) {
        activeStepIndex = index;
      }
      let styles = '';
      if (this.isStepperText) {
        styles = step.complete ? 'stepper__link stepper__link--active' : 'stepper__link stepper__text';
      } else {
        styles = step.complete ? 'stepper__link stepper__link--active' : 'stepper__link';
      }
      return {
        title: step.title,
        class: styles
      };
    });
    if (activeStepIndex > 0) {
      classes[activeStepIndex - 1].status = 'done';
    }  
    if (activeStepIndex > 1) {
      classes[activeStepIndex - 2].status = 'done';
    } 
    if (activeStepIndex >= 0 && activeStepIndex < classes.length) {
      classes[activeStepIndex].status = 'active';
    }  
    return classes;
  }

  /**
   * Lifecycle Hook
   */
  renderedCallback() {
    if (window.innerWidth < 768) {
      this.template.querySelectorAll('.stepper__link').forEach(el=>{
        el.style.minWidth = 92/this.steps.length + 'vw';
      })
    }
  }
  
}