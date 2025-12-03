import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getGlobalPicklistValues from '@salesforce/apex/AddMilestoneController.getGlobalPicklistValues';
import getMilesStone from '@salesforce/apex/AddMilestoneController.getMilesStone';
import { NavigationMixin } from 'lightning/navigation';
import getAssessmentMaster from '@salesforce/apex/AddMilestoneController.getAssessmentMaster';
import getDescisionCriteria from '@salesforce/apex/AddMilestoneController.getDescisionCriteria';
import saveMilestone from '@salesforce/apex/AddMilestoneController.saveMilestone';
import saveAssessment from '@salesforce/apex/AddMilestoneController.saveAssessment';
import saveDecision from '@salesforce/apex/AddMilestoneController.saveDecision';



export default class AddMilestoneToOpportunity extends NavigationMixin(LightningElement) {
    @api recordId;
    @track showSpinner = false;

    picklistOptions = [];
    error;
    selectedProdCategory = '';
    @track mileStoneList = [];
    @track mileStoneId = [];

    @wire(getGlobalPicklistValues)
    wiredPicklist({ data, error }) {
        if (data) {
            this.picklistOptions = data;
        } else if (error) {
            this.error = error;
        }
    }



    connectedCallback() {
        console.log('recordId-->', this.recordId);

    }
    handleChange(event) {
        this.selectedProdCategory = event.target.value;
        console.log('selectedProdCategory-->', this.selectedProdCategory);
        this.getMileStoneData(this.selectedProdCategory);
    }

    getMileStoneData(group) {
        this.showSpinner = true;

        this.mileStoneList = [];
        this.mileStoneId = [];
        getMilesStone({ category: group }).then(result => {
            this.showSpinner = false;
            if (result.length > 0) {
                result.forEach((ele, index) => {
                    this.mileStoneId.push(ele.Id);
                    let temp = {
                        index: index,
                        isOpen: false,
                        Id: ele.Id,
                        
                        Name: ele.Name,
                        Milestone_Code: ele.Milestone_Code__c,
                        Milestone_Sequence: ele.Milestone_Sequence__c,
                        Product_Group: ele.Product_Group__c,
                        Milestone_Description: ele.Milestone_Description__c,
                        Assessment_Master: [],
                        Decision_Criteria_Master: [],

                    }
                    this.mileStoneList.push(temp);
                });
                console.log('result-->', JSON.stringify(this.mileStoneList));

            } else {
                this.showSuccessToast('Error', 'Error', 'There are no milestone added for this product category yet.');
            }

        })
    }

    hanldeOpenChild(event) {
        console.log('event-->', event.target.dataset.id);
        let mileId = event.target.dataset.id;
        let index = event.target.dataset.index;
        let check = this.mileStoneList[index].isOpen;
        console.log('check-->', check);
        if (check) {
            this.mileStoneList[index].isOpen = false;
        } else {
            this.mileStoneList[index].isOpen = true;
            this.getAssessment(index, mileId);
            this.getDescision(index, mileId);
        }
    }

    getAssessment(index, mileId) {
        getAssessmentMaster({ mileStoneId: mileId }).then(result => {
            let data = []
            if (result.length > 0) {
                result.forEach((ele, index) => {
                    let temp = {
                        index: index,
                        Id: ele.Id,
                        Name: ele.Name,
                        Question_Type: ele.Question_Type__c,
                        Assessment_Question: ele.Assessment_Question__c,
                        Criteria_Measure: ele.Criteria_Measure__c,
                        Assessment_Remarks: ele.Assessment_Remarks__c,
                        msg: ''
                    }
                    data.push(temp);
                })
            } else {
                let temp = {
                    msg: 'There are no Assessment Master added for this milestone yet.'
                }
                data.push(temp);
            }
            this.mileStoneList[index].Assessment_Master = data;
            console.log('-->', JSON.stringify(this.mileStoneList[index].Assessment_Master));

        })
    }

    getDescision(index, mileId) {
        getDescisionCriteria({ mileStoneId: mileId }).then(result => {
            let data = []
            if (result.length > 0) {
                result.forEach((ele, index) => {
                    let temp = {
                        index: index,
                        Id: ele.Id,
                        Name: ele.Name,
                        Question: ele.Question__c,
                        Decision: ele.Decision__c,
                        msg: ''
                    }
                    data.push(temp);
                })
            } else {
                let temp = {
                    msg: 'There are no Decision Criteria Master added for this milestone yet.'
                }
                data.push(temp);
            }
            this.mileStoneList[index].Decision_Criteria_Master = data;
            console.log('-->', JSON.stringify(this.mileStoneList[index].Decision_Criteria_Master));
        })
    }

    showSuccessToast(title, vari, message) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: vari,
        });
        this.dispatchEvent(evt);
    }

    handleMileStoneSave() {
        console.log('selected mile stone-->',this.mileStoneList.length);
        
            if(this.mileStoneList.length > 0){
                console.log('Indside if save called');
            saveMilestone({ optyId: this.recordId, js: JSON.stringify(this.mileStoneList) }).then(result => {
                    console.log('result-->', result);
                    if (result.message == 'success') {
                        this.showSuccessToast('success', 'Success', 'Milestone Master Created Successfully !!!');
                        this.handleAssessmentSave();
                    } else {
                        this.showSuccessToast('Error', 'error', result.message);
                    }
            })
            }else  if(this.mileStoneList.length == 0){
                console.log('Indside else');
                
                 this.showSuccessToast('Error', 'Error', 'Please Select Milestone Master');
            }
    }



    handleAssessmentSave() {

        saveAssessment({ optyId: this.recordId, mId: JSON.stringify(this.mileStoneId) }).then(result => {
            console.log('result-->', result);
            if (result.message == 'success') {
                this.showSuccessToast('success', 'Success', 'Record Created Successfully !!!');
                this.handleDescisionSave();
            } else {
                this.showSuccessToast('Error', 'error', result.message);
            }
        })


    }


    handleDescisionSave() {
        saveDecision({ optyId: this.recordId, mId: JSON.stringify(this.mileStoneId) }).then(result => {
            console.log('result-->', result);
            if (result.message == 'success') {
                this.showSuccessToast('success', 'Success', 'Decision Criteria Master Created Successfully !!!');
                this.handleCancel();

                setTimeout(() => {
                    window.location.reload();
                }, 1000);
            } else {
                this.showSuccessToast('Error', 'error', result.message);
            }
        })


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