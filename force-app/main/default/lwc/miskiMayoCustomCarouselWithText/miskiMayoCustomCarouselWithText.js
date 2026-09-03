import { LightningElement, api } from 'lwc';
import CAROUSEL_IMAGES_PART_A from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartA';
import CAROUSEL_IMAGES_PART_A1 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartA1';
import CAROUSEL_IMAGES_PART_B from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartB';
import CAROUSEL_IMAGES_PART_C from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartC';
import CAROUSEL_IMAGES_PART_D from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartD';
import CAROUSEL_IMAGES_PART_E from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartE';
import CAROUSEL_IMAGES_PART_F from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartF';
import CAROUSEL_IMAGES_PART_F1 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartF1';
import CAROUSEL_IMAGES_PART_G from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartG';
import CAROUSEL_IMAGES_PART_G2 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartG2';
import CAROUSEL_IMAGES_PART_H from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartH';
import CAROUSEL_IMAGES_PART_H1 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartH1';
import CAROUSEL_IMAGES_PART_I from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartI';
import CAROUSEL_IMAGES_PART_J from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartJ';
import CAROUSEL_IMAGES_PART_K from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartK';
import CAROUSEL_IMAGES_PART_L from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartL';
import CAROUSEL_IMAGES_PART_M from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartM';
import CAROUSEL_IMAGES_PART_N from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartN';
import CAROUSEL_IMAGES_PART_N1 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartN1';
import CAROUSEL_IMAGES_PART_O1 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartO1';
import CAROUSEL_IMAGES_PART_O2 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartO2';
import CAROUSEL_IMAGES_PART_P1 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP1';
import CAROUSEL_IMAGES_PART_P2 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP2';
import CAROUSEL_IMAGES_PART_P3 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP3';
import CAROUSEL_IMAGES_PART_P4 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP4';
import CAROUSEL_IMAGES_PART_P5 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP5';
import CAROUSEL_IMAGES_PART_P6 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP6';
import CAROUSEL_IMAGES_PART_P7 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP7';
import CAROUSEL_IMAGES_PART_P8 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP8';
import CAROUSEL_IMAGES_PART_P9 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP9';
import CAROUSEL_IMAGES_PART_P10 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP10';
import CAROUSEL_IMAGES_PART_P11 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP11';
import CAROUSEL_IMAGES_PART_P12 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP12';
import CAROUSEL_IMAGES_PART_P13 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP13';
import CAROUSEL_IMAGES_PART_P14 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP14';
import CAROUSEL_IMAGES_PART_P15 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP15';
import CAROUSEL_IMAGES_PART_P16 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP16';
import CAROUSEL_IMAGES_PART_P17 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP17';
import CAROUSEL_IMAGES_PART_P18 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP18';
import CAROUSEL_IMAGES_PART_P19 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP19';
import CAROUSEL_IMAGES_PART_P20 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP20';
import CAROUSEL_IMAGES_PART_P21 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP21';
import CAROUSEL_IMAGES_PART_P22 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP22';
import CAROUSEL_IMAGES_PART_P23 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP23';
import CAROUSEL_IMAGES_PART_P24 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP24';
import CAROUSEL_IMAGES_PART_P25 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP25';
import CAROUSEL_IMAGES_PART_P26 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP26';
import CAROUSEL_IMAGES_PART_P27 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP27';
import CAROUSEL_IMAGES_PART_P28 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP28';
import CAROUSEL_IMAGES_PART_P29 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP29';
import CAROUSEL_IMAGES_PART_P30 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP30';
import CAROUSEL_IMAGES_PART_P31 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP31';
import CAROUSEL_IMAGES_PART_P32 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP32';
import CAROUSEL_IMAGES_PART_P33 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP33';
import CAROUSEL_IMAGES_PART_P34 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP34';
import CAROUSEL_IMAGES_PART_P35 from '@salesforce/resourceUrl/miskiMayoCustomCarouselWithTextPartP35';

const CARD_VISIBLE_CLASSES = 'fade slds-show';
const CARD_HIDDEN_CLASSES = 'fade slds-hide';
const DOT_VISIBLE_CLASSES = 'dot active';
const DOT_HIDDEN_CLASSES = 'dot';
const DEFAULT_SLIDER_TIMER = 9000;
const DEFAULT_SLIDER_WIDTH = 700;

export default class MiskiMayoCustomCarouselWithText extends LightningElement {
    slides = [];
    slides2 = [];
    slideIndex = 1;
    timer;
    textTimeout;

    @api pageName;
    @api textDescription;
    @api imageOne;
    @api imageTwo;
    @api imageThree;
    @api imageFour;
    @api imageFive;
    @api imageSix;
    @api imageSeven;
    @api imageEight;
    @api imageNine;
    @api imageTen;

    slideTimer = DEFAULT_SLIDER_TIMER;
    enableAutoScroll = true;
    customWidth = DEFAULT_SLIDER_WIDTH;
    showFull = true;

    get maxWidth() {
        return this.showFull ? `width:100%` : `width:${Number(this.customWidth)}px`;
    }

    connectedCallback() {
        this.initSlides();
        if (this.enableAutoScroll) {
            this.startAutoScroll();
        }
        this.showTextWithDelay();
    }

    disconnectedCallback() {
        if (this.enableAutoScroll) {
            window.clearInterval(this.timer);
        }
        if (this.textTimeout) {
            clearTimeout(this.textTimeout);
        }
    }

    initSlides() {
        const description = this.textDescription || '';
        const images = this.buildImageList();
        const staticResource = this.getCarouselResource();

        this.slides = images.map((fileName, index) => {
            return index === 0
                ? {
                      image: staticResource + fileName,
                      heading: description,
                      slideIndex: index + 1,
                      cardClasses: CARD_VISIBLE_CLASSES,
                      dotClases: DOT_VISIBLE_CLASSES,
                      showText: false
                  }
                : {
                      image: staticResource + fileName,
                      heading: description,
                      slideIndex: index + 1,
                      cardClasses: CARD_HIDDEN_CLASSES,
                      dotClases: DOT_HIDDEN_CLASSES,
                      showText: false
                  };
        });
    }

    startAutoScroll() {
        this.timer = window.setInterval(() => {
            this.slideSelectionHandler(this.slideIndex + 1);
        }, Number(this.slideTimer));
    }

    showTextWithDelay() {
        if (this.textTimeout) {
            clearTimeout(this.textTimeout);
        }
        this.textTimeout = setTimeout(() => {
            this.slides = this.slides.map((item) => {
                return this.slideIndex === item.slideIndex
                    ? { ...item, showText: true }
                    : { ...item, showText: false };
            });
        }, 1000);
    }

    currentSlide(event) {
        let slideIndex = Number(event.target.dataset.id);
        this.slideSelectionHandler(slideIndex);
    }

    backSlide() {
        let slideIndex = this.slideIndex - 1;
        this.slideSelectionHandler(slideIndex);
    }

    forwardSlide() {
        let slideIndex = this.slideIndex + 1;
        this.slideSelectionHandler(slideIndex);
    }

    slideSelectionHandler(id) {
        if (this.textTimeout) {
            clearTimeout(this.textTimeout);
        }

        if (id > this.slides.length) {
            this.slideIndex = 1;
        } else if (id < 1) {
            this.slideIndex = this.slides.length;
        } else {
            this.slideIndex = id;
        }

        this.slides = this.slides.map((item) => {
            return this.slideIndex === item.slideIndex
                ? { ...item, cardClasses: CARD_VISIBLE_CLASSES, dotClases: DOT_VISIBLE_CLASSES, showText: false }
                : { ...item, cardClasses: CARD_HIDDEN_CLASSES, dotClases: DOT_HIDDEN_CLASSES, showText: false };
        });

        this.showTextWithDelay();
    }

    buildImageList() {
        const imageKeys = [
            'imageOne','imageTwo','imageThree','imageFour','imageFive',
            'imageSix','imageSeven','imageEight','imageNine','imageTen'
        ];

        const images = [];
        imageKeys.forEach((key) => {
            const value = this[key];
            const isValidString = typeof value === 'string' && /^\d+$/.test(value);
            const numericValue = parseInt(value, 10);

            if (isValidString && numericValue >= 1 && numericValue <= 100) {
                images.push(`/photo${value}.jpg`);
            }
        });
        return images;
    }

    getCarouselResource() {
        switch (this.pageName) {
            case 'pageA':  return CAROUSEL_IMAGES_PART_A;
            case 'pageA1': return CAROUSEL_IMAGES_PART_A1;
            case 'pageB':  return CAROUSEL_IMAGES_PART_B;
            case 'pageC':  return CAROUSEL_IMAGES_PART_C;
            case 'pageD':  return CAROUSEL_IMAGES_PART_D;
            case 'pageE':  return CAROUSEL_IMAGES_PART_E;
            case 'pageF':  return CAROUSEL_IMAGES_PART_F;
            case 'pageF1': return CAROUSEL_IMAGES_PART_F1;
            case 'pageG':  return CAROUSEL_IMAGES_PART_G;
            case 'pageG2': return CAROUSEL_IMAGES_PART_G2;
            case 'pageH':  return CAROUSEL_IMAGES_PART_H;
            case 'pageH1': return CAROUSEL_IMAGES_PART_H1;
            case 'pageI':  return CAROUSEL_IMAGES_PART_I;
            case 'pageJ':  return CAROUSEL_IMAGES_PART_J;
            case 'pageK':  return CAROUSEL_IMAGES_PART_K;
            case 'pageL':  return CAROUSEL_IMAGES_PART_L;
            case 'pageM':  return CAROUSEL_IMAGES_PART_M;
            case 'pageN':  return CAROUSEL_IMAGES_PART_N;
            case 'pageN1': return CAROUSEL_IMAGES_PART_N1;
            case 'pageO1': return CAROUSEL_IMAGES_PART_O1;
            case 'pageO2': return CAROUSEL_IMAGES_PART_O2;
            case 'pageP1': return CAROUSEL_IMAGES_PART_P1;
            case 'pageP2': return CAROUSEL_IMAGES_PART_P2;
            case 'pageP3': return CAROUSEL_IMAGES_PART_P3;
            case 'pageP4': return CAROUSEL_IMAGES_PART_P4;
            case 'pageP5': return CAROUSEL_IMAGES_PART_P5;
            case 'pageP6': return CAROUSEL_IMAGES_PART_P6;
            case 'pageP7': return CAROUSEL_IMAGES_PART_P7;
            case 'pageP8': return CAROUSEL_IMAGES_PART_P8;
            case 'pageP9': return CAROUSEL_IMAGES_PART_P9;
            case 'pageP10': return CAROUSEL_IMAGES_PART_P10;
            case 'pageP11': return CAROUSEL_IMAGES_PART_P11;
            case 'pageP12': return CAROUSEL_IMAGES_PART_P12;
            case 'pageP13': return CAROUSEL_IMAGES_PART_P13;
            case 'pageP14': return CAROUSEL_IMAGES_PART_P14;
            case 'pageP15': return CAROUSEL_IMAGES_PART_P15;
            case 'pageP16': return CAROUSEL_IMAGES_PART_P16;
            case 'pageP17': return CAROUSEL_IMAGES_PART_P17;
            case 'pageP18': return CAROUSEL_IMAGES_PART_P18;
            case 'pageP19': return CAROUSEL_IMAGES_PART_P19;
            case 'pageP20': return CAROUSEL_IMAGES_PART_P20;
            case 'pageP21': return CAROUSEL_IMAGES_PART_P21;
            case 'pageP22': return CAROUSEL_IMAGES_PART_P22;
            case 'pageP23': return CAROUSEL_IMAGES_PART_P23;
            case 'pageP24': return CAROUSEL_IMAGES_PART_P24;
            case 'pageP25': return CAROUSEL_IMAGES_PART_P25;
            case 'pageP26': return CAROUSEL_IMAGES_PART_P26;
            case 'pageP27': return CAROUSEL_IMAGES_PART_P27;
            case 'pageP28': return CAROUSEL_IMAGES_PART_P28;
            case 'pageP29': return CAROUSEL_IMAGES_PART_P29;
            case 'pageP30': return CAROUSEL_IMAGES_PART_P30;
            case 'pageP31': return CAROUSEL_IMAGES_PART_P31;
            case 'pageP32': return CAROUSEL_IMAGES_PART_P32;
            case 'pageP33': return CAROUSEL_IMAGES_PART_P33;
            case 'pageP34': return CAROUSEL_IMAGES_PART_P34;
            case 'pageP35': return CAROUSEL_IMAGES_PART_P35;
            default: return CAROUSEL_IMAGES_PART_P35;
        }
    }
}