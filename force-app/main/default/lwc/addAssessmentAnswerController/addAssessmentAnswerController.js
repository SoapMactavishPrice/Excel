import { LightningElement, track, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';
import saveAnswer from '@salesforce/apex/AddAssessmentMasterController.saveAnswer';
import isFetchdata from '@salesforce/apex/AddAssessmentMasterController.isFetchdata';
import getPicklistValues from '@salesforce/apex/AddAssessmentMasterController.getPicklistValues';

export default class AddAssessmentAnswerController extends NavigationMixin(LightningElement) {
   @api recordId;

    // @wire(CurrentPageReference)
    // getStateParameters(currentPageReference) {
    //     if (currentPageReference) {
    //         this.recordId = currentPageReference.state.recordId;
    //         console.log('this.recordId ', this.recordId);
    //     }
    // }

    @track tempIndex = 0;
    @track addAnswer = [
        {
            index: this.tempIndex,
            Assessment_Score: '',
            Assessment_Answer: '',
            Criteria_Measure: '',
            Assessment_Question: '',
            Question_Type: '',
            accessorRole:'',
            accessorRoleUser:'',
            respRole:'',
            respRoleUser:'',
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


    // Wire to get current page reference and extract the recordId
    // @wire(CurrentPageReference)
    // getStateParameters(currentPageReference) {
    //     if (currentPageReference) {
    //         this.recordId = currentPageReference.state.recordId;
    //     }
    // }


    @track accessorRoleOptions = [];
    @track respRoleOptions = [];

    @wire(getPicklistValues, { objectName: 'Assessment_Master__c', fieldName: 'Accessor_Role__c' })
wiredAccessRolePicklistValues({ error, data }) {
    if (data) {
        // Ensure that you are mapping the values correctly
        this.accessorRoleOptions = data.values.map(option => ({
            label: option.label,
            value: option.value
        }));
        console.log('accessorRoleOptions-->', JSON.stringify(this.accessorRoleOptions));
    } else if (error) {
        console.error('Error fetching Accessor Role picklist values', error);
        this.showToast('Error', 'Failed to fetch Accessor Role picklist values', 'error');
    }
}

@wire(getPicklistValues, { objectName: 'Assessment_Master__c', fieldName: 'Responsibility_Role__c' })  // Correct field name
wiredrespRolePicklistValues({ error, data }) {
    if (data) {
        // Ensure that you are mapping the values correctly
        this.respRoleOptions = data.values.map(option => ({
            label: option.label,
            value: option.value
        }));
        console.log('respRoleOptions-->', JSON.stringify(this.respRoleOptions));  // Corrected log
    } else if (error) {
        console.error('Error fetching Responsibility Role picklist values', error);
        this.showToast('Error', 'Failed to fetch Responsibility Role picklist values', 'error');
    }
}

    addAnswerItem() {
        this.tempIndex = this.tempIndex + 1;
        const newAnswer = {
            index: this.tempIndex,
            Assessment_Score: '',
            Assessment_Answer: '',
            Criteria_Measure: '',
            Assessment_Question: '',
            accessorRole:'',
            accessorRoleUser:'',
            respRole:'',
            respRoleUser:'',
           
        };
        this.addAnswer.push(newAnswer);// = [...this.addAnswer, newAnswer];  // Add new item to array
        // Increment index for next item
    }


    removeAnswer(event) {
        //let indexToRemove = event.target.dataset.index;
        /*console.log('OUTPUT : ', indexToRemove);
        if (this.addAnswer.length > 1) {
            this.addAnswer = this.addAnswer.filter(answer => answer.index != parseInt(indexToRemove, 10));
        }*/
        let userKeyToRemove = event.target.dataset.index;
        let indexToRemove = this.addAnswer.findIndex(answer => answer.index == userKeyToRemove);
        console.log('OUTPUT : updated- 001 -> ',indexToRemove);

        if (indexToRemove !== -1) {
            if (this.addAnswer.length > 1) {
                //let temp = event.target.data.userid;
                this.addAnswer = this.addAnswer.filter(answer => answer.index != parseInt(indexToRemove));
                
                this.addAnswer = this.addAnswer.map((user, index) => {
                    user.index = index;
                    //user.srNo = index + 1;
                    return user;
                });
                this.tempIndex = this.addAnswer.length - 1;
            }
        } else {
            console.error('User not found');
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
        //console.log('label-->', label);
        console.log('index--->', index, label);
        //console.log('value-->', event.target.value);

        this.addAnswer[index][label] = event.target.value;
        console.log('value..', this.addAnswer[index][label]);

        // if(label=='Assessment_Score'){
        //    // this.existAnswer.add(event.target.value);
        // }
    }

    save() {
        let isValidate = !this.addAnswer.some(ele =>
            ele.Assessment_Score == null || ele.Assessment_Score == '' || ele.Assessment_Score == undefined
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
            this.showSuccess('Error', 'Please Fill Valid Assessment Score', 'Error');
        }
    }


    validateAnswers() {
        console.log('JSON-->', this.existAnswer);
        let duplicateFound = true;
        this.addAnswer.forEach(element => {
            let name = element.Assessment_Score;

            if (this.existAnswer.has(name)) {
                duplicateFound = false;  // Set flag to true if a duplicate is found

                this.showSuccess('Error', 'Assesment Sequence Score Already Exist ' + name, 'Error');
            }

            if ([...this.addAnswer].filter(ele => ele.Assessment_Score === name).length > 1) {
                duplicateFound = false;  // Set flag to true if a duplicate is found within `this.addAnswer`
                this.showSuccess('Error', 'Duplicate Assessment Sequence Score Found : ' + name, 'Error');
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