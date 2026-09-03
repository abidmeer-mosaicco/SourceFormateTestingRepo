import { LightningElement, api, track } from 'lwc';

export default class Pmc_ss_customCarousel extends LightningElement {

    @api autoScroll = false;
    @api customHeight = '75%';
    @api customWidth = '100%';
    @api hideNavigationButtons = false;
    @api hideNavigationDots = false;
    @api hideSlideNumber = false;
    @api hideSlideText = false;
    @api scrollDuration = 5000;

    @api slides = [];
    @api allKnowledgeArticles = [];
    @api searchResult = [];

    @track searchText = '';

    @track hideLeftNavButton = true;
    @track hideRightNavButton = true;

    slideIndex = 1;
    timer;

    get maxWidth() {
        return `width: ${this.customWidth}`;
    }

    get maxHeight() {
        return `height: ${this.customHeight}; width:100%`;
    }

    @api
    get slidesData() {
        return this.slides;
    }

    get slideTitle() {
        if(this.slides.length > 0) {
            if(this.slideIndex >= this.slides.length) {
                return this.slides[this.slides.length - 1].heading;
            }
            else if(this.slideIndex == 1) {
                return this.slides[0].heading;
            }
    
            return this.slides[this.slideIndex - 1].heading;
        }
    }

    get slideDescription() {
        if(this.slides.length > 0) {
            if(this.slideIndex >= this.slides.length) {
                return this.slides[this.slides.length - 1].description;
            }
            else if(this.slideIndex == 1) {
                return this.slides[0].description;
            }
    
            return this.slides[this.slideIndex - 1].description;
        }
    }

    set slidesData(data) {

        this.slides = data.map((slide, i) => {
            if (i === 0) {
                return {
                    ...slide,
                    index: i + 1,
                    slideClass: 'fade slds-show',
                    dotClass: 'dot active'
                };
            }

            return {
                ...slide,
                index: i + 1,
                slideClass: 'fade slds-hide',
                dotClass: 'dot'
            };
        });
    }

    connectedCallback() {
        if (this.autoScroll) {
            this.timer = window.setInterval(() => {
                this.handleSlideSelection(this.slideIndex + 1);
            }, Number(this.scrollDuration));
        }
    }

    handleMouseOver() {
        if (this.autoScroll) {
            window.clearInterval(this.timer);
        }
    }

    handleMouseOut() {
        if (this.autoScroll) {
            this.timer = window.setInterval(() => {
                this.handleSlideSelection(this.slideIndex + 1);
            }, Number(this.scrollDuration));
        }
    }

    disconnectedCallback() {
        if (this.autoScroll) {
            window.clearInterval(this.timer);
        }
    }

    showSlide(event) {
        const slideIndex = Number(event.target.dataset.id);
        console.log('Slide Index --> ' + slideIndex);
        this.handleSlideSelection(slideIndex);
    }

    slideBackward() {
        const slideIndex = this.slideIndex - 1;
        this.handleSlideSelection(slideIndex);
    }

    slideForward() {
        const slideIndex = this.slideIndex + 1;
        this.handleSlideSelection(slideIndex);
    }

    handleSlideSelection(index) {
        if (index > this.slides.length) {
            this.slideIndex = 1;
        } else if (index < 1) {
            this.slideIndex = this.slides.length;
        } else {
            this.slideIndex = index;
        }

        this.slides = this.slides.map((slide) => {
            if (this.slideIndex === slide.index) {
                return {
                    ...slide,
                    slideClass: 'fade slds-show',
                    dotClass: 'dot active'
                };
            }
            return {
                ...slide,
                slideClass: 'fade slds-hide',
                dotClass: 'dot'
            };
        });
    }

    openModal() {
        this.isShowModal = true;
    }

    closeModal() {
        this.isShowModal = false;
    }

    handleSearchText(event) {
        try{
            this.searchText = event.target.value;
            if(this.searchText != '' || this.searchText != null) {
                this.handleSearchClick(event);
            }
        }catch(error){
            //console.log('error ',error);
        }
    }

    handleSearchClick(e) {
        if(this.searchText != '' && this.searchText != undefined && this.searchText != null) {
            let filteredData = this.handleSearch(this.allKnowledgeArticles, this.searchText);
            this.searchResult = filteredData;
        }
        else {
            this.searchResult = this.allKnowledgeArticles;
        }
    }

    handleSearch = (array, searchTerm) => {
        try{
        const filterData = array.filter(article => {
            console.log('Article ',article);
            if((article.description!=null && article.description!=undefined && article.title!=null && article.title!=undefined) && article.description.toUpperCase().includes(searchTerm.toUpperCase()) || article.title.toUpperCase().includes(searchTerm.toUpperCase())) {
                return article;
            }
        });
        return filterData;
        }catch(err){
            console.log('Error ',err);
        }
        
    }
}