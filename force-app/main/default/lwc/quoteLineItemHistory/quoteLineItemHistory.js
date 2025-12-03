import { LightningElement, track, api } from 'lwc';
import getLatestQuoteLineItems from '@salesforce/apex/QuoteLineItemHistoryController.getLatestQuoteLineItems';

export default class QuoteLineItemHistory extends LightningElement {
    @api recordId;
    @track groupedItems = [];
    @track error;
    intervalId;

    connectedCallback() {
        this.fetchData();
        this.intervalId = setInterval(() => this.fetchData(), 60000);
    }

    disconnectedCallback() {
        clearInterval(this.intervalId);
    }

    fetchData() {
        if (!this.recordId) {
            this.error = 'Quote ID is missing.';
            return;
        }

        getLatestQuoteLineItems({ quoteId: this.recordId })
            .then(data => {
                const grouped = data.map(item => ({
                    product: item.productName,
                    items: [{
                        id: item.id,
                        quantity: this.formatNumber(item.quantity),
                        salesPrice: this.formatCurrency(item.salesPrice),
                        modifiedDate: this.formatDateTime(item.modifiedDate)
                    }]
                }));
                this.groupedItems = grouped;
                this.error = null;
            })
            .catch(error => {
                this.error = error?.body?.message || 'Unknown error';
                console.error(error);
            });
    }

    formatCurrency(value) {
        return new Intl.NumberFormat('en-IN', {
            style: 'currency',
            currency: 'INR'
        }).format(value || 0);
    }

    formatNumber(value) {
        return new Intl.NumberFormat('en-IN').format(value || 0);
    }

    formatDateTime(dateTimeStr) {
        const date = new Date(dateTimeStr);
        return new Intl.DateTimeFormat('en-US', {
            year: 'numeric', month: 'short', day: '2-digit',
            hour: '2-digit', minute: '2-digit', hour12: true
        }).format(date);
    }
}