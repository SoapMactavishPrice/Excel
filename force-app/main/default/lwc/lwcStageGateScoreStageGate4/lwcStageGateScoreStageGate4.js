import { LightningElement, api, track, wire } from 'lwc';
import getAssessmentMaster from '@salesforce/apex/LwcStageGateScoreControllerStage4.getAssessmentMaster';
import getAssessmentAnswer from '@salesforce/apex/LwcStageGateScoreControllerStage4.getAssessmentAnswer';
import getDescisionCriteria from '@salesforce/apex/LwcStageGateScoreControllerStage4.getDescisionCriteria';
import saveData from '@salesforce/apex/LwcStageGateScoreControllerStage4.saveData';
import getDocumentUrl from '@salesforce/apex/LwcStageGateScoreControllerStage4.getDocumentUrl';
import getFiledDisplay from '@salesforce/apex/LwcStageGateScoreControllerStage4.getFiledDisplay';
import deletefile from '@salesforce/apex/LwcStageGateScoreControllerStage3.deletefile';
import USER_ID from '@salesforce/user/Id';  // Importing the logged-in user's ID
import getRecordDetail from '@salesforce/apex/LwcStageGateScoreControllerStage2.getRecordDetail';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
const FIELDS = ['Milestone__c.Final_Outcome__c'];

export default class LwcStageGateScoreStageGate4 extends NavigationMixin(LightningElement) {
    @api recordId;
    @track total = 0;
    @track openDecisionCriteria = false;
    userId = USER_ID;


    // @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    // wiredRecord({ error, data }) {
    //     if (data) {
    //         // Access file_come__c field from the record data
    //         this.total = Number(data.fields.Final_Outcome__c.value);
    //         if(this.total > 0){
    //           this.openDecisionCriteria = true;
    //         }
    //     } else if (error) {
    //         console.error('Error fetching record data:', error);
    //     }
    // }

    @track assData = [];
    @track ansData = [];
    @track decisionData = [];

    @track option = [
        {
            label: 'Go',
            value: 'Go'
        }, {
            label: 'Defer',
            value: 'Defer'
        },
        {
            label: 'Kill',
            value: 'Kill'
        },
    ]

    // get isAnsDataArray() {
    //     return Array.isArray(this.ansData);
    // }

    //         @wire(getDescisionCriteria, { recordId: '$recordId' })
    // wiredDescisionCriteria({ error, data }) {
    //     if (data) {
    //         this.decisionData = data;
    //         this.decisionData = data.map(item => {
    //             // You can set a default value like `null`, `0`, or any other default value
    //             return { ...item, decision: item.Decision__c || '', decision_Rating: item.Decision_Rating__c||'', notes: item.Decision_making_Notes__c ||'' };  // Add Assessment_Answer with default empty string
    //         });

    //     } else if (error) {
    //         console.error('Error fetching assessment master data:', error);
    //     }
    // }



    // // Wire for getAssessmentMaster
    // @wire(getAssessmentMaster, { recordId: '$recordId' })
    // wiredAssessmentMaster({ error, data }) {
    //     if (data) {
    //         this.assData = data;

    //         this.assData = data.map(item => {
    //             let isUserResponsible = item.Responsibilty_User__c === this.userId;
    //             let isAccessor = item.Accessor_User__c === this.userId;
    //             let num = item.Assessment_Answer__r && item.Assessment_Answer__r.Name 
    //         ? Number(item.Assessment_Answer__r.Name) 
    //         : '';  
    //             console.log('-->',isUserResponsible,isAccessor);

    //             return { ...item, Assessment_Answer: num,
    //                 isUserResponsible: isUserResponsible,
    //                 isAccessor: isAccessor
    //              };  // Add Assessment_Answer with default empty string
    //         });

    //     } else if (error) {
    //         console.error('Error fetching assessment master data:', error);
    //     }
    // }


    @track headerData = [];
    @track totalcolspan = 0;
    // Wire for getAssessmentAnswer (assuming it also needs recordId)

    connectedCallback() {
        this.fetchDecisionCriteria();
        this.getAssessment();
    }

    @track selectedValue = '';

    // Define options for the combobox
    get approveroptions() {
        return [
            { label: 'Pending', value: 'Pending' },
            { label: 'Approved', value: 'Approved' },
            { label: 'Reject', value: 'Reject' }
        ];
    }

    // handleChange(event) {
    //     this.selectedValue = event.detail.value;
    // }

    @track ApprovalStatus = '';
    @track isBUHead = false;


    handleRecordFetch() {
        getRecordDetail({ recordId: this.recordId })
            .then(result => {
                this.ceoDecision = result.Overall_Decision_by_CEO__c;
                this.ApprovalStatus = result.BU_Head_Status__c;
                this.selectedValue  = result.BU_Head_Status__c;
                let userId15 =this. userId.substring(0, 15);
                console.log('OUTPUT : --> ',this.ApprovalStatus,result.BU_Head_User__c, this.userId,result.BU_Head_User__c == userId15);
                this.isBUHead = result.BU_Head_User__c == userId15;
            })
            .catch(error => {
                // Error case
                console.error('Error fetching record data:', error);
            });
    }


    @track isValidUser = true;
    fetchDecisionCriteria() {
        getDescisionCriteria({ recordId: this.recordId })
            .then((data) => {
                this.decisionData = data.map(item => {
                    let isDecisionUser = item.Decision_User__c === this.userId;
                    let isDisbaled = item.Decision_User__c != this.userId;
                    return {
                        ...item,
                        decision: item.Decision__c || '',
                        decision_Rating: item.Decision_Rating__c || '',
                        notes: item.Decision_making_Notes__c || '',
                        isDecisonUser: isDecisionUser,
                        isDisbaled: isDisbaled
                    };
                });



                if (this.decisionData.length > 0) {
                    for (let i = 0; i < this.decisionData.length; i++) {
                        console.log(this.decisionData[i].Decision_User__c, this.userId);

                        if (this.decisionData[i].Decision_User__c == this.userId) {
                            this.isValidUser = false;
                            break;
                        }
                    }

                    console.log('this.isValidUser->', this.isValidUser);


                }
                this.fetchAssessmentMaster();
                this.handleRecordFetch();
            })
            .catch((error) => {
                console.error('Error fetching decision criteria:', error);
            });
    }



    fetchAssessmentMaster() {
        getAssessmentMaster({ recordId: this.recordId })
            .then((data) => {
                this.assData = data.map(item => {
                    let isUserResponsible = item.Responsibilty_User__c === this.userId;
                    let isAccessor = item.Accessor_User__c === this.userId;
                    let isDisbaled = item.Accessor_User__c != this.userId;

                    let initials = '';
                    let title = '';
                        if(item.Responsibilty_User__r.Name /*&& isUserResponsible*/){
                        let nameParts = item.Responsibilty_User__r.Name.split(' ');

                        let firstNameInitial = nameParts[0].charAt(0);  // First letter of the first name
                        let lastNameInitial = nameParts[1] ? nameParts[1].charAt(0) : '';  // First letter of the last name, if present
                        initials = firstNameInitial + lastNameInitial;
                        title = item.Responsibilty_User__r.Name;
                        }



                    let num = item.Assessment_Answer__r && item.Assessment_Answer__r.Name
                        ? Number(item.Assessment_Answer__r.Name)
                        : '';
                    console.log('isUserResponsible:', isUserResponsible, 'isAccessor:', isAccessor, 'isDisbaled->', isDisbaled);

                    return {
                        ...item,
                        Assessment_Answer: num,
                        isUserResponsible: isUserResponsible,
                        isAccessor: isAccessor,
                        initials:initials,
                        title:title,
                        isDisbaled: isDisbaled,
                    };


                });

                this.total = this.assData.reduce((sum, item) => sum + Number(item.Assessment_Answer__r.Name || 0), 0);
                console.log('total-->', this.total, this.isValidUser);

                if (this.total >= 15 && !this.isValidUser) {
                    if(this.ApprovalStatus == 'Approved'){
                    this.openDecisionCriteria = true;
                    }
                }

                this.dataReady = true;
            })
            .catch((error) => {
                console.error('Error fetching assessment master data:', error);
            });
    }

    deleteFile(event) {
        let fileIds = event.target.dataset.id;
        deletefile({ prodId: fileIds }).then(result => {
            if (result) {
                this.showToast('Success', `File Deleted Successfully`, 'success');
                this.fileViewdata = this.fileViewdata.filter(file => file.Id !== fileIds);
                if (this.fileViewdata.length == 0) {
                    this.isOpenFileView = false;
                }
            }
        })

    }


    @track uniqueHeaders = new Set();
    @track headerData = []; // Assuming you're storing header labels
    @track tempAnswerData = [];
    getAssessment() {
        getAssessmentAnswer().then(result => {
            console.log(result.length);

            if (result) {
                result.forEach(ele => {
                    let temData = ele.Assessment_Answer__r;


                    temData.forEach(e => {
                        console.log('12--> ', e.Name);
                        let tempLabel = {
                            'label': e.Name
                        };

                        if (!this.uniqueHeaders.has(e.Name)) {
                            this.uniqueHeaders.add(e.Name);  // Add to Set
                            this.headerData.push(tempLabel);   // Push the tempLabel to headerData
                        }
                    });



                })
                this.tempAnswerData = result;
				
				const maxValue = Math.max(...this.uniqueHeaders);
                const minValue = Math.min(...this.uniqueHeaders);

                for (let i = minValue; i <= maxValue; i++) {
                    // Step 3: If the value is not in the Set, add it
                    if (!this.uniqueHeaders.has(i.toString())) {
                        this.uniqueHeaders.add(i.toString());
                        let tempLabel = {
                            'label': i
                        };
                        this.headerData.push(tempLabel);
                    }
                }
				this.totalcolspan = this.headerData.length + 1; // Include extra for other data

                

                console.log('this.uniqueHeaders-->   cfye   --', JSON.stringify(this.headerData));
                console.log('this.uniqueHeaders', this.uniqueHeaders);

                this.headerData = this.headerData.sort((a, b) => parseInt(a.label) - parseInt(b.label));
                this.proceedData(result);
            } else {
                console.error('No data found or Assessment_Answer__r is not an array.');
            }
        }).catch(error => {
            console.error('Error fetching assessment answers:', error);
        });
    }


    sortheaders(data) {
        return data.map(item => {
            item.sort((a, b) => parseInt(a.label) - parseInt(b.label));
            return item;
        });
    }
    sortUniques(data) {
        return [...data].sort((a, b) => parseInt(a) - parseInt(b));

    }



    sortAnswersByScore(data) {
        return data.map(item => {
            item.answers.sort((a, b) => parseInt(a.score) - parseInt(b.score));
            return item;
        });
    }


    proceedData(data) {


        data.forEach((e, index) => {
            const existingMaster = this.ansData.find(item => item.Assessment_Master === e.Name);

            if (existingMaster) {
                return; // Skip this iteration
            }

            let tempChild = {};
            tempChild['index'] = index;
            tempChild['Assessment_Master'] = e.Name;

            // if(e.Assessment_Remarks__c.length > 40 && e.Assessment_Remarks__c !=null && e.Assessment_Remarks__c !=''){
            //     tempChild['remarksShow'] = true;
            //     tempChild['remarks'] = e.Assessment_Remarks__c;
            // }{
            tempChild['remarksShow'] = false;
            tempChild['remarks'] = e.Assessment_Remarks__c;
            // }
            tempChild['answers'] = [];  // Initialize an array to hold the answers

            // Iterate through the 'Assessment_Answer__r' array and push unique answers
            e.Assessment_Answer__r.forEach((ele, index) => {
                if (this.uniqueHeaders.has(ele.Name)) {
                    let temp = {};
                    temp['score'] = ele.Name;
                    temp['index'] = index;

                    if (ele.Assessment_Answer__c.length > 50 && ele.Assessment_Answer__c != undefined && ele.Assessment_Answer__c != null && ele.Assessment_Answer__c != '') {
                        temp['ansShow'] = true;
                        temp['ansSub'] = ele.Assessment_Answer__c.substring(0, 50);
                        temp['ans'] = ele.Assessment_Answer__c;
                    } else if (ele.Assessment_Answer__c != undefined && ele.Assessment_Answer__c != null && ele.Assessment_Answer__c != '') {

                        temp['ansShow'] = false;
                        temp['ansSub'] = ele.Assessment_Answer__c;
                        temp['ans'] = ele.Assessment_Answer__c;
                    }
                    tempChild['answers'].push(temp);  // Add the answer to the 'answers' array
                }
            });

            const missingValueg = [...this.uniqueHeaders].filter(value => !e.Assessment_Answer__r.some(ele => ele.Name === value));
            missingValueg.forEach((missingValue, index) => {
                let temp = {};
                temp['score'] = missingValue;  // Add the missing value (e.g., 2, 4)
                temp['ans'] = '';
                temp['index'] = index;
                temp['ansShow'] = false; // Default message for missing value
                tempChild['answers'].push(temp);  // Add the fallback answer to the 'answers' array
            });

            this.ansData.push(tempChild);

        });

        if (this.ansData.length > 0) {

            this.ansData = this.sortAnswersByScore(this.ansData);
        }
    }


    checkExitingRating(value, assmentName) {
        let tempChecker = false;

        for (let ele of this.tempAnswerData) {
            if (ele.Assessment_Answer__r && ele.Assessment_Answer__r.length > 0, ele.Name == assmentName) {
                let valueExists = ele.Assessment_Answer__r.some(item => item.Name == value);

                if (valueExists) {
                    tempChecker = true;
                    console.log('Value found, exiting loop');
                    break;
                } else {
                    this.showToast('Error', `Rating for Scoring ${value} not found for ${ele.Name}`, 'error');
                    tempChecker = false;
                }
            }
        }

        return tempChecker;
    }

    handleOnchange(event) {
        let index = this.assData.findIndex(item => item.Id == event.target.dataset.id);
        let assmentName = event.target.dataset.name;

        if (index !== -1) {

            const maxValue = Math.max(...this.uniqueHeaders);
            const minValue = Math.min(...this.uniqueHeaders);
            const value = Number(event.target.value);

            if (value <= maxValue && value >= minValue) {
                let validator = this.checkExitingRating(value, assmentName);
                if (validator) {
                    this.assData[index].Assessment_Answer = value;
                    this.total = this.assData.reduce((sum, item) => sum + Number(item.Assessment_Answer || 0), 0);
                    if (this.total >= 15 && !this.isValidUser) {
                        //this.openDecisionCriteria = true;
                    } else {
                        this.openDecisionCriteria = false;
                    }
                    this.assData = [...this.assData];
                }
            } else {
                this.showToast('Error', `Please enter a number between ${minValue} and ${maxValue}`, 'Error');
            }
        }
    }

    @track OpenFileUpload = false;
    @track currentAssessmentId = '';
    handleFileOpenClick(event) {
        this.OpenFileUpload = true;
        let currentId = event.target.dataset.id;
        this.currentAssessmentId = currentId;
    }

    get acceptedFormats() {
        return ['.pdf', '.png'];
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
    }

    closeModal() {
        this.OpenFileUpload = false;
    }

    handleFileChange(event) {
        const file = event.target.files[0]; // Get the selected file
        if (file) {
            this.fileData = file;
        }
    }
    handleOnchangeValue(event) {
        let index = this.decisionData.findIndex(item => item.Id == event.target.dataset.id);
        let name = event.target.dataset.name;
        if (index != -1) {
            let label = event.target.dataset.label;
            this.decisionData[index][label] = event.target.value;
            if ((name.toLowerCase()).includes('overall decision')) {
                this.label = event.target.value;  // Corrected 'value' instead of 'valuel'
            }
        }
    }


    handleOnNoteschangeValue(event) {
        let index = this.decisionData.findIndex(item => item.Id == event.target.dataset.id);
        if (index != -1) {
            let label = event.target.dataset.label;
            this.decisionData[index][label] = event.target.value;
        }
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        })
    }



    validate() {
        let validator = true;

        for (let ele of this.decisionData) {
           

            if (ele.Decision_User__c == this.userId && (ele.decision == '' || ele.decision == null || ele.decision == undefined)) {
                this.showToast('Error', `Please Fill Decision For  ${ele.Name}`, 'error');
                validator = false;
                break;
            }

            if (ele.Decision_User__c == this.userId && (ele.notes == '' || ele.notes == null || ele.notes == undefined)) {
                this.showToast('Error', `Please Fill Decision making - Notes For  ${ele.Name}`, 'error');
                validator = false;
                break;
            }
        }


        return validator;
    }


    @track label = '';
    handleOnDecesionchangeValue(event) {
        this.label = event.target.value;
    }



@track showReason  = false;
    handleChange(event) {
        this.selectedValue = event.detail.value;
        this.showReason = false;
        if(this.selectedValue =='Reject'){
            this.showReason = true;
        }
    }
    
    @track rejectedReson = '';
    handleRejectedChange(event){
        this.rejectedReson = event.target.value;
    }
   


    handleSave() {
        let tempCheck = true;
        if(this.openDecisionCriteria){
        tempCheck = this.validate();
         }


if(this.showReason){
            if(this.rejectedReson =='' || this.rejectedReson ==null || this.rejectedReson == undefined){
                this.showToast('Error','Please Fill Rejection Reason','Error');
                tempCheck = false;
            }
        }

        if (tempCheck) {

            saveData({ JS: JSON.stringify(this.assData), descJs: JSON.stringify(this.decisionData), score: this.total, 
            recordId: this.recordId, label: this.label, approverLabel:this.selectedValue,openDecisionCriteria:this.openDecisionCriteria ,reason:this.rejectedReson}).then(result => {
                if (result.Message && result.Message.startsWith('Success')) {
                    // Extract the value after the underscore
                    const resultId = result.Message.split('_')[1];
                    if (resultId != null && resultId != undefined && resultId != '') {
                        this.recordId = resultId;
                    }
                    this.showToast('Success', `Implement Stage Record Updated successfully.`, 'Success');
                    this.handleCancel();

                    setTimeout(() => {
                        window.location.reload();
                    }, 2000);
                } else {
                    this.showToast('Error', result.Message, 'Error');
                }

            })
        }
    }

    showToast(variant, message, title) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant

        });
        this.dispatchEvent(event);

    }

    @track isOpenFileView = false;


    @track fileViewdata = [];

    previewFile(event) {
        let Name = event.target.dataset.name;
        let id = event.target.dataset.id;

        getFiledDisplay({ prodId: id }).then(data => {
            let result = JSON.parse(data);
            if (result == null) {
                this.showToast('Error', ` File Not found for Assessment Criteria ${Name} `, 'error');
            } else {
                this.fileViewdata = result;
                this.isOpenFileView = true;
            }
        });

    }

    viewFile(event) {
        let fileIds = event.target.dataset.id;
        console.log('fileId', fileIds);
        getDocumentUrl({ Id: fileIds }).then(result => {
            if (result) {
                this[NavigationMixin.Navigate]({
                    type: 'standard__namedPage',
                    attributes: {
                        pageName: 'filePreview'
                    },
                    state: {
                        selectedRecordId: result
                    }
                });
            }
        });
    }


    handleOkay() {
        this.isOpenFileView = false;
    }

}