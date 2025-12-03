import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import sendCustomerData from '@salesforce/apex/SalesOrder_ToOracle.createSalesOrderData';
import getChangedOrderLineItems from '@salesforce/apex/SendOrderToOracle.getChangedOrderLineItems';
import getOrderLineItems from '@salesforce/apex/SendOrderToOracle.getOrderLineItems';
import getPriceList from '@salesforce/apex/SendOrderToOracle.getPriceList';
import getOrganization from '@salesforce/apex/SendOrderToOracle.getOrganization';
import getAddInfo from '@salesforce/apex/SendOrderToOracle.getAddInfo';
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from 'lightning/refresh';

export default class SendOrderToOracle extends LightningElement {

	@api recordId;
	@api objectApiName;
	@api salesDocNo;
	@track showSpinner = true;
	@track recTypeName = '';
	@track ResponseMessage = '';
	@track errorResponseMessage = '';
	@track syncDataResponseFlag = false;
	@track showDispatchSchModal = false;

	@track orderLineItemList = [];
	@track showOrderLineItemModal = false;
	@track isEditing = false;
	@track orderLineItemId = '';
	@track lineNumberValue;

	@track priceListOptions = [];
	@track priceListValue = '';
	@track warehouseOptions = [];
	@track warehouseValue = '';
	@track operatingUnitValue = '';
	@track currencyValue = '';
	@track accountValue = '';
	@track billtoOptions = [];
	@track billtoValue = '';
	@track shiptoOptions = [];
	@track shiptoValue = '';

	@track productQuantity = 0;
	@track productId = '';
	@track orderId = '';
	@track orderLineId = '';

	connectedCallback() {
		console.log('IN SendCustomertoOracle ConnectedCallback');

		setTimeout(() => {
			// this.handleCallout();
			console.log(this.recordId);
			// this.handlerGetOrderLineItems();
			this.showSpinner = false;

			const currencyField = this.template.querySelector('[data-name="currencyfield"]');
			this.currencyValue = currencyField.value;
			const accountField = this.template.querySelector('[data-name="accountdata"]');
			this.accountValue = accountField.value;

			const lookupField = this.template.querySelector('[data-name="operatingunit"]');
			const lookupValue = lookupField.value;
			if (lookupValue) {
				this.operatingUnitValue = lookupValue;
				this.handlerGetOrganization(this.operatingUnitValue);
				this.handlerGetAddressInfo();
			}

			// setTimeout(() => {
			// 	this.handleCreateDispatchSchedule();
			// }, 2000);

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

	handleCallout() {
		sendCustomerData({
			soId: this.recordId
		}).then((result) => {
			console.log('result ', result);
			this.showSpinner = false;
			if (result.includes('Error')) {

				this.errorResponseMessage = result;
			} else {
				this.ResponseMessage = result;
				setTimeout(() => {
					this.handleCreateDispatchSchedule();
				}, 2000);
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

	// ----------- Get Price List -----------
	handlerGetPriceList(pId) {
		getPriceList({
			productId: pId,
			curr: this.currencyValue
		}).then((result) => {
			console.log('result getPriceList:> ', result);
			let data = JSON.parse(result);
			if (data.length > 0) {
				this.priceListOptions = JSON.parse(result);
				let li = this.orderLineItemList[0].Order;
				const pricelistField = this.template.querySelector('[data-name="pricelistField"]');
				if (li.Price_List__c) {
					this.priceListValue = li.Price_List__c;
					pricelistField.value = this.priceListValue;
				}
				if (data.length == 1 && this.priceListValue == '') {
					this.priceListValue = data[0].value;
					pricelistField.value = this.priceListValue;
				}
			}
		})
	}

	// ------------- Price list Change ------------
	handleInputChange(event) {
		if (event.currentTarget.dataset.name == 'pricelist') {
			this.priceListValue = event.target.value;
			const pricelistField = this.template.querySelector('[data-name="pricelistField"]');
			pricelistField.value = this.priceListValue;
		}
		if (event.currentTarget.dataset.name == 'operatingunit') {
			this.operatingUnitValue = event.target.value;
			if (this.operatingUnitValue != '') {
				this.handlerGetOrganization(this.operatingUnitValue);
				this.handlerGetAddressInfo();
			}
		}
		if (event.currentTarget.dataset.name == 'warehouse') {
			this.warehouseValue = event.target.value;
			const warehouselookupField = this.template.querySelector('[data-name="warehouselookup"]');
			warehouselookupField.value = this.warehouseValue;
			this.handlerGetOrderLineItems();
		}
		if (event.currentTarget.dataset.name == 'billtodata') {
			this.billtoValue = event.target.value;
			const billTolookupField = this.template.querySelector('[data-name="billtolookup"]');
			billTolookupField.value = this.billtoValue;
		}
		if (event.currentTarget.dataset.name == 'shiptodata') {
			this.shiptoValue = event.target.value;
			const shipTolookupField = this.template.querySelector('[data-name="shiptolookup"]');
			shipTolookupField.value = this.shiptoValue;
		}
	}

	handlerGetOrganization(ouId) {
		getOrganization({
			ouId: ouId
		}).then((result) => {
			if (result != '') {
				this.warehouseOptions = JSON.parse(result);
				console.log('result getOrganization:> ', this.warehouseOptions);
			}
			const warehouselookupField = this.template.querySelector('[data-name="warehouselookup"]');
			const warehouselookupValue = warehouselookupField.value;
			if (warehouselookupValue) {
				this.warehouseValue = warehouselookupValue;
				getOrderLineItems({
					ordId: this.recordId
				}).then((data) => {
					this.orderLineItemList = JSON.parse(data);
					if (this.orderLineItemList.length > 0) {
						let li = this.orderLineItemList[0].Order;
						if (li.Oracle_Sales_Order_No__c != null && li.Oracle_Sales_Order_No__c != undefined) {
							this.showToast('Order has been already created in Oracle', '', 'info');
							// this.closeModal();
						} else {
							this.handlerGetPriceList(this.orderLineItemList[0].Product2Id);
						}
					}
				}).catch((error) => {
					console.log('getOrderLineItems:>> ', error);
					this.showToast('Something went wrong!!', 'Check getOrderLineItems()', 'error');
					this.showSpinner = false;
				})
			}
		});
	}

	handlerGetAddressInfo() {
		getAddInfo({
			ouId: this.operatingUnitValue,
			accId: this.accountValue
		}).then((result) => {
			console.log('getAddInfo result:>> ', JSON.parse(result));
			let data = JSON.parse(result);
			let bdata = data.billToAddInfoList;
			let sdata = data.shipToAddInfoList;
			if (bdata.length > 0) {
				this.billtoOptions = bdata.map(element => ({
					value: element.Id,
					label: this.getAddLabel(element)
				}));

				const billtodataField = this.template.querySelector('[data-name="billtolookup"]');
				const billtodataValue = billtodataField.value;
				// console.log(billtodataValue);
				this.billtoValue = billtodataValue;
			}
			if (sdata.length > 0) {
				this.shiptoOptions = sdata.map(element => ({
					value: element.Id,
					label: this.getAddLabel(element)
				}));

				const shiptodataField = this.template.querySelector('[data-name="shiptolookup"]');
				const shiptodataValue = shiptodataField.value;
				// console.log(shiptodataValue);
				this.shiptoValue = shiptodataValue;
			}
		}).catch((error) => {
			console.log('getAddInfo ERROR:>> ', error);

		})
	}

	getAddLabel(para) {
		let postal = para.Postal_Code__c ? ', ' + para.Postal_Code__r.Name : '';
		let city = para.City__c ? ', ' + para.City__r.Name : '';
		let state = para.State__c ? ', ' + para.State__r.Name : '';
		return para.Address_1__c + ', ' + para.Address_2__c + city + state + postal;
	}

	// --------- Get Order Line Item --------
	handlerGetOrderLineItems() {
		this.showSpinner = true;
		getChangedOrderLineItems({
			ordId: this.recordId,
			orgId: this.warehouseValue
		}).then((result) => {
			this.orderLineItemList = JSON.parse(result);
			console.log('getOrderLineItems:> ', this.orderLineItemList);
			if (this.orderLineItemList.length > 0) {
				let li = this.orderLineItemList[0].Order;
				if (li.Oracle_Sales_Order_No__c != null && li.Oracle_Sales_Order_No__c != undefined) {
					this.showToast('Order has been already created in Oracle', '', 'info');
					// this.closeModal();
				} else {
					this.handlerGetPriceList(this.orderLineItemList[0].Product2Id);
				}
			}
			this.showSpinner = false;
		}).catch((error) => {
			console.log('getChangedOrderLineItems:>> ', error);
			this.showToast('Something went wrong!!', 'Check getChangedOrderLineItems()', 'error');
			this.showSpinner = false;
		})
	}

	// ------------ Edit Line Item -------------

	handleCloseOrderLineItemModal() {
		this.showSpinner = false;
		this.showOrderLineItemModal = false;
		this.orderLineItemId = '';
		this.isEditing = false;
	}

	handleEditRow(event) {
		// this.showSpinner = true;
		this.isEditing = true;
		this.showOrderLineItemModal = true;
		const index = event.currentTarget.dataset.index;
		// console.log((parseInt(index)+1)*1000);
		this.lineNumberValue = (parseInt(index) + 1) * 1000;
		this.orderLineItemId = this.orderLineItemList[index].Id;
	}

	handleLineItemOnSubmit(event) {
		console.log('YESSSS');

		event.preventDefault();
		const lwcInputFields = this.template.querySelectorAll('lightning-input-field');
		const mandatoryFields = ['Line_No__c', 'Quantity', 'UnitPrice', 'Requested_Delivery_Date__c', 'Promised_Delivery_Date__c', 'Type__c'];
		let validationFlag = false;
		if (lwcInputFields) {
			lwcInputFields.forEach(field => {
				if (mandatoryFields.includes(field.fieldName) && (field.value == null || field.value === '')) {
					validationFlag = true;
				}
				field.reportValidity();
			});
			if (validationFlag) {
				console.log('validation flag trigger');
				// Optionally show a toast message for validation errors
				this.showToast('Please fill all the mandatory fields', '', 'error');
			} else {
				const form1 = this.template.querySelector('lightning-record-edit-form[data-id="form1"]');
				form1.submit();
			}
		}
	}

	handleOnError(event) {
		const error = event.detail;
		console.log('Error occurred: ', error);
		this.showToast(error.detail, '', 'error');
	}

	handleLineItemOnSuccess(event) {
		this.showToast('Line Item Update', '', 'success');
		this.handleCloseOrderLineItemModal();
		getOrderLineItems({
			ordId: this.recordId
		}).then((data) => {
			this.orderLineItemList = JSON.parse(data);
		})
	}

	// ------------ Main Order Submit --------------------
	handleMainSubmit(event) {
		this.showSpinner = true;
		event.preventDefault();
		const mandatoryFields = ['Payment_Term__c', 'Order_Type__c', 'Operating_Unit__c', 'Po_Received_Date__c', 'Requested_Delivery_Date__c', 'Promised_Delivery_Date__c', 'PoNumber', 'Business_Unit__c', 'Bill_to_Party__c', 'Ship_to_Party__c'];
		const lwcInputFields = this.template.querySelectorAll('lightning-input-field');
		let validationFlag = false;
		if (lwcInputFields) {
			lwcInputFields.forEach(field => {
				if (mandatoryFields.includes(field.fieldName) && (field.value == null || field.value === '')) {
					console.log(field.fieldName);

					validationFlag = true;
				}
				field.reportValidity();
			});
			if (this.priceListValue == '') {
				validationFlag = true;
			} else if (this.warehouseValue == '') {
				validationFlag = true;
			}
			if (validationFlag) {
				console.log('validation flag trigger');
				// Optionally show a toast message for validation errors
				this.showToast('Please fill all the mandatory fields', '', 'error');
				this.showSpinner = false;
			} else {
				const form1 = this.template.querySelector('lightning-record-edit-form[data-id="mainform"]');
				const fields = {};
				// fields.Price_List__c = this.priceListValue;
				// fields.Warehouse__c = this.warehouseValue;

				// lwcInputFields.forEach(field => {
				// 	fields[field.fieldName] = field.value;
				// });
				form1.submit();
			}
		}
	}

	handleNewError(event) {
		// This will display the error in the lightning-messages component
		const error = event.detail;
		console.log('Error occurred: ', error);

		// Optionally show an error toast message
		this.dispatchEvent(
			new ShowToastEvent({
				title: 'Error',
				message: 'An error occurred: ' + error.detail,
				variant: 'error'
			})
		);

	}

	handleMainSuccess(event) {
		// this.showToast('Customer Details Save', '', 'success');
		this.showToast('Please wait for callout response', '', 'info');
		this.syncDataResponseFlag = true;
		// this.showSpinner = false;
		this.handleCallout();
	}

	handleCreateDispatchSchedule() {
		// this.showSpinner = true;
		this.syncDataResponseFlag = true;

		this.orderId = this.recordId;
		this.orderLineId = this.orderLineItemList[0].Id;
		this.productQuantity = this.orderLineItemList[0].Quantity;
		this.productId = this.orderLineItemList[0].Product2Id;
		
		this.showDispatchSchModal = true;
	}

	handleAfterDispatchInfoSave(event){
		this.closeModal();
	}

}