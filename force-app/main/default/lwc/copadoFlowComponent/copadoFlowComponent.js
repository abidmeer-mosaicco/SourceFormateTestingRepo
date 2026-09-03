import { LightningElement } from 'lwc';

export default class CopadoFlowComponent extends LightningElement {
    flowSteps = [
        {
            id: 1,
            icon: '📝',
            title: 'Plan',
            description: 'Create User Stories and plan releases inside Copado.'
        },
        {
            id: 2,
            icon: '👨‍💻',
            title: 'Build',
            description: 'Develop in scratch orgs or sandboxes linked to the story.'
        },
        {
            id: 3,
            icon: '📦',
            title: 'Commit',
            description: 'Commit metadata to Git directly from Copado.'
        },
        {
            id: 4,
            icon: '🚀',
            title: 'Promote',
            description: 'Move stories up the pipeline with click-based promotion.'
        },
        {
            id: 5,
            icon: '✅',
            title: 'Deploy',
            description: 'Deploy to production using automated CI/CD flows.'
        }
    ];
}