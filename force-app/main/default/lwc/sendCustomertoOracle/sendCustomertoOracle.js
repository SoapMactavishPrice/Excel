import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import sendCustomerData from '@salesforce/apex/CustomerUpsert_ToOracle.sendCustomerData';
import getContactDetail from '@salesforce/apex/SendCustomertoOracle.getContactDetail';
import getAddInfoDetail from '@salesforce/apex/SendCustomertoOracle.getAddInfoDetail';
import getRecordTypeId from '@salesforce/apex/SendCustomertoOracle.getRecordTypeId';
import hasRequiredAddressInfo from '@salesforce/apex/SendCustomertoOracle.hasRequiredAddressInfo';
import getPinCodeDetails from '@salesforce/apex/SendCustomertoOracle.getPinCodeDetails';
import deleteAddressInfo from '@salesforce/apex/SendCustomertoOracle.deleteAddressInfo';
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from 'lightning/refresh';

export default class SendCustomertoOracle extends LightningElement {

	@api recordId;
	@api objectApiName;
	@api salesDocNo;
	@track showSpinner = true;
	@track syncDataResponseFlag = false;
	@track addressInfoList = [];
	@track contactList;
	@track conFirstName;
	@track conLastName;
	@track conMobilePhone;
	@track conEmail;
	@track recTypeName = '';
	@track ResponseMessage = '';
	@track errorResponseMessage = '';

	@track showAddressInfoModal = false;
	@track addressInfoId = '';
	@track recordTypeId = '';
	@track addInfoName = '';
	@track isEditing = false;

	@track addFieldsRerenderFlag = true;
	@track pincodevalue = '';
	@track areavalue = '';
	@track cityvalue = '';
	@track statevalue = '';
	@track countryvalue = '';
	@track areakey;
	@track citykey;
	@track statekey;
	@track countrykey;

	connectedCallback() {
		console.log('IN SendCustomertoOracle ConnectedCallback');

		setTimeout(() => {
			// this.handleCallout();
			console.log(this.recordId);
			this.handlerGetContactDetail();
			this.handlerGetAddInfoDetail();
		}, 2000);
	}

	showToast(toastTitle, toastMsg, toastType) {
		const event = new ShowToastEvent({
			title: toastTitle,
			message: toastMsg,
			variant: toastType,
			mode: "dismissable"
		});
		this.dispatchEvent(event);
	}

	// Send Customer data to Oracle - API
	handleCallout() {
		sendCustomerData({
			accId: this.recordId
		}).then((result) => {
			console.log('result ', result);
			this.showSpinner = false;
			if (result.includes('Error')) {
				this.errorResponseMessage = result;
			} else {
				this.ResponseMessage = result;
			}
			console.log('ResponseMessage', this.ResponseMessage);
			console.log('errorResponseMessage', this.errorResponseMessage);

			// const customEvent = new CustomEvent('getresponsemsg', {
			//     detail: { resmsg: this.ResponseMessage } // Set the parameter in the detail object
			// });
			// this.dispatchEvent(customEvent);

			// history.replaceState(null, document.title, location.href);
		}).catch((error) => {
			console.log('= erorr', error);
			this.showSpinner = false;
		})
	}

	closeModal(event) {
		this.dispatchEvent(new CloseActionScreenEvent());
		this.dispatchEvent(new RefreshEvent());
	}

	handlerGetContactDetail() {
		getContactDetail({
			accId: this.recordId
		}).then((result) => {
			console.log('getContactDetail:> ', result);
			this.contactList = JSON.parse(result);
			if (this.contactList.length > 0) {
				this.conFirstName = this.contactList[0].FirstName;
				this.conLastName = this.contactList[0].LastName;
				this.conMobilePhone = this.contactList[0].MobilePhone;
				this.conEmail = this.contactList[0].Email;
			}
			this.showSpinner = false;
		})
	}

	// --------- Rerender Address record picker --------
	handlerRerenderAddFields() {
		this.addFieldsRerenderFlag = false;
		setTimeout(() => {
			this.addFieldsRerenderFlag = true;
		}, 200);
	}

	// ---------- Get Address list ------------
	handlerGetAddInfoDetail() {
		getAddInfoDetail({
			accId: this.recordId
		}).then((result) => {
			console.log('getAddInfoDetail:> ', result);
			this.addressInfoList = JSON.parse(result);
			if (this.addressInfoList.length > 0) {
			}
			this.showSpinner = false;
		})
	}

	// ------------ Edit/Remove Address -------------
	handleEditRow(event) {
		// this.showSpinner = true;
		this.isEditing = true;
		this.showAddressInfoModal = true;
		this.handlerClearPostCodeRelatedDate();
		const index = event.currentTarget.dataset.index;
		this.addressInfoId = this.addressInfoList[index].Id;
		this.pincodevalue = this.addressInfoList[index].Postal_Code__c;
		this.areavalue = this.addressInfoList[index].Area__c;
		this.cityvalue = this.addressInfoList[index].City__c;
		this.statevalue = this.addressInfoList[index].State__c;
		this.countryvalue = this.addressInfoList[index].Country__c;
	}

	handleRemoveRow(event) {
		this.showSpinner = true;
		const index = event.currentTarget.dataset.index;
		this.addressInfoId = this.addressInfoList[index].Id;
		console.log(this.addressInfoId);
		deleteAddressInfo({
			addId: this.addressInfoId
		}).then((result) => {
			console.log('deleteAddressInfo:> ', result);
			if (result == 'Success') {
				this.handlerGetAddInfoDetail();
			}
		})
	}

	handleCloseAddressInfoModal() {
		this.showSpinner = false;
		this.showAddressInfoModal = false;
		this.addressInfoId = '';
		this.recordTypeId = '';
		this.addInfoName = '';
		this.isEditing = false;
	}

	// ----------For New Address Insert----------------
	handleInsertAddInfo(event) {
		let recTypeName = event.currentTarget.dataset.name;
		this.addInfoName = recTypeName.toUpperCase();
		this.showAddressInfoModal = true;
		getRecordTypeId({
			name: recTypeName
		}).then((result) => {
			console.log(result);
			this.recordTypeId = result;
			this.handlerClearPostCodeRelatedDate();
		})
	}

	handlePostCodeChange(event) {
		const field = event.target.dataset.id;
		if (field == 'pincode') {
			this.pincodevalue = event.detail.recordId;
			if (this.pincodevalue != '' && this.pincodevalue != null) {
				this.handleGetDataByPinCode();
			} else {
				this.handlerClearPostCodeRelatedDate();
			}
		} else if (field == 'area') {
			this.areavalue = event.detail.recordId;
		} else if (field == 'city') {
			this.cityvalue = event.detail.recordId;
		} else if (field == 'state') {
			this.statevalue = event.detail.recordId;
		} else if (field == 'country') {
			this.countryvalue = event.detail.recordId;
		}
	}

	handlerClearPostCodeRelatedDate() {
		this.pincodevalue = null;
		this.areavalue = null;
		this.cityvalue = null;
		this.statevalue = null;
		this.countryvalue = null;
		this.handlerRerenderAddFields();
	}

	handleGetDataByPinCode() {
		getPinCodeDetails({
			pincode: this.pincodevalue
		}).then((result) => {
			console.log('getPinCodeDetails:>> ', result);
			let data = JSON.parse(result);
			this.areavalue = data.areaId;
			this.cityvalue = data.cityId;
			this.statevalue = data.stateId;
			this.countryvalue = data.countryId;
		});
	}

	// ---------Address Upsert Part-------------------
	handleAddInfoOnSubmit(event) {
		event.preventDefault();
		const lwcInputFields = this.template.querySelectorAll('lightning-input-field');
		let validationFlag = false;
		if (lwcInputFields) {
			lwcInputFields.forEach(field => {
				if (field.fieldName == 'Address_1__c') {
					if (field.value == null || field.value == '') {
						validationFlag = true;
					}
				} else if (field.fieldName == 'Address_2__c') {
					if (field.value == null || field.value == '') {
						validationFlag = true;
					}
				}
			});
			if (this.pincodevalue == '' || this.pincodevalue == null) {
				validationFlag = true;
			} else if (this.areavalue == '' || this.areavalue == null) {
				validationFlag = true;
			} else if (this.cityvalue == '' || this.cityvalue == null) {
				validationFlag = true;
			} else if (this.statevalue == '' || this.statevalue == null) {
				validationFlag = true;
			} else if (this.countryvalue == '' || this.countryvalue == null) {
				validationFlag = true;
			}
			if (validationFlag) {
				console.log('validation flag trigger');
				// Optionally show a toast message for validation errors
				this.showToast('Please fill all the mandatory fields', '', 'error');
			} else {
				const form1 = this.template.querySelector('lightning-record-edit-form[data-id="form1"]');
				const fields = {};
				fields.Postal_Code__c = this.pincodevalue;
				fields.Area__c = this.areavalue;
				fields.City__c = this.cityvalue;
				fields.State__c = this.statevalue;
				fields.Country__c = this.countryvalue;
				lwcInputFields.forEach(field => {
					fields[field.fieldName] = field.value;
				});
				form1.submit(fields);
			}
		}
	}

	handleAddInfoOnSuccess(event) {
		this.showToast('Address Created', '', 'success');
		this.handleCloseAddressInfoModal();
		this.handlerGetAddInfoDetail();
	}

	// ------------ Main Acc Detail Submit --------------------
	handleMainSubmit(event) {
		this.showSpinner = true;
		event.preventDefault();
		const lwcInputFields = this.template.querySelectorAll('lightning-input-field');
		let validationFlag = false;
		if (lwcInputFields) {
			lwcInputFields.forEach(field => {
				if (field.fieldName == 'Gender__c') {
					if (field.value == null || field.value == '') {
						validationFlag = true;
					}
				} else if (field.fieldName == 'Credit_Limit__c') {
					if (field.value == null || field.value == '') {
						validationFlag = true;
					}
				} else if (field.fieldName == 'Country_Code__c') {
					if (field.value == null || field.value == '') {
						validationFlag = true;
					}
				}
				field.reportValidity();
			});
			if (validationFlag) {
				console.log('validation flag trigger');
				// Optionally show a toast message for validation errors
				this.showToast('Please fill all the mandatory fields', '', 'error');
				this.showSpinner = false;
			} else {
				const form1 = this.template.querySelector('lightning-record-edit-form[data-id="mainform"]');
				form1.submit();
			}
		}
	}

	handleMainSuccess(event) {
		// this.showToast('Customer Details Save', '', 'success');
		this.showToast('Please wait', '', 'info');
		this.handleAddressInfoCheck();
	}

	// Check bill to and ship to present
	handleAddressInfoCheck() {
		hasRequiredAddressInfo({
			accId: this.recordId
		}).then((result) => {
			console.log('hasRequiredAddressInfo:>> ', result);
			if (result) {
				this.showToast('Please wait for a while', '', 'info');
				this.syncDataResponseFlag = true;
				this.handleCallout();
			} else {
				this.showToast('Bill to and Ship to required', '', 'error');
				this.showSpinner = false;
			}
		})
	}

}