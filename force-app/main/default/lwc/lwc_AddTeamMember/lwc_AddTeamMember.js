import { LightningElement, api, track, wire } from 'lwc';
import save from '@salesforce/apex/Lwc_AddTeamMemberController.save';


import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';


export default class Lwc_AddTeamMember extends NavigationMixin(LightningElement) {
    @api recordId;
    @track addedNames = new Set();

    @track keyIndex = 0;
    @track teamMemberDetail = [{
        key: this.keyIndex,
        srNo: this.keyIndex + 1,
        userName: '',
        userRole: '',

    }
    ];

    addTemMember() {
        let validate = this.validateData(); // Call validateData to validate the data
        console.log('validate--> Item', validate);

        if (validate) {
            this.keyIndex = this.keyIndex + 1;
            let temp = {
                key: this.keyIndex,
                srNo: this.keyIndex + 1,
                userName: '',
                userRole: '',

            }
            this.teamMemberDetail.push(temp);
        }
    }


    validateData() {
        let validate = true;
        for (let element of this.teamMemberDetail) {


            if (element.name == '' || element.name == undefined || element.name == null) {
                this.showToast('Error', `Please Select User Name at Sr.No ${element.srNo}`, 'Error');
                validate = false;
                break; // Exit the loop early since validation failed
            }
            else if (element.userRole == '' || element.userRole == undefined || element.userRole == null) {
                this.showToast('Error', `Please Fill Team Member role at Sr.No  ${element.srNo}`, 'Error');
                console.log('index at volume', element.index);
                validate = false;
                break; // Exit the loop early since validation failed
            }

        }
        return validate;

    }


    remove(event) {
        let userKeyToRemove = event.target.dataset.index;
        let indexToRemove = this.teamMemberDetail.findIndex(user => user.key == userKeyToRemove);


        if (indexToRemove !== -1) {
            if (this.teamMemberDetail.length > 0) {
                let temp = event.target.data.userid;
                if (this.addedNames.has(temp)) {
                    this.addedNames.delete(temp);
                }
                this.teamMemberDetail.splice(indexToRemove, 1);
                
                this.teamMemberDetail = this.teamMemberDetail.map((user, index) => {
                    user.key = index;
                    user.srNo = index + 1;
                    return user;
                });
                this.keyIndex = this.teamMemberDetail.length - 1;
            }
        } else {
            console.error('User not found');
        }
    }


    handleUserOnchange(event) {
        let index = event.target.dataset.index;
        let label = event.target.dataset.label;
        if(!this.addedNames.has(event.target.value)){
            this.teamMemberDetail[index][label] = event.target.value;
            this.addedNames.add(event.target.value);
        }else{
            this.teamMemberDetail[index] = {...this.teamMemberDetail[index], name: ''};
            this.showToast('Error', 'Duplicate User Selected h-->', 'Error');
        }

    }

    handleOnchange(event) {
        let index = event.target.dataset.index;
        let label = event.target.dataset.label;
        this.teamMemberDetail[index][label] = event.target.value;
        
    }

    showToast(variant, message, title) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant

        });
        this.dispatchEvent(event);

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

    duplicateUser() {
        this.showToast('Error', 'Duplicate User', 'Error');
    }
    handleSave() {
        let validate = this.validateData(); // Call validateData to validate the data
        console.log('validate--> Item', validate);
        if(validate){
            save({mileId:this.recordId,JS:JSON.stringify(this.teamMemberDetail)})
            .then(result => {
            
                if (result.Message == 'success') {
                    this.showToast('success', 'Record Created Successfully !!!', 'Success');
                    this.handleCancel();

                    setTimeout(() => {
                        window.location.reload();
                    }, 1000);
                } else {
                    this.showSuccess('Error', result.message, 'error');
                }
            })
            
            .catch(error => {   
                this.showToast('Error', error, 'Error');                
            });
        }
    }

}