import { LightningElement, track, api, wire } from 'lwc';
//import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';
import saveProductInterested from '@salesforce/apex/addProductOnSampleLineItem.saveProductInterested';
//import isFetchdata from '@salesforce/apex/lwcAssessmentAnswerController.isFetchdata';
import getExistingProducts from '@salesforce/apex/addProductOnSampleLineItem.getExistingProducts';



export default class LwcProductIntrestedPage extends NavigationMixin(LightningElement) {
    @api recordId;


    @track currencyCode = '';
    options = [];

    // Wire the Apex method to fetch picklist values


    @track where = '';
    @track Exist = [];
    getExisting() {
        getExistingProducts({ Id: this.recordId }).then(result => {
            console.log('OUTPUT : -->', JSON.stringify(result));
            let data = JSON.parse(JSON.stringify(result));

            this.Exist = data.id;
            // console.log('OUTPUT : length-->', data.Product_Interested.length);
            // let data = data.Product_Interested;
            // if (data.Product_Interested.length > 0) {
            //     this.addAnswer = [];
            //     data.Product_Interested.forEach(ele => {
            //         let temp = {
            //             index: this.tempIndex,
            //             family: '',
            //             prodId: ele.Product__c,
            //             prodName: ele.Product__r ? ele.Product__r.Name : null,
            //             prodCode: ele.Product_Code__c,
            //             volume: ele.Volume_in_Kgs__c,
            //             remark: '',
            //         }
            //         this.addAnswer.push(temp);
            //     })
            // }


            this.where = `'Id NOT IN : '${this.Exist}'`;

        })
    }

    lookupRecord(event) {
        const selectedRecord = event.detail.selectedRecord;
        const index = event.target.dataset.index;
        console.log('event.detail.-->', event.detail.index);

        if (!selectedRecord) {
            console.log("No record selected");
            return;
        }

        // Log the selected record (useful for debugging)
        console.log('called--> ok', event.detail.selectedRecord);

        const selectedCampaign = event.detail;
        // Get the index from dataset

        const key = event.currentTarget.dataset.label;  // Get the field name from dataset
        const pbe = selectedCampaign.selectedRecord;
        console.log('pbe', pbe);
        // PricebookEntry
        if (this.addAnswer && this.addAnswer[index]) {
            // this.addAnswer[index][key] = pbe.Id;  // Update the product ID in the corresponding field
            // this.addAnswer[index].prodName = pbe.Name;  // Update the Pricebook Entry ID
            // this.addAnswer[index].prodCode = pbe.ProductCode;  // Update the price
            this.addAnswer[index] = { ...this.addAnswer[index], prodId: pbe.Id, prodName: pbe.Name, prodCode: pbe.ProductCode, family: pbe.Family };  // This ensures the view updates
            console.log('Updated Field:', index, this.addAnswer[index]);
        } else {
            console.error('Invalid index or fields array');
        }

    }

    @track tempIndex = 0;
    @track addAnswer = [
        {
            index: this.tempIndex,
            family: '',
            prodId: '',
            prodName: '',
            prodCode: '',
            volume: '',
            remark: '',
        }
    ];



    connectedCallback() {
        this.getExisting();
    }


    addAnswerItem() {
        let validate = this.validateData(); // Call validateData to validate the data
        console.log('validate--> Item', validate);

        if (validate) {
            this.tempIndex = this.tempIndex + 1; // Increment tempIndex
            const newAnswer = {
                index: this.tempIndex,
                family: '',
                prodId: '',
                prodName: '',
                prodCode: '',
                volume: '',
                remark: '',
            };

            // Adding the new answer to the top of the array
            this.addAnswer.push(newAnswer); // Use unshift to add at the beginning
            console.log('addAnswer after adding item:', this.addAnswer);
        } else {
            console.log('Validation failed');
        }
    }



    removeAnswer(event) {
        let indexToRemove = event.target.dataset.index;
        console.log('OUTPUT : ', indexToRemove);
        if (this.addAnswer.length > 1) {
            this.addAnswer = this.addAnswer.filter(answer => answer.index != parseInt(indexToRemove, 10));
        }
    }


    showSuccess(title, msg, varinat) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: varinat,
        });
        this.dispatchEvent(evt);

    }

    handleScoreChange(event) {
        let label = event.target.dataset.label;
        let index = event.target.dataset.index;
        this.addAnswer[index][label] = event.target.value;


        if (label == 'prodFamily') {
            this.addAnswer[index] = { ...this.addAnswer[index], prodId: '', prodName: '', prodCode: '' };  // This ensures the view updates
            console.log('family get changed->', JSON.stringify(this.addAnswer));
        }
        /* // this.callResetChildMethod(index);*/

    }


    validateData() {
        let validate = true;
        for (let element of this.addAnswer) {
            console.log('ele--', JSON.stringify(element));

            // if (element.prodFamily === '' || element.prodFamily === undefined || element.prodFamily === 0) {
            //     this.showSuccess('Error', `Please Fill family for Product ${element.prodName}`, 'Error');
            //     console.log('index at family',element.index,' - > ',element.family );
            //     validate = false;
            //     break; // Exit the loop early since validation failed
            // }
            // else

            if (element.prodName === '' || element.prodName === undefined || element.prodName === 0) {
                this.showSuccess('Error', `Please Select Product`, 'Error');
                console.log('index at prodName', element.index);

                validate = false;
                break; // Exit the loop early since validation failed
            }
            else if (element.volume === '' || element.volume === undefined || element.volume === 0) {
                this.showSuccess('Error', `Please Fill Volume in kgs for Product ${element.prodName}`, 'Error');
                console.log('index at volume', element.index);
                validate = false;
                break; // Exit the loop early since validation failed
            }
            // else if (element.price === '' || element.price === undefined || element.price === 0) {
            //     this.showSuccess('Error', `Please Fill Price for Product ${element.prodName}`, 'Error');
            //     console.log('index at price', element.index);
            //     validate = false;
            //     break; // Exit the loop early since validation failed
            // }

        }
        return validate;

    }

    @api
    getChildComponent() {
        return this.template.querySelector('c-look-up-component');
    }

    callResetChildMethod(index) {
        const child = this.getChildComponent();
        console.log('child->', child);

        if (child) {
            child.removeRecordOnLookup(index);  // Call the method in the child
        }
    }


    save() {
        let validate = this.validateData();
        console.log('validate--> inside save', validate);

        if (validate) {
            //let isDupliacte  =this.validateAnswers();
            //if (isDupliacte) {
            saveProductInterested({ Id: this.recordId, JS: JSON.stringify(this.addAnswer) }).then(result => {
                console.log('result-->', result);
                if (result.message == 'success') {
                    this.showSuccess('success', 'Record Created Successfully !!!', 'Success');
                    this.handleCancel();

                    setTimeout(() => {
                        window.location.reload();
                    }, 1000);
                } else {
                    this.showSuccess('Error', result.message, 'error');
                }
            })
        }

    }


    validateAnswers() {
        console.log('JSON-->', this.existAnswer);
        let duplicateFound = true;
        this.addAnswer.forEach(element => {
            let name = element.Assessment_Score;

            if (this.existAnswer.has(name)) {
                duplicateFound = false;  // Set flag to true if a duplicate is found

                this.showSuccess('Error', 'Assesment Answer Score Already Exist ' + name, 'Error');
            }

            if ([...this.addAnswer].filter(ele => ele.Assessment_Score === name).length > 1) {
                duplicateFound = false;  // Set flag to true if a duplicate is found within `this.addAnswer`
                this.showSuccess('Error', 'Duplicate Assessment Answer Score Found : ' + name, 'Error');
            }
        })
        return duplicateFound;
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view',
            },
        });



    }

}