import { LightningElement, track, api, wire } from 'lwc';
//import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';
//import isFetchdata from '@salesforce/apex/lwcAssessmentAnswerController.isFetchdata';
import getProdInterest from '@salesforce/apex/LwcEditProductInterestedController.getProdInterest';
import updateData from '@salesforce/apex/LwcEditProductInterestedController.updateData';


export default class LwcEditProductInterested extends NavigationMixin(LightningElement) {
    @api recordId;
        @track Exist =[]; 
        connectedCallback() {
            this.getProd();
        }

        handleRecordChange(){

        }
    
        getProd(){
            getProdInterest({Id:this.recordId}).then(result=>{
                console.log('result--<>>>---',JSON.stringify(result));

                
            if(result.length> 0){
                result.forEach((ele,index) => {
                    let temp = {
                        index: index,
                        Id : ele.Id,
                        Name : ele.Name,
                        prodId: ele.Product__c,
                        prodCode: ele.Product_Code__c,
                        Expected_Price: ele.Expected_Price__c,
                        Volume_in_Kgs: ele.Volume_in_Kgs__c,
                        Add_In_Opty : ele.Add_In_Opty__c,
                        prodName: ele.Product__r ? ele.Product__r.Name : 'No Product' // Handle related field 'Product__r.Name'

                    }
                    this.Exist.push(temp);
                    
                    
                });
               // console.log('-->',JSON.stringify(this.Exist));
                //this.Exist = result;
            }
            else{ 
                
                this.Exist =[]; 
                //this.setTimeout(() => {
                this.showSuccess('Error', `No Products Interested`, 'Error');
                
                    this.handleCancel();
                //}, 1000);
                
            } 
    })
     }

     handleSelectChange(event){
        let label = event.target.dataset.label;
        let index = event.target.dataset.index;
        this.Exist[index][label] = event.target.checked;  
     }
    
    
        handleScoreChange(event) {
            let label = event.target.dataset.label;
            let index = event.target.dataset.index;
            this.Exist[index][label] = event.target.value;
        }
    
    
        validateData() {
            let validate = true;
            for (let element of this.Exist) {
                
                 if (element.Volume_in_Kgs === '' || element.Volume_in_Kgs === undefined || element.Volume_in_Kgs === 0) {
                    this.showSuccess('Error', `Please Fill Volume in kgs for Product ${element.prodName}`, 'Error');
                    console.log('index at volume',element.index);
                    validate = false;
                    break; // Exit the loop early since validation failed
                }
                else if (element.Expected_Price === '' || element.Expected_Price === undefined || element.Expected_Price === 0) {
                    this.showSuccess('Error', `Please Fill Price for Product ${element.prodName}`, 'Error');
                    console.log('index at price',element.index);
                    validate = false;
                    break; // Exit the loop early since validation failed
                }
    
            }
            return validate;
    
        }
    
    
    
        save() {
            let validate = this.validateData();
        
    
            if (validate) {
                console.log('validate--> inside', validate);
                
                    updateData({ JS: JSON.stringify(this.Exist) }).then(result => {
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

    showSuccess(title, msg, varinat) {
            const evt = new ShowToastEvent({
                title: title,
                message: msg,
                variant: varinat,
            });
            this.dispatchEvent(evt);
    
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