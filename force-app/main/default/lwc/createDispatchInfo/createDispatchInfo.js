import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveDispatchSchedule from '@salesforce/apex/SendOrderToOracle.saveDispatchSchedule';

export default class CreateDispatchInfo extends LightningElement {

    @api productQuantity;
    @api productId;
    @api orderId;
    @api orderLineId;

    totalQuantity; // can make dynamic later
    @track lineItems = [
        { id: 1, qty: 0, startDate: '', endDate: '' }
    ];
    nextId = 2;

    get remainingQuantity() {
        const totalSplit = this.lineItems.reduce((sum, item) => sum + Number(item.qty || 0), 0);
        return this.totalQuantity - totalSplit;
    }

    get remainingStyle() {
        if (this.remainingQuantity < 0) {
            this.showToast('Invalid quantity input', '', 'error');
            return 'color:red;';
        } else if (this.remainingQuantity > 0) {
            return 'color:orange;';
        } else {
            return 'color:green;';
        }
    }

    get disableAdd() {
        // Cannot add if remaining qty <= 0
        if (this.remainingQuantity <= 0) {
            return true;
        }

        // Cannot add if any existing row is incomplete
        const hasIncomplete = this.lineItems.some(item => {
            return (
                !item.qty || item.qty <= 0 ||
                !item.startDate ||
                !item.endDate
            );
        });

        return hasIncomplete;
    }

    get disableSave() {
        return this.remainingQuantity !== 0 || this.lineItems.some(item => {
            return (
                !item.qty || item.qty <= 0 ||
                !item.startDate ||
                !item.endDate
            );
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

    connectedCallback() {
        console.log('CreateDispatchInfo connectedCallback');
        // console.log(this.productQuantity);
        // console.log(this.productId);
        // console.log(this.orderId);
        // console.log(this.orderLineId);
        this.totalQuantity = this.productQuantity;
    }

    addRow() {
        this.lineItems = [
            ...this.lineItems,
            { id: this.nextId++, qty: 0, startDate: '', endDate: '' }
        ];
    }

    removeRow(event) {
        const id = Number(event.target.dataset.id);
        this.lineItems = this.lineItems.filter(item => item.id !== id);
    }

    handleQtyChange(event) {
        const id = Number(event.target.dataset.id);
        const value = Number(event.target.value);
        this.lineItems = this.lineItems.map(item => {
            if (item.id === id) {
                return { ...item, qty: value };
            }
            return item;
        });
    }

    handleStartDateChange(event) {
        const id = Number(event.target.dataset.id);
        const value = event.target.value;
        this.lineItems = this.lineItems.map(item => {
            if (item.id === id) {
                return { ...item, startDate: value };
            }
            return item;
        });
    }

    handleEndDateChange(event) {
        const id = Number(event.target.dataset.id);
        const value = event.target.value;
        this.lineItems = this.lineItems.map(item => {
            if (item.id === id) {
                return { ...item, endDate: value };
            }
            return item;
        });
    }

    handleSave() {
        // Validate again
        if (this.remainingQuantity !== 0) {
            this.showToast('Error', 'Remaining Quantity must be zero before saving.', 'error');
            return;
        }

        const hasIncomplete = this.lineItems.some(item => {
            return (
                !item.qty || item.qty <= 0 ||
                !item.startDate ||
                !item.endDate
            );
        });
        if (hasIncomplete) {
            this.showToast('Error', 'All line items must be completely filled before saving.', 'error');
            return;
        }

        // Prepare data
        const payload = this.lineItems.map(item => ({
            qty: item.qty,
            startDate: item.startDate,
            endDate: item.endDate
        }));

        // console.log(this.productQuantity);
        // console.log(this.productId);
        // console.log(this.orderId);
        // console.log(this.orderLineId);
        // console.log(payload);

        saveDispatchSchedule({
            oId: this.orderId,
            oliId: this.orderLineId,
            prodId: this.productId,
            jsonPayload: JSON.stringify(payload)
        }).then(() => {
            this.showToast('Success', 'Line items saved successfully!', 'success');
            const saveEvent = new CustomEvent('savecompleted', {
                detail: {
                    message: 'done',
                    data: payload
                }
            });
            this.dispatchEvent(saveEvent);
        }).catch(error => {
            this.showToast('Error', error.body.message, 'error');
        });
    }


}