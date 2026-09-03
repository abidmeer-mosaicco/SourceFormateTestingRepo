import { LightningElement, api, track } from 'lwc';
import CAROUSEL_IMAGES from '@salesforce/resourceUrl/miskiMayoGetToKnowUsCustomThirdCarouselWrapper';
import styleMiskiMayoGetToKnowUsCustomThirdCarouselWrapper from '@salesforce/resourceUrl/styleMiskiMayoGetToKnowUsCustomThirdCarouselWrapper';
import miskiMayoGetToKnowUsCustomThirdCarouselWrapperArrows from "@salesforce/resourceUrl/miskiMayoGetToKnowUsCustomThirdCarouselWrapperArrows";
import { loadStyle } from 'lightning/platformResourceLoader';
import MMGetToKnowUsCustomThirdCarouselWrapperPart1 from "@salesforce/label/c.MMGetToKnowUsCustomThirdCarouselWrapperPart1";
import MMGetToKnowUsCustomThirdCarouselWrapperPart2 from "@salesforce/label/c.MMGetToKnowUsCustomThirdCarouselWrapperPart2";
import MMGetToKnowUsCustomThirdCarouselWrapperPart3 from "@salesforce/label/c.MMGetToKnowUsCustomThirdCarouselWrapperPart3";
import MMGetToKnowUsCustomThirdCarouselWrapperPart4 from "@salesforce/label/c.MMGetToKnowUsCustomThirdCarouselWrapperPart4";
import MMGetToKnowUsCustomThirdCarouselWrapperPart5 from "@salesforce/label/c.MMGetToKnowUsCustomThirdCarouselWrapperPart5";
import MMGetToKnowUsCustomThirdCarouselWrapperPart6 from "@salesforce/label/c.MMGetToKnowUsCustomThirdCarouselWrapperPart6";
import MMGetToKnowUsCustomThirdCarouselWrapperPart7 from "@salesforce/label/c.MMGetToKnowUsCustomThirdCarouselWrapperPart7";
import MMGetToKnowUsCustomThirdCarouselWrapperPart8 from "@salesforce/label/c.MMGetToKnowUsCustomThirdCarouselWrapperPart8";
import MMGetToKnowUsCustomThirdCarouselWrapperPart9 from "@salesforce/label/c.MMGetToKnowUsCustomThirdCarouselWrapperPart9";
import MMGetToKnowUsCustomThirdCarouselWrapperPart10 from "@salesforce/label/c.MMGetToKnowUsCustomThirdCarouselWrapperPart10";
import MMGetToKnowUsCustomThirdCarouselWrapperPart11 from "@salesforce/label/c.MMGetToKnowUsCustomThirdCarouselWrapperPart11";
import MMGetToKnowUsCustomThirdCarouselWrapperPart12 from "@salesforce/label/c.MMGetToKnowUsCustomThirdCarouselWrapperPart12";
import MMGetToKnowUsCustomThirdCarouselWrapperPart13 from "@salesforce/label/c.MMGetToKnowUsCustomThirdCarouselWrapperPart13";
import MMGetToKnowUsCustomThirdCarouselWrapperPart14 from "@salesforce/label/c.MMGetToKnowUsCustomThirdCarouselWrapperPart14";
import MMGetToKnowUsCustomThirdCarouselWrapperPart15 from "@salesforce/label/c.MMGetToKnowUsCustomThirdCarouselWrapperPart15";


export default class MiskiMayoGetToKnowUsCustomThirdCarousel extends LightningElement {
    @track currentStartIndex = 0;
    stylesLoaded = false;
    arrowLeftIcon = miskiMayoGetToKnowUsCustomThirdCarouselWrapperArrows + '/arrow_left.png';
    arrowRightIcon = miskiMayoGetToKnowUsCustomThirdCarouselWrapperArrows + '/arrow_right.png';

    @track labels = {MMGetToKnowUsCustomThirdCarouselWrapperPart1,MMGetToKnowUsCustomThirdCarouselWrapperPart2,MMGetToKnowUsCustomThirdCarouselWrapperPart3,MMGetToKnowUsCustomThirdCarouselWrapperPart4,
        MMGetToKnowUsCustomThirdCarouselWrapperPart5, MMGetToKnowUsCustomThirdCarouselWrapperPart6, MMGetToKnowUsCustomThirdCarouselWrapperPart7, MMGetToKnowUsCustomThirdCarouselWrapperPart8,
        MMGetToKnowUsCustomThirdCarouselWrapperPart9, MMGetToKnowUsCustomThirdCarouselWrapperPart10, MMGetToKnowUsCustomThirdCarouselWrapperPart11, MMGetToKnowUsCustomThirdCarouselWrapperPart12,
        MMGetToKnowUsCustomThirdCarouselWrapperPart13, MMGetToKnowUsCustomThirdCarouselWrapperPart14,MMGetToKnowUsCustomThirdCarouselWrapperPart15};

    slidesData = [
        { image: CAROUSEL_IMAGES + '/photo1.jpg', description: this.labels.MMGetToKnowUsCustomThirdCarouselWrapperPart1},
        { image: CAROUSEL_IMAGES + '/photo2.jpg', description: this.labels.MMGetToKnowUsCustomThirdCarouselWrapperPart2},
        { image: CAROUSEL_IMAGES + '/photo3.jpg', description: this.labels.MMGetToKnowUsCustomThirdCarouselWrapperPart3},
        { image: CAROUSEL_IMAGES + '/photo4.jpg', description: this.labels.MMGetToKnowUsCustomThirdCarouselWrapperPart4},
        { image: CAROUSEL_IMAGES + '/photo5.jpg', description: this.labels.MMGetToKnowUsCustomThirdCarouselWrapperPart5},
        { image: CAROUSEL_IMAGES + '/photo6.jpg', description: this.labels.MMGetToKnowUsCustomThirdCarouselWrapperPart6},
        { image: CAROUSEL_IMAGES + '/photo7.jpg', description: this.labels.MMGetToKnowUsCustomThirdCarouselWrapperPart7},
        { image: CAROUSEL_IMAGES + '/photo8.jpg', description: this.labels.MMGetToKnowUsCustomThirdCarouselWrapperPart8},
        { image: CAROUSEL_IMAGES + '/photo9.jpg', description: this.labels.MMGetToKnowUsCustomThirdCarouselWrapperPart9},
        { image: CAROUSEL_IMAGES + '/photo10.jpg', description: this.labels.MMGetToKnowUsCustomThirdCarouselWrapperPart10},
        { image: CAROUSEL_IMAGES + '/photo11.jpg', description: this.labels.MMGetToKnowUsCustomThirdCarouselWrapperPart11},
        { image: CAROUSEL_IMAGES + '/photo12.jpg', description: this.labels.MMGetToKnowUsCustomThirdCarouselWrapperPart12},
        { image: CAROUSEL_IMAGES + '/photo13.jpg', description: this.labels.MMGetToKnowUsCustomThirdCarouselWrapperPart13},
        { image: CAROUSEL_IMAGES + '/photo14.jpg', description: this.labels.MMGetToKnowUsCustomThirdCarouselWrapperPart14},
        { image: CAROUSEL_IMAGES + '/photo15.jpg', description: this.labels.MMGetToKnowUsCustomThirdCarouselWrapperPart15}
    ];

    get slidesToShow() {
        if (window.innerWidth <= 480) {
            return 1;
        } else if (window.innerWidth <= 1024) {
            return 2;
        } else {
            return 4;
        }
    }
    
    get visibleSlides() {
        return this.slidesData.slice(this.currentStartIndex, this.currentStartIndex + this.slidesToShow);
    }
    

    get trackStyle() {
        return 'display: flex;';
    }

    renderedCallback() {
        if (!this.stylesLoaded) {
            Promise.all([loadStyle(this, styleMiskiMayoGetToKnowUsCustomThirdCarouselWrapper)])
                .then(() => {
                    console.log("Custom styles loaded");
                    this.stylesLoaded = true;
                })
                .catch((error) => {
                    console.error("Error loading custom styles");
                });
        }
    
        window.addEventListener('resize', () => {
            this.currentStartIndex = 0; // Resetar quando redimensionar
            this.requestUpdate && this.requestUpdate(); // forçar update se necessário
        });
    }

    previousSlide() {

        if(this.slidesToShow == 4)
        {
            if (this.currentStartIndex > 0) {
                this.currentStartIndex--;
                return;
            }
    
            if(this.currentStartIndex == 0)
            {
                this.currentStartIndex = 12;
            }
            
        } else
        {
            if (this.currentStartIndex > 0) {
                this.currentStartIndex--;
            } else {
                this.currentStartIndex = this.slidesData.length - this.slidesToShow;
            }

        }
    }
    
    nextSlide() {
        let maxIndex = this.slidesData.length - this.slidesToShow;
        if(this.slidesToShow == 4)
        {
            maxIndex++;
        }
        if (this.currentStartIndex < maxIndex) {
            this.currentStartIndex++;
        } else {
            this.currentStartIndex = 0;
        }
    }
}