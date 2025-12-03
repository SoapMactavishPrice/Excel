import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';
import saveProductInterested from '@salesforce/apex/NewSampleRequest.saveProductInterested';
//import isFetchdata from '@salesforce/apex/lwcAssessmentAnswerController.isFetchdata';
import getExistingProducts from '@salesforce/apex/NewSampleRequest.getExistingProducts';

export default class NewSampleRequest extends NavigationMixin(LightningElement) {
    @api recordId;

    @track sampleRequest = {
        'Sample_Request_Type': '',
        'New_Customer': '',
        'Sample_Requested_Date': '',
        'Mode_of_Transport': '',
        'Expected_By': '',
        'Use_Lead_Address_for_Sample_Dispatch_To': false,

    };
    @track leadName = '';

    @track isNew = true;
    @track isExist = false;

    handleSampleChange(event) {
        let label = event.target.dataset.label;
        let value = event.target.value;
        this.sampleRequest[label] = value;
        console.log(label, this.sampleRequest[label]);


    }

    handleAddressChange(event) {
        if (event.target.value) {
            this.addAnswer.forEach(ele => {
                ele.address = this.defaultAddress;
            })
        } else {
            this.addAnswer.forEach(ele => {
                ele.address = '';
            })
        }
    }

    handleAddressv2Change(event) {
        if (this.addAnswer && this.addAnswer.length > 0) {
            if (event.target.checked) {
                // Get the address from the first object
                const baseAddress = this.addAnswer[0].address || '';

                // Apply it to all others
                this.addAnswer = this.addAnswer.map((ele, index) => {
                    return {
                        ...ele,
                        address: baseAddress
                    };
                });
            } else {
                // Clear address from all
                this.addAnswer = this.addAnswer.map(ele => {
                    return {
                        ...ele,
                        address: ''
                    };
                });
            }

            console.log('Updated addAnswer:', JSON.stringify(this.addAnswer));
        }
    }



    // if(this.sampleRequest['Sample_Request_Type'].includes('New Product New Customer') || this.sampleRequest['Sample_Request_Type'].includes('Old Product New Customer') ){
    //     this.isNew = true;
    //     this.sampleRequest.New_Customer = this.leadName;
    //     this.Existing_Customer = null;
    //     this.isExist = false;
    // }

    // if(this.sampleRequest['Sample_Request_Type'].includes('New Product Existing Customer') || this.sampleRequest['Sample_Request_Type'].includes('Old Product Existing Customer') ){
    //     this.isNew = false;
    //     this.isExist = true;
    //     this.sampleRequest.New_Customer = '';
    // }

    // if(this.sampleRequest['Sample_Request_Type']==''){
    //     this.isNew = false;
    //     this.isExist = false;
    // }
    //this.isExist = false;
    //this.isNew = true;








    @track currencyCode = '';
    options = [];

    // Wire the Apex method to fetch picklist values


    @track where = '';
    @track Exist = [];
    @track defaultAddress = '';
    @track defaultApprover = '';
    getExisting() {
        getExistingProducts({ Id: this.recordId }).then(result => {

            let data = JSON.parse(result);
            console.log('OUTPUT : -->', data);
            //this.sampleRequest.New_Customer = data.lead.Name;
            this.leadName = data.lead.Name;
            this.defaultAddress = data.lead.Adrress;
            this.defaultApprover = data.lead.Approver;
            this.currencyCode = data.lead.CurrencyISOCode

            this.sampleRequest.New_Customer = data.lead.Name;
            this.sampleRequest.Sample_Request_Type = data.lead.Sample_Request_Type;
            console.log('OUTPUT : ', this.defaultAddress, this.sampleRequest);
            this.Exist = data.id;
            console.log('OUTPUT : length-->', data.Product_Interested.length);
            // let data = data.Product_Interested;
            if (data.Product_Interested.length > 0) {
                this.addAnswer = [];
                data.Product_Interested.forEach(ele => {
                    let temp = {
                        index: this.tempIndex,
                        family: ele.family,
                        prodId: ele.prodId,
                        prodName: ele.prodName,
                        prodCode: ele.prodCode,
                        volume: ele.volume,
                        pbeId: ele.pbeId,
                        New_Product: ele.New_Product,
                        New_Product_Name: ele.New_Product_Name,
                        unitPrice: parseFloat(ele.unitPrice),
                        remark: '',
                        address: '',
                    }
                    this.addAnswer.push(temp);
                    this.tempIndex = this.tempIndex + 1;
                })
            }


            this.where = `'Id NOT IN : '${this.Exist}'`;

        })
    }

    lookupRecord(event) {
        const selectedRecord = event.detail.selectedRecord;
        let eve = event.target.dataset.index;
        let index = this.addAnswer.findIndex(element => element.index == eve);
        //const index = event.target.dataset.index;
        console.log('event.detail.-->', event.detail.index);

        if (!selectedRecord) {
            console.log("No record selected");
            return;
        }

        // Log the selected record (useful for debugging)
        // PricebookEntry
        if (this.addAnswer && this.addAnswer[index]) {
            this.addAnswer[index] = { ...this.addAnswer[index], prodId: selectedRecord.proId, prodName: selectedRecord.Name, unitPrice: selectedRecord.unitPrice, pbeId: selectedRecord.Id, prodCode: selectedRecord.ProductCode, family: selectedRecord.familyField };  // This ensures the view updates
            console.log('Updated Field:', index, this.addAnswer[index]);
        } else {
            console.error('Invalid index or fields array');
        }

    }

    @track generatedIds = new Set();
    generateRandomNum() {
        let randomId;
        do {
            randomId = Math.floor(Math.random() * 9000) + 1000;  // Generates a random number between 1000 and 9999
        } while (this.generatedIds.has(randomId)); // If the number already exists, regenerate

        // Add the randomId to the set of generated ids to avoid duplicates
        this.generatedIds.add(randomId);
        return randomId;

    }



    @track tempIndex = 0;
    @track addAnswer = [
        {
            index: this.generateRandomNum(),
            family: '',
            prodId: '',
            prodName: '',
            address: '',
            prodCode: '',
            New_Product: false,
            New_Product_Name: '',
            volume: 0,
            pbeId: '',
            unitPrice: 0,
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
                index: this.generateRandomNum(),
                family: '',
                prodId: '',
                prodName: '',
                prodCode: '',
                volume: 0,
                New_Product: false,
                New_Product_Name: '',
                address: '',
                pbeId: '',
                unitPrice: 0,
                remark: '',
            };

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

    handleTextInputChange(event) {
        const eve = event.target.dataset.index;
        let index = this.addAnswer.findIndex(element => element.index == eve);

        this.addAnswer[index] = {
            ...this.addAnswer[index],
            New_Product_Name: event.target.value
        };
    }

    handleCheckboxChange(event) {
        //const index = event.target.dataset.index;
        const isChecked = event.target.checked;
        let eve = event.target.dataset.index;

        let index = this.addAnswer.findIndex(element => element.index == eve);
        this.addAnswer[index] = {
            ...this.addAnswer[index],
            New_Product: event.target.checked,
            pbeId: isChecked ? '' : this.addAnswer[index].pbeId,
            prodId: isChecked ? '' : this.addAnswer[index].prodId,
            volume: isChecked ? '' : this.addAnswer[index].volume,
            address: isChecked ? '' : this.addAnswer[index].address,
            unitPrice: isChecked ? 1 : this.addAnswer[index].unitPrice,
            prodCode: isChecked ? '' : this.addAnswer[index].prodCode,
            remarks: isChecked ? '' : this.addAnswer[index].remark,
            New_Product_Name: isChecked ? this.addAnswer[index].New_Product_Name : '',
        };
        // Force UI update
        this.addAnswer = [...this.addAnswer];
    }

    handleScoreChange(event) {
        let label = event.target.dataset.label;
        let eve = event.target.dataset.index;

        let index = this.addAnswer.findIndex(element => element.index == eve);
        this.addAnswer[index][label] = event.target.value;
        console.log('family get changed->', JSON.stringify(this.addAnswer));



    }

    validateSample() {
        let validate = true;
        console.log('this.SampleLine-->', JSON.stringify(this.sampleRequest));

        // Validation for Request_Date
        if (!this.sampleRequest.Sample_Request_Type) {
            this.showSuccess('Error', `Please Fill Sample Request Type`, 'Error');
            validate = false;
        }


        // else if (!this.sampleRequest.New_Customer && (this.sampleRequest.Sample_Request_Type.includes('New Product New Customer') 
        //                          || this.sampleRequest.Sample_Request_Type.includes('Old Product New Customer'))) {
        //     this.showSuccess('Error', `Please Fill New Customer`, 'Error');
        //     validate = false;
        // }
        // Validation for Sample_Sent_To_Plant
        // else if (!this.sampleRequest.Existing_Customer && (this.sampleRequest.Sample_Request_Type.includes('New Product Existing Customer') 
        //     || this.sampleRequest.Sample_Request_Type.includes('Old Product Existing Customer'))) {
        //     this.showSuccess('Error', `Please Fill Existing Customer`, 'Error');
        //     validate = false;
        // }
        // Validation for Follow_Up_Reminder
        else if (!this.sampleRequest.Sample_Requested_Date) {
            this.showSuccess('Error', `Please Fill Sample Requested Date`, 'Error');
            validate = false;
        }

        else if (!this.sampleRequest.Mode_of_Transport) {
            this.showSuccess('Error', `Please Fill Mode of Transport`, 'Error');
            validate = false;
        }

        else if (!this.sampleRequest.Expected_By) {
            this.showSuccess('Error', `Please Fill Expected By`, 'Error');
            validate = false;
        }

        // else if (!this.sampleRequest.Use_Lead_Address_for_Sample_Dispatch_To) {
        //     this.showSuccess('Error', `Please Fill Use Lead Address for Sample Dispatch To`, 'Error');
        //     validate = false;
        // }

        return validate;
    }


    validateData() {
        let validate = true;
        for (let element of this.addAnswer) {
            console.log('ele--', JSON.stringify(element));

            if (!element.New_Product && (element.prodName === '' || element.prodName === undefined || element.prodName === 0)) {
                this.showSuccess('Error', `Please Select Product`, 'Error');
                console.log('index at prodName', element.index);

                validate = false;
                break; // Exit the loop early since validation failed
            }
            else if (element.New_Product && (element.New_Product_Name === '' || element.New_Product_Name === undefined || element.New_Product_Name === 0)) {
                this.showSuccess('Error', `Please add Product`, 'Error');
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

            else if ((Number(element.volume) > 5) && (element.remark == '' || element.remark == undefined || element.remark == null)) {
                this.showSuccess('Error', `Please Fill remarks for Product ${element.prodName || element.New_Product_Name}`, 'Error');
                console.log('index at volume', element.index);
                validate = false;
                break; // Exit the loop early since validation failed
            }


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

    @track showSpinner = false;
    save() {
        let validate = this.validateSample();

        if (validate) {
            validate = this.validateData();
        }
        console.log('validate--> inside save', validate);
        setTimeout(() => {
            if (validate) {
                this.showSpinner = true;
                //let isDupliacte  =this.validateAnswers();
                //if (isDupliacte) {
                saveProductInterested({ Id: this.recordId, sample: JSON.stringify(this.sampleRequest), JS: JSON.stringify(this.addAnswer), defaultApprover: this.defaultApprover }).then(result => {
                    console.log('result-->', result);

                    if (result.message == 'success') {
                        this.showSuccess('success', 'Record Created Successfully !!!', 'Success');
                        this.handleCancel();
                        this.recordId = result.Id;
                        setTimeout(() => {
                            window.location.reload();
                            this.showSpinner = false;
                        }, 1000);
                    } else {
                        this.showSpinner = false;
                        this.showSuccess('Error', result.message, 'error');
                    }

                })
            }
        }, 1000);

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