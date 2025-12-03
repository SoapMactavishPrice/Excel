import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import createOrderWithProducts from '@salesforce/apex/OrderController.createOrderWithProducts';
import getCurrencyOptions from '@salesforce/apex/OrderController.getCurrencyOptions';
import getSalesOrderDetail from '@salesforce/apex/OrderController.getSalesOrderDetail';

const ACCOUNT_FIELDS = ['Account.Name', 'Account.CurrencyIsoCode'];

export default class CreateOrderOnAccount extends NavigationMixin(LightningElement) {
    @api recordId;

    @track showSpinner = false;
    @track poNumber = '';
    @track poReceivedDate = '';
    @track effectiveDate = '';
    @track status = 'Draft';
    @track currency = '';
    @track intendedUserId = '';

    @track statusOptions = [
        { label: 'Draft', value: 'Draft' },
        { label: 'Activated', value: 'Activated' }
    ];
    @track currencyOptions = [];
    @track orderProducts = [{ key: 0, productId: null, productName: null, pbeId: null, quantity: 1, unitPrice: 0 }];

    nextKey = 1;
    accountName = '';
    accountCurrency = '';

    @track orderTypeOptions = [
        { label: 'New', value: 'New' },
        { label: 'Existing', value: 'Existing' }
    ];
    @track orderTypeValue = 'New';
    @track orderTypeFlag = false;
    @track existingOrderId = '';

    @wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            this.accountName = getFieldValue(data, 'Account.Name');
            this.accountCurrency = getFieldValue(data, 'Account.CurrencyIsoCode');
            this.currency = this.accountCurrency;

            // Load all available currency options
            getCurrencyOptions()
                .then(result => {
                    this.currencyOptions = result.map(curr => ({
                        label: curr,
                        value: curr
                    }));
                })
                .catch(error => {
                    console.error('Error loading currency options', error);
                    // Fallback to just the account currency
                    this.currencyOptions = [{
                        label: this.accountCurrency,
                        value: this.accountCurrency
                    }];
                });
        } else if (error) {
            this.showToast('Error', 'Failed to load Account information', 'error');
        }
    }

    connectedCallback() {
        const today = new Date().toISOString().split('T')[0];
        this.effectiveDate = today;
    }

    // Rest of your methods remain the same...
    handlePoNumberChange(event) { this.poNumber = event.target.value; }
    handlePoReceivedDateChange(event) { this.poReceivedDate = event.target.value; }
    handleEffectiveDateChange(event) { this.effectiveDate = event.target.value; }
    handleStatusChange(event) { this.status = event.detail.value; }
    handleCurrencyChange(event) { this.currency = event.detail.value; }
    handleIntendedUserChange(event) { this.intendedUserId = event.detail.value; }

    // lookupRecord(event) {
    //     const selectedRecord = event.detail.selectedRecord;
    //     const index = event.target.dataset.index;
    //     console.log(selectedRecord);

    //     if (selectedRecord && this.orderProducts[index]) {
    //         this.orderProducts[index] = {
    //             ...this.orderProducts[index],
    //             // productId: selectedRecord.Product2Id || selectedRecord.Id,
    //             productId: selectedRecord.proId || selectedRecord.Id,
    //             productName: selectedRecord.Name,
    //             pbeId: selectedRecord.Id,
    //             quantity: 1,
    //             unitPrice: selectedRecord.UnitPrice || selectedRecord.unitPrice || 0,
    //             productCode: selectedRecord.productCode || '' // <- ADD THIS
    //         };
    //         this.orderProducts = [...this.orderProducts];
    //     }
    // }

    lookupRecord(event) {
        const selectedRecord = event.detail.selectedRecord;
        const index = event.target.dataset.index;

        if (selectedRecord && this.orderProducts[index]) {
            // Verify the selected product's currency matches the order currency
            if (selectedRecord.CurrencyIsoCode && selectedRecord.CurrencyIsoCode !== this.currency) {
                this.showToast('Warning',
                    `This product is priced in ${selectedRecord.CurrencyIsoCode} but the order is in ${this.currency}. ` +
                    'Please select a different product or change the order currency.',
                    'warning');
                return;
            }

            this.orderProducts[index] = {
                ...this.orderProducts[index],
                productId: selectedRecord.proId || selectedRecord.Id,
                productName: selectedRecord.Name,
                pbeId: selectedRecord.Id,
                quantity: 1,
                unitPrice: selectedRecord.UnitPrice || selectedRecord.unitPrice || 0,
                productCode: selectedRecord.productCode || ''
            };
            this.orderProducts = [...this.orderProducts];
        }
    }


    handleQuantityChange(event) {
        const index = event.target.dataset.index;
        const value = parseFloat(event.target.value);
        this.orderProducts[index].quantity = isNaN(value) ? 1 : value;
        this.orderProducts = [...this.orderProducts];
    }

    handlePriceChange(event) {
        const index = event.target.dataset.index;
        const value = parseFloat(event.target.value);
        // const regex = /^\d{1,2}(\.\d{1,2})?$/;
        // if (!regex.test(inputValue)) {
        //     event.target.setCustomValidity("Enter number in 00.00 format");
        // } else {
        //     this.orderProducts[index].unitPrice = isNaN(value) ? 0 : value;
        //     this.orderProducts = [...this.orderProducts];
        // }
        this.orderProducts[index].unitPrice = isNaN(value) ? 0 : value;
        this.orderProducts = [...this.orderProducts];
    }

    handleCurrencyChange(event) {
        const newCurrency = event.detail.value;

        // Check if any existing products don't support the new currency
        const hasIncompatibleProducts = this.orderProducts.some(
            p => p.pbeId && p.currencyCode && p.currencyCode !== newCurrency
        );

        if (hasIncompatibleProducts) {
            this.showToast('Warning',
                'Changing currency will remove products not available in the new currency',
                'warning');

            // Remove products that don't match the new currency
            this.orderProducts = this.orderProducts.filter(
                p => !p.pbeId || (p.currencyCode && p.currencyCode === newCurrency)
            );

            // Ensure at least one empty row remains
            if (this.orderProducts.length === 0) {
                this.handleAddItem();
            }
        }

        this.currency = newCurrency;
    }

    handleAddItem() {
        this.orderProducts = [...this.orderProducts, {
            key: this.nextKey++,
            productId: null,
            productName: null,
            pbeId: null,
            quantity: 1,
            unitPrice: 0
        }];
    }

    handleRemoveItem(event) {
        const index = parseInt(event.target.dataset.index, 10);
        if (this.orderProducts.length > 1) {
            this.orderProducts = this.orderProducts.filter((_, i) => i !== index);
        }
    }

    validate() {
        let isValid = true;

        // Order-level validations — checked first and stop at first failure
        if (!this.poNumber) {
            this.showToast('Error', 'PO Number is required', 'error');
            return false;
        }

        if (!this.poReceivedDate) {
            this.showToast('Error', 'PO Received Date is Required', 'error');
            return false;
        }

        if (!this.effectiveDate) {
            this.showToast('Error', 'Order Start Date is Required', 'error');
            return false;
        }

        if (!this.intendedUserId) {
            this.showToast('Error', 'Intended User is Required', 'error');
            return false;
        }

        // Line item validations
        if (!this.orderProducts.length) {
            this.showToast('Error', 'Add at least one Product', 'error');
            return false;
        }

        let missingProduct = false;
        let invalidQuantity = false;
        let invalidPrice = false;

        this.orderProducts.forEach(p => {
            if (!p.productId) {
                missingProduct = true;
            }
            if (!p.quantity || p.quantity <= 0) {
                invalidQuantity = true;
            }
            if (p.unitPrice == null || p.unitPrice < 0) {
                invalidPrice = true;
            }
        });

        if (missingProduct) {
            this.showToast('Error', 'Please select product for all Rows', 'error');
            isValid = false;
        }

        if (invalidQuantity) {
            this.showToast('Error', 'Please enter valid quantity for all Rows', 'error');
            isValid = false;
        }

        if (invalidPrice) {
            this.showToast('Error', 'Please enter valid unit price for all Rows', 'error');
            isValid = false;
        }

        return isValid;
    }

    handleSave() {
        if (!this.validate()) return;

        this.showSpinner = true;

        const orderData = {
            order: {
                accountId: this.recordId,
                poNumber: this.poNumber,
                poReceivedDate: this.poReceivedDate,
                effectiveDate: this.effectiveDate,
                status: this.status,
                currency: this.currency,
                intendedUserId: this.intendedUserId
            },
            orderProducts: this.orderProducts.map(p => ({
                Product2Id: p.productId,
                PricebookEntryId: p.pbeId,
                Quantity: p.quantity,
                UnitPrice: p.unitPrice
            }))
        };

        createOrderWithProducts({ orderData: JSON.stringify(orderData) })
            .then(result => {
                if (result.status === 'success') {
                    this.showToast('Success', 'Order created successfully', 'success');
                    this.navigateToOrder(result.orderId);
                } else {
                    // Handle specific error messages from Apex
                    let errorMessage = result.message || 'Failed to create Order';

                    // Check for currency mismatch error
                    if (errorMessage.includes('FIELD_INTEGRITY_EXCEPTION') &&
                        errorMessage.includes('Enter the same currency as the parent Order')) {
                        errorMessage = 'Products are not available in the selected currency. ' +
                            'Please change the currency or remove those products.';
                    }

                    this.showToast('Error', errorMessage, 'error');
                }
            })
            .catch(error => {
                console.error('Order creation error:', error);
                let errorMessage = error.body?.message || error.message || 'Unexpected error';

                // Check for currency mismatch error in the exception
                if (errorMessage.includes('FIELD_INTEGRITY_EXCEPTION') &&
                    errorMessage.includes('Enter the same currency as the parent Order')) {
                    errorMessage = 'One or more products are not available in the selected currency. ' +
                        'Please change the currency or remove those products.';
                }

                this.showToast('Error', errorMessage, 'error');
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    navigateToOrder(orderId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: orderId,
                objectApiName: 'Order',
                actionName: 'view'
            }
        });
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant,
            mode: 'dismissable'
        }));
    }

    // HA Changes

    handleOrderTypeChange(event) {
        let t = event.target.value;
        if (t == 'Existing') {
            this.orderTypeFlag = true;
        } else {
            this.orderTypeFlag = false;
            this.poNumber = '';
            this.poReceivedDate = '';
            const today = new Date().toISOString().split('T')[0];
            this.effectiveDate = today;
            this.intendedUserId = '';
            this.orderProducts = [];
            setTimeout(() => {
                this.orderProducts.push({
                    key: 0,
                    productId: null,
                    productName: null,
                    pbeId: null,
                    quantity: 1,
                    unitPrice: 0
                });
            }, 500);
        }
    }

    lookupOrderRecord(event) {
        const selectedOrder = event.detail.selectedRecordId;
        console.log(selectedOrder);
        getSalesOrderDetail({
            soId: selectedOrder,
            accId: this.recordId
        }).then((result) => {
            console.log('getSalesOrderDetail:>> ', JSON.parse(result));
            let data = JSON.parse(result);
            this.poNumber = data.order.PoNumber;
            this.poReceivedDate = data.order.Po_Received_Date__c;
            // this.effectiveDate = data.order.EffectiveDate;
            this.intendedUserId = data.order.Intended_User__c;
            if (data.orderItems.length > 0) {
                this.orderProducts = [];
                setTimeout(() => {
                    this.orderProducts.push({
                        key: 0,
                        productId: data.orderItems[0].Product2Id,
                        pbeId: data.orderItems[0].PricebookEntryId,
                        disabled: true
                    });
                    setTimeout(() => {
                        this.orderProducts[0].quantity = data.orderItems[0].Quantity;
                        this.orderProducts[0].unitPrice = data.orderItems[0].UnitPrice;
                        console.log(this.orderProducts);
                    }, 1000);
                }, 500);
            }
        }).catch((error) => {
            console.log(error);
        })
    }

    handleOrderChange(event) {
        this.existingOrderId = event.detail.recordId;
        console.log(this.existingOrderId);
    }

}