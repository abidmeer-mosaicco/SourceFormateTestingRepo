import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getAllKnowledgeArticles from '@salesforce/apex/PMC_SS_TechnicalBulletinController.getAllKnowledgeArticles';

export default class Pmc_ss_testparentcomponent extends LightningElement {

    slider1Link = '#';
    autoScroll = true;

    @track knowledgeArticles = [];
    @track allKnowledgeArticles = [];
    
    connectedCallback() {
        //this.fetchKnowledgeArticles();
        this.fetchAllKnowledgeArticles();
        }

    fetchAllKnowledgeArticles() {
        getAllKnowledgeArticles().then(result => {
            if(result != undefined) {
                for(var i=0; i<result.length; i++) {
                    if(result[i].publishStatus == 'Online') {
                        this.knowledgeArticles.push(result[i]);
                    }
                }
                this.allKnowledgeArticles = result;
            
            }
        }).catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                  title: "Error in fetching data",
                  message: error.body.message,
                  variant: "error",
                }),
              );
        });
    }

    get sliderData() {
        try{
        var array = [];
        for(var i=0; i<this.knowledgeArticles.length; i++) {
            array.push({
                "image": this.knowledgeArticles[i].imageUrl,
                "link": this.slider1Link,
                "heading": this.knowledgeArticles[i].title,
                "description": this.knowledgeArticles[i].description
            });
        }
        }catch(error){
            console.log('Error',error);
        }
        return array;
    }
}