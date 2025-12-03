import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createRecord } from 'lightning/uiRecordApi';
import EVENT_OBJECT from '@salesforce/schema/Event';
import createVisits from '@salesforce/apex/VisitController.createVisits';

export default class VisitCreationForm extends LightningElement {
    @track visitRows = [];
    nextId = 1;

    // Options for Visit For picklist
    get visitForOptions() {
        return [
            { label: 'Lead', value: 'Lead' },
            { label: 'Account', value: 'Account' }
        ];
    }

    connectedCallback() {
        this.addNewRow();
    }

    // Generate a unique ID for new rows/attendees
    generateId() {
        return `id-${this.nextId++}`;
    }

    // Add a new visit row
    generatedCodes = new Set();

    generateUniqueFourDigitCode() {
        let code;
        do {
            code = Math.floor(1000 + Math.random() * 9000).toString();
        } while (this.generatedCodes.has(code));

        this.generatedCodes.add(code);
        return code;
    }
    getRoundedDateTime() {
        const now = new Date();

        // Round up to the next 15 minutes
        const ms = 1000 * 60 * 15; // 15 minutes in milliseconds
        const roundedTime = new Date(Math.ceil(now.getTime() / ms) * ms);

        return this.formatToUtcString(roundedTime);
    }

    getRoundedEndDateTime() {
        const start = new Date(this.getRoundedDateTime()); // get the rounded start time
        const end = new Date(start.getTime() + 1000 * 60 * 30); // add 30 minutes

        return this.formatToUtcString(end);
    }

    formatToUtcString(date) {
        const pad = num => String(num).padStart(2, '0');
        const year = date.getUTCFullYear();
        const month = pad(date.getUTCMonth() + 1);
        const day = pad(date.getUTCDate());
        const hours = pad(date.getUTCHours());
        const minutes = pad(date.getUTCMinutes());
        const seconds = pad(date.getUTCSeconds());

        return `${year}-${month}-${day}T${hours}:${minutes}:${seconds}.000Z`;
    }





    addNewRow() {
        const newRow = {
            id: this.generateId(),
            visitFor: 'Lead',
            recordPickerObject: 'Lead',
            accountId: '',
            purpose: '',
            startDateTime: this.getRoundedDateTime(),
            endDateTime: this.getRoundedEndDateTime(),
            description: '',
            isAttendeesVisible: true,
            isExternalVisible: true,
            attendees: [],
            externalContacts: [], // NEW
            isAccount: false,     // NEW
            showAdd: true,
            showDelete: this.visitRows.length > 0
        };

        // Only the last row should show the add button
        if (this.visitRows.length > 0) {
            this.visitRows[this.visitRows.length - 1].showAdd = false;
            this.visitRows[0].showDelete = true;
        }

        this.visitRows = [...this.visitRows, newRow];

    }

    handleAddRow() {
        this.addNewRow();
    }




    handleRemoveRow(event) {
        const rowId = event.target.dataset.rowId;
        this.visitRows = this.visitRows.filter(row => row.id !== rowId);

        // Update showAdd/showDelete flags
        if (this.visitRows.length > 0) {
            this.visitRows[this.visitRows.length - 1].showAdd = true;
            if (this.visitRows.length === 1) {
                this.visitRows[0].showDelete = false;
            }
        }
    }


    get visitPurposeOptions() {
        console.log("method call => visitPurposeOptions");

        return [
            { value: '', label: '--None--' },
            { value: 'Generating Enquiries', label: 'Generating Enquiries' },
            { value: 'Quality Related Issues', label: 'Quality Related Issues' },
            { value: 'Payment Follow Up', label: 'Payment Follow Up' },
            { value: 'Quotation Follow Up', label: 'Quotation Follow Up' },
            { value: 'Introduction', label: 'Introduction' },
            { value: 'Order Finalisation', label: 'Order Finalisation' },
            { value: 'Collecting Rejection', label: 'Collecting Rejection' },
            { value: 'Sample Collection', label: 'Sample Collection' },
            { value: 'Serving Customer', label: 'Serving Customer' },
            { value: 'Regular Visit', label: 'Regular Visit' },
            { value: 'Other', label: 'Other' },

        ];
    }

    @track isAttendeesVisible = true;

    @track isAttendeesVisible = true;

    handleAddAttendees(event) {
        const rowId = event.target.dataset.rowId;
        const newAttendee = {
            id: event.detail.selectedRecordId,
            name: event.detail.selectedValue,
            showAdd: true,
            showDelete: true
        };

        this.visitRows = this.visitRows.map(row => {
            if (row.id !== rowId) return row;

            const isDuplicate = row.attendees?.some(att => att.id === newAttendee.id);
            if (isDuplicate) return row;

            const updatedAttendees = [...(row.attendees || []), newAttendee];
            this.isAttendeesVisible = false;
            // Optionally set it back to true after a timeout to re-render
            setTimeout(() => {
                this.isAttendeesVisible = true;
            }, 1000);
            return {
                ...row,
                attendees: updatedAttendees,
            };
        });

        // Toggle visibility after selection

    }



    handleRemoveAttendees(event) {
        const rowId = event.target.dataset.rowId;
        const attendeeId = event.target.dataset.attendeeId;

        this.visitRows = this.visitRows.map(row => {
            if (row.id === rowId) {
                const updatedAttendees = row.attendees.filter(att => att.id !== attendeeId);

                return {
                    ...row,
                    attendees: updatedAttendees,
                    isAttendeesVisible: true // ensure picker is shown after removal
                };
            }
            return row;
        });
    }

    handleAddExternalContacts(event) {
        const rowId = String(event.currentTarget.dataset.rowId);

        const selectedId = event.detail.selectedRecordId;
        const selectedName = event.detail.selectedValue;

        if (!selectedId) {
            console.warn('Skipping empty contact selection.');
            return;
        }

        const contact = {
            id: selectedId,
            name: selectedName
        };

        this.visitRows = this.visitRows.map(row => {
            if (String(row.id) === rowId) {
                // Hide the lookup to reset it
                row.isExternalVisible = false;

                // Re-show it after a short delay
                setTimeout(() => {
                    row.isExternalVisible = true;
                    this.visitRows = [...this.visitRows]; // trigger reactivity
                }, 100);

                return {
                    ...row,
                    externalContacts: [...(row.externalContacts || []), contact],
                    isExternalVisible: false // temporary value
                };
            }
            return row;
        });
    }



    handleRemoveExternalContact(event) {
        const rowId = event.target.dataset.rowId;
        const contactId = event.target.dataset.contactId;

        this.visitRows = this.visitRows.map(row => {
            if (row.id === rowId) {
                return {
                    ...row,
                    externalContacts: (row.externalContacts || []).filter(
                        contact => contact.id !== contactId
                    )
                };
            }
            return row;
        });
    }


    handleEventDetailsChange(event) {
        console.log('OUTPUT : ', event);
    }


    handleRemoveAttendee(event) {
        const rowId = event.target.dataset.rowId;
        const attendeeId = event.target.dataset.attendeeId;

        this.visitRows = this.visitRows.map(row => {
            if (row.id !== rowId) return row;

            // Remove the selected attendee
            const updatedAttendees = row.attendees.filter(att => att.id !== attendeeId);

            // Update showDelete and showAdd flags
            const total = updatedAttendees.length;
            const updated = updatedAttendees.map((att, index) => ({
                ...att,
                showDelete: total > 1,
                showAdd: index === total - 1
            }));

            return { ...row, attendees: updated };
        });
    }

    // Update attendee contact selection
    handleAttendeeChange(event) {
        const rowId = event.target.dataset.rowId;
        const attendeeId = event.target.dataset.attendeeId;
        const contactId = event.detail.recordId;

        this.visitRows = this.visitRows.map(row => {
            if (row.id === rowId) {
                return {
                    ...row,
                    attendees: row.attendees.map(a =>
                        a.id === attendeeId ? { ...a, contactId } : a
                    )
                };
            }
            return row;
        });
    }



    // Helper to get the correct object for record picker
    getRecordPickerObject(visitFor) {
        return visitFor === 'Lead' ? 'Lead' : 'Account';
    }

    // Field change handlers
    handleVisitForChange(event) {
        const rowId = event.target.dataset.rowId;
        const value = event.detail.value;

        const objectApi = value === 'Lead' ? 'Lead' : 'Account';

        this.visitRows = this.visitRows.map(row =>
            row.id === rowId
                ? {
                    ...row, visitFor: value,
                    recordPickerObject: objectApi, accountId: null
                }
                : row
        );
    }

    handleRecordSelection(event) {
        const rowId = event.target.dataset.rowId;
        const value = event.detail.recordId;
        console.log(`Record selected for Row ${rowId}: ${value}`);

        this.visitRows = this.visitRows.map(row =>
            row.id === rowId ? { ...row, accountId: value, contactFilter: 'AccountId = ' + "'" + value + "'" } : row
        );
        console.log('Updated visitRows after record selection:', JSON.stringify(this.visitRows, null, 2));

    }

    // handleRecordSelection(event) {
    //     const rowId = event.target.dataset.rowId;
    //     const accountId = event.detail.recordId;

    //     this.visitRows = this.visitRows.map(row => {
    //         if (row.id === rowId) {
    //             return {
    //                 ...row,
    //                 accountId,
    //                 contactFilter: this.generateContactFilter(accountId)
    //             };
    //         }
    //         return row;
    //     });
    // }

    generateContactFilter(accountId) {
        return {
            criteria: [
                {
                    fieldPath: 'AccountId',
                    operator: 'equals',
                    value: accountId
                }
            ],
            logicalOperator: 'and'
        };
    }




    handlePurposeChange(event) {
        const rowId = event.target.dataset.rowId;
        const value = event.target.value;
        this.visitRows = this.visitRows.map(row =>
            row.id === rowId ? { ...row, purpose: value } : row
        );
    }

    handleStartDateChange(event) {
        const rowId = event.target.dataset.rowId;
        const value = event.target.value;
        this.visitRows = this.visitRows.map(row =>
            row.id === rowId ? { ...row, startDateTime: value } : row
        );
    }

    handleEndDateChange(event) {
        const rowId = event.target.dataset.rowId;
        const value = event.target.value;
        this.visitRows = this.visitRows.map(row =>
            row.id === rowId ? { ...row, endDateTime: value } : row
        );
    }

    handleDescriptionChange(event) {
        const rowId = event.target.dataset.rowId;
        const value = event.target.value;
        this.visitRows = this.visitRows.map(row =>
            row.id === rowId ? { ...row, description: value } : row
        );
    }

    handleCancel() {
        this.visitRows = [];
        this.addNewRow();
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Cancelled',
                message: 'Form has been reset',
                variant: 'info'
            })
        );
    }


    handleSave() {
        console.log('Starting handleSave...');
        this.isSaveDisabled = true;

        if (!this.validateForm()) {
            console.log('Form validation failed. Aborting save.');
            this.isSaveDisabled = false;
            return;
        }

        // Transform the data to match Apex expectations
        const visitsPayload = this.visitRows.map(row => {
            const payload = {
                purpose: row.purpose,
                description: row.description,
                startDateTime: row.startDateTime,
                endDateTime: row.endDateTime,
                accountId: row.accountId,
                objectType: row.visitFor,
                attendees: (row.attendees || []).filter(a => a.id).map(a => ({ id: a.id })),
                externalContacts: (row.externalContacts || []).filter(c => c.id).map(c => ({ id: c.id }))
            };

            // For Account events with external contacts, set the first contact as contactId
            if (row.visitFor === 'Account' && row.externalContacts?.length > 0) {
                payload.contactId = row.externalContacts[0].id;
            } else {
                payload.contactId = row.contactId;
            }

            return payload;
        });

        console.log('Sending payload to Apex:', JSON.stringify(visitsPayload, null, 2));

        createVisits({ events: JSON.stringify(visitsPayload) })
            .then(result => {
                if (result.Message == 'Success') {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Visits created successfully.',
                            variant: 'success'
                        })
                    );
                    setTimeout(() => {
                        window.location.reload();
                    }, 1000);
                } else {
                    this.isSaveDisabled = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: result.Message,
                            variant: 'error' // Fixed from 'Error' to 'error'
                        })
                    );
                }
            })
            .catch(error => {
                console.error('Apex error:', error);
                this.isSaveDisabled = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body?.message || 'An error occurred',
                        variant: 'error'
                    })
                );
            });
    }

    validateForm() {
        let isValid = true;

        this.visitRows.forEach((row, index) => {
            if (!row.visitFor) {
                console.log(`Row ${index + 1}: Missing 'Visit For'`);
                isValid = false;
            }
            if (!row.accountId) {
                console.log(`Row ${index + 1}: Missing Lead/Account`);
                isValid = false;
            }
            if (!row.purpose) {
                console.log(`Row ${index + 1}: Missing Purpose`);
                isValid = false;
            }
            if (!row.startDateTime) {
                console.log(`Row ${index + 1}: Missing Start DateTime`);
                isValid = false;
            }
            if (!row.endDateTime) {
                console.log(`Row ${index + 1}: Missing End DateTime`);
                isValid = false;
            }

            // row.attendees.forEach((attendee, aIndex) => {
            //     if (!attendee.contactId) {
            //         console.log(`Row ${index + 1}, Attendee ${aIndex + 1}: Missing Contact`);
            //         isValid = false;
            //     }
            // });
        });

        if (!isValid) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Validation Error',
                    message: 'Please fill all required fields',
                    variant: 'error'
                })
            );
        }

        return isValid;
    }

}