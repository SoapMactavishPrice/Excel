import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';

import saveAnswer from '@salesforce/apex/AddDecisionCriteriaMaster.saveAnswer';
import isFetchdata from '@salesforce/apex/AddDecisionCriteriaMaster.isFetchdata';
import getPicklistValues from '@salesforce/apex/AddDecisionCriteriaMaster.getPicklistValues';

export default class AddDecisionCriteriaMaster extends NavigationMixin(LightningElement) {
    @api recordId;

   
    @track tempIndex = 0;
    @track addAnswer = [
        {
            index: this.tempIndex,
            Assessment_Score: '',
            Question: '',
            Decision__c: '',
            decRole:'',
            decUser:'',
        }
    ];



    connectedCallback() {
        this.getExisting();
    }

    @track existAnswer = new Set();
    getExisting() {
        isFetchdata({ recordId: this.recordId }).then(result => {
            console.log('result-->', result);
            result.forEach(element => {
                // Assuming element.Name is the property you want to add to the Set
                const name = element.Name;

                // Adding the name to the Set (duplicates are automatically avoided)
                this.existAnswer.add(name);
            });
        })
    }

    @track questionTypeOptions = [];
    

    // Wire to get picklist values for Question_Type__c field
    @wire(getPicklistValues, { objectName: 'Decision_Criteria_Master__c', fieldName: 'Decision__c' })
    wiredPicklistValues({ error, data }) {
        if (data) {
            this.questionTypeOptions = data.map(option => ({
                label: option.label,
                value: option.value
            }));
        } else if (error) {
            this.showToast('Error', 'Failed to fetch picklist values', 'error');
        }
    }

    addAnswerItem() {
        this.tempIndex = this.tempIndex + 1;
        const newAnswer = {
            index: this.tempIndex,
            Assessment_Score: '',
            Question: '',
            Decision__c: '',
            decRole:'',
            decUser:'',
        };
        this.addAnswer.push(newAnswer);// = [...this.addAnswer, newAnswer];  // Add new item to array
        // Increment index for next item
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
        console.log('label-->', label);
        console.log('index--->', index);
        console.log('value-->', event.target.value);

        this.addAnswer[index][label] = event.target.value;

        // if(label=='Assessment_Score'){
        //    // this.existAnswer.add(event.target.value);
        // }
    }

    save() {
        let isValidate = !this.addAnswer.some(ele =>
            ele.Assessment_Score == null || ele.Assessment_Score == '' || ele.Assessment_Score == undefined ||
            ele.decRole == null || ele.decRole == '' || ele.decRole == undefined ||
            ele.decUser == null || ele.decUser == '' || ele.decUser == undefined
           
        );

        if (isValidate) {
            let isDupliacte = this.validateAnswers();
            if (isDupliacte) {
                saveAnswer({ Id: this.recordId, JS: JSON.stringify(this.addAnswer) }).then(result => {
                    console.log('result-->', result);
                    if (result.message == 'success') {
                        this.showSuccess('success', 'Record Created Successfully !!!', 'Success');
                        this.handleCancel();

                        setTimeout(() => {
                            window.location.reload();
                        }, 1000);
                    } else {
                        this.showSuccess('Error', result.error, 'error');
                    }
                })
            }
        } else {
            this.showSuccess('Error', 'Please Fill Valid Decision Criteria Sequence', 'Error');
        }
    }


    validateAnswers() {
        console.log('JSON-->', this.existAnswer);
        let duplicateFound = true;
        this.addAnswer.forEach(element => {
            let name = element.Assessment_Score;

            if (this.existAnswer.has(name)) {
                duplicateFound = false;  // Set flag to true if a duplicate is found

                this.showSuccess('Error', 'Decision Criteria Sequence Already Exist ' + name, 'Error');
            }

            if ([...this.addAnswer].filter(ele => ele.Assessment_Score === name).length > 1) {
                duplicateFound = false;  // Set flag to true if a duplicate is found within `this.addAnswer`
                this.showSuccess('Error', 'Duplicate Decision Criteria Sequence Found : ' + name, 'Error');
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