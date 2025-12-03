import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getPicklistValues from '@salesforce/apex/OrderController.getPicklistValues';
import createOrderWithItems from '@salesforce/apex/OrderController.createOrderWithItems';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import ACCOUNT_CURRENCY_FIELD from '@salesforce/schema/Account.CurrencyIsoCode';

export default class CreateOrderForAccount extends NavigationMixin(LightningElement) {
    @api recordId; // Account ID from the page

    // Order fields
    accountName = '';
    accountCurrency = '';
    poNumber = '';
    poReceivedDate = '';
    effectiveDate = new Date().toISOString().slice(0, 10);
    status = '';
    statusOptions = [];
    currency = '';
    currencyOptions = [];

    // Line items
    @track lineItems = [];
    showSpinner = false;
    productOptions = [];

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [ACCOUNT_NAME_FIELD, ACCOUNT_CURRENCY_FIELD]
    })
    wiredAccount({ error, data }) {
        if (data) {
            this.accountName = getFieldValue(data, ACCOUNT_NAME_FIELD);
            this.accountCurrency = getFieldValue(data, ACCOUNT_CURRENCY_FIELD);
            this.currency = this.accountCurrency;
        } else if (error) {
            console.error('Error loading account', error);
        }
    }

    connectedCallback() {
        this.loadPicklistValues();
        this.loadAccountProducts();
        this.addNewLineItem();
    }

    loadPicklistValues() {
        getPicklistValues({ objectApiName: 'Order', fieldApiName: 'Status' })
            .then(result => {
                this.statusOptions = result.map(item => ({
                    label: item.label,
                    value: item.value
                }));
                this.status = this.statusOptions[0]?.value || 'Draft';
            })
            .catch(error => {
                console.error('Error loading status picklist', error);
                this.statusOptions = [
                    { label: 'Draft', value: 'Draft' },
                    { label: 'Activated', value: 'Activated' }
                ];
                this.status = 'Draft';
            });
    }

    loadAccountProducts() {
        getAccountProducts({ accountId: this.recordId })
            .then(result => {
                this.productOptions = result;
            })
            .catch(error => {
                console.error('Error loading account products', error);
            });
    }

    handleProductSelection(event) {
        const index = event.detail.index;
        const selectedRecord = event.detail.selectedRecord;

        if (selectedRecord) {
            // Find if this product exists in account products
            const accountProduct = this.productOptions.find(
                prod => prod.productId === selectedRecord.Id
            );

            this.lineItems = this.lineItems.map((item, i) => {
                if (i === index) {
                    return {
                        ...item,
                        productId: selectedRecord.Id,
                        productName: selectedRecord.Name,
                        productCode: selectedRecord.ProductCode,
                        productFamily: selectedRecord.Family,
                        quantity: accountProduct?.quantity || 1,
                        unitPrice: accountProduct?.unitPrice || 0
                    };
                }
                return item;
            });
        }
    }

    // Line item management
    handleAddItem() {
        this.addNewLineItem();
    }

    addNewLineItem() {
        this.lineItems = [...this.lineItems, {
            key: Date.now().toString(),
            productId: '',
            productName: '',
            productCode: '',
            productFamily: '',
            quantity: 1,
            unitPrice: 0
        }];
    }

    handleRemoveItem(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        if (this.lineItems.length > 1) {
            this.lineItems = this.lineItems.filter((item, i) => i !== index);
        } else {
            this.showToast('Error', 'At least one line item is required', 'error');
        }
    }

    handleQuantityChange(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const value = parseFloat(event.target.value) || 0;

        this.lineItems = this.lineItems.map((item, i) =>
            i === index ? { ...item, quantity: value } : item
        );
    }

    handlePriceChange(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const value = parseFloat(event.target.value) || 0;

        this.lineItems = this.lineItems.map((item, i) =>
            i === index ? { ...item, unitPrice: value } : item
        );
    }

    // Other field handlers
    handlePoNumberChange(event) {
        this.poNumber = event.target.value;
    }

    handlePoReceivedDateChange(event) {
        this.poReceivedDate = event.target.value;
    }

    handleEffectiveDateChange(event) {
        this.effectiveDate = event.target.value;
    }

    handleStatusChange(event) {
        this.status = event.detail.value;
    }

    handleCurrencyChange(event) {
        this.currency = event.detail.value;
    }

    // Validation and save
    validateOrder() {
        if (!this.poNumber) {
            this.showToast('Error', 'PO Number is required', 'error');
            return false;
        }

        if (!this.effectiveDate) {
            this.showToast('Error', 'Effective Date is required', 'error');
            return false;
        }

        const hasInvalidItems = this.lineItems.some((item, i) => {
            if (!item.productId) {
                this.showToast('Error', `Please select a product for item ${i + 1}`, 'error');
                return true;
            }
            if (!item.quantity || item.quantity <= 0) {
                this.showToast('Error', `Please enter valid quantity for item ${i + 1}`, 'error');
                return true;
            }
            if (!item.unitPrice || item.unitPrice <= 0) {
                this.showToast('Error', `Please enter valid price for item ${i + 1}`, 'error');
                return true;
            }
            return false;
        });

        return !hasInvalidItems;
    }

    handleSave() {
        if (!this.validateOrder()) return;

        this.showSpinner = true;

        const orderData = {
            accountId: this.recordId,
            poNumber: this.poNumber,
            poReceivedDate: this.poReceivedDate,
            effectiveDate: this.effectiveDate,
            status: this.status,
            currency: this.currency
        };

        const lineItemsData = this.lineItems.map(item => ({
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: item.unitPrice
        }));

        createOrderWithItems({ orderData, lineItemsData })
            .then(result => {
                this.showToast('Success', 'Order created successfully', 'success');
                this.navigateToOrder(result);
            })
            .catch(error => {
                console.error('Error creating order', error);
                this.showToast('Error', error.body?.message || 'Error creating order', 'error');
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

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
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
}