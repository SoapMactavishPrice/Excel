import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCollectionDetails from '@salesforce/apex/Lwc_collection_reportController.getCollectionDetails';
import getProductsData from '@salesforce/apex/Lwc_collection_reportController.getProductsData';
const monthNames = [
    "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
    "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"
];

export default class Lwc_collection_report extends LightningElement {
    @track collectionLoadingList = [];
    @track currentMonthName = '';
    @track collectionList = [];

    @wire(getCollectionDetails)
    collectionDetails({ error, data }) {
        if (data) {
            this.getDataProcees(JSON.stringify(data));
        } else {
            console.log(error);
            this.showToastMessage('Error', 'Error', 'Collection Plan data Not found');

        }
    }
    getDataProcees(data) {
        let temlData = data.replace(/__c/g, '_c');
        temlData = temlData.replace(/__r/g, '_r');
        let temp = JSON.parse(temlData);
        return temp;
    }

    connectedCallback() {
        let currentDate = new Date();
        let currentMonth = monthNames[currentDate.getMonth()];
        this.currentMonthName = ' Collection Plan of ' + currentMonth + ' ' + currentDate.getFullYear();
        this.getProductCategory();
    }

    getProductCategory() {
        let total = {
            "total_Actual_Collection_110th_c": 1,
            "total_Actual_Collection_1120th_c": 1,
            "total_Actual_Collection_2131st_c": 0,
            "total_Bal_ERP_Coll_Plan_c": 0,
            "total_Bal_Imm_Adv_Coll_Plan_c": 0,
            "total_Collection_Plan_110th_c": 0,
            "total_Collection_Plan_1120th_c": 0,
            "total_Collection_Plan_2131st_c": 0,
            "total_ERP_Actual_Coll_c": 0,
            "total_Imm_Adv_Actual_Coll_c": 0,
            "total_ERP_Actual_Coll_c": 0,

            "total_ERP_Collectibles_110th_c": 0,
            "total_ERP_Collectibles_1120th_c": 0,
            "total_ERP_Collectibles_2131st_c": 0,
            "total_ERP_Collectibles_Due_Previous_Month_c": 0,
            "total_ERP_Plan_c": 0,
            "total_Imm_Adv_Plan_c": 0,
            "total_Plan_Vs_Actuals_c": 0,
            "total_Start_Date_c": "2025-03-01",
            "total_Total_Actual_Collection_c": 0,
            "total_Total_Collection_Plan_c": 0,
            "total_Total_ERP_Collectibles_c": 0,
            "Total_Shortfall_Excess_in_Coll_Plan_c": 0
        };


        getProductsData().then(result => {
            let data = JSON.parse(result);
            this.collectionLoadingList = data.map(item => {
                return {
                    ...item,
                    'totalLabel': 'Total of ' + item.ParameterPGName,
                    'total': total,
                    lineData: []
                }
            });
            this.getData();
        })

    }

    getData() {
        this.showSpinner = true;
        getCollectionDetails().then(result => {

            if (result) {
                let tempdata = this.getDataProcees(JSON.stringify(result));
                console.log('tempdata-->', tempdata);
                setTimeout(() => {
                    tempdata.forEach(report => {
                        if (this.collectionLoadingList) {
                            let index = this.collectionLoadingList.findIndex(item => item.ParameterId == report.Product_Group_c);
                            if (index !== -1) {
                                this.collectionLoadingList[index].lineData.push(report);
                            }
                        }
                    });

                    this.showSpinner = false;
                    this.filterData();
                }, 2000);
            } else {
                console.log(error);
                this.showToastMessage('Error', 'Error', 'Collection Plan data Not found');
            }
        })
    }


    generateTable() {
        let doc = '<table class="slds-table slds-table_bordered monthlytable">';

        // Add styles for the table
        doc += '<style>';
        // Base styles for the table, headers, and body cells
        doc += 'table, th, td {';
        doc += '    border: 1px solid black;';
        doc += '    border-collapse: collapse;';
        doc += '    padding: 30px;';
        doc += '}';

        // Style for table data cells
        doc += 'td {';
        doc += '    width: 100px;';
        doc += '    text-align: center;';
        doc += '    background-color: white;';
        doc += '    color: black;';
        doc += '}';

        // Style for header cells
        doc += 'th {';
        doc += '    background-color: #f2f2f2;';
        doc += '    color: black;';
        doc += '}';

        // Add borders to all table header cells
        doc += '.slds-table th.header-cell, .slds-table td.body-cell {';
        doc += '    border: 1px solid black;';
        doc += '}';

        // Apply border to header rows for separation
        doc += '.slds-table thead tr {';
        doc += '    border-bottom: 1px solid black;';
        doc += '}';

        // Apply border to the first column in header for spacing
        doc += '.slds-table thead th:first-child {';
        doc += '    border-left: 1px solid black;';
        doc += '}';

        // Adjust the padding inside table cells for spacing
        doc += '.slds-table th, .slds-table td {';
        doc += '    padding: 30px;';
        doc += '}';

        // Center alignment for table header content
        doc += '.centerAlign tr th div {';
        doc += '    text-align: center;';
        doc += '}';

        // Style for the header cells
        doc += '.centerAlign th {';
        doc += '    background-color: #efefef;';
        doc += '}';

        doc += '</style>';

        // Add table header row
        doc += '<thead class="tablcls centerAlign">';
        doc += `<tr class="slds-text-title_caps"><th colspan="22" style="padding: 30px;background-color: #efefef">${this.currentMonthName}</th></tr>`;
        doc += '<tr class="slds-text-title_caps">';
        doc += '<th style="padding: 30px;background-color: #efefef"></th>';  // Empty cell
        doc += `<th colspan="5" style="padding: 30px;background-color: #efefef"><div class="commonLeftForSecondcol">ERP Collectibles</div></th>`;
        doc += `<th colspan="6" style="padding: 30px;background-color: #efefef"><div class="commonLeftForSecondcol">Collection Plan</div></th>`;
        doc += `<th colspan="6" style="padding: 30px;background-color: #efefef"><div class="commonLeftForSecondcol">Actual Collection Plan</div></th>`;
        doc += `<th colspan="3" style="padding: 30px;background-color: #efefef"><div class="commonLeftForSecondcol">Balance Collectibles</div></th>`;
        doc += `<th style="padding: 30px;background-color: #efefef"><div class="commonLeftForSecondcol">%</div></th>`;

        doc += '</tr>';

        // Product category and month list headers
        doc += '<tr class="slds-text-title_caps">';
        doc += '<th style="padding: 30px;background-color: #efefef">Customer Name</th>';
        doc += '<th style="padding: 30px;background-color: #efefef">ERP Collectibles (Due Prev Month)</th>';
        doc += '<th style="padding: 30px;background-color: #efefef">1-10th</th>';
        doc += '<th style="padding: 30px;background-color: #efefef">11-20th</th>';
        doc += '<th style="padding: 30px;background-color: #efefef">21-31st</th>';
        doc += '<th style="padding: 30px;background-color: #efefef">Total ERP Collectibles</th>';
        doc += '<th style="padding: 30px;background-color: #efefef">1-10th</th>';
        doc += '<th style="padding: 30px;background-color: #efefef">11-20th</th>';
        doc += '<th style="padding: 30px;background-color: #efefef">21-31st</th>';
        doc += '<th style="padding: 30px;background-color: #efefef">ERP Plan</th>';
        doc += '<th style="padding: 30px;background-color: #efefef">Imm / Adv Plan</th>';
        doc += '<th style="padding: 30px;background-color: #efefef">Total Collection Plan</th>';
        doc += '<th style="padding: 30px;background-color: #efefef">1-10th</th>';
        doc += '<th style="padding: 30px;background-color: #efefef">11-20th</th>';
        doc += '<th style="padding: 30px;background-color: #efefef">21-31st</th>';
        doc += '<th style="padding: 30px;background-color: #efefef">ERP Plan</th>';
        doc += '<th style="padding: 30px;background-color: #efefef">Imm / Adv Plan</th>';
        doc += '<th style="padding: 30px;background-color: #efefef">Total Collection Plan</th>';
        doc += '<th style="padding: 30px;background-color: #efefef">Bal ERP Coll Plan</th>';
        doc += '<th style="padding: 30px;background-color: #efefef">Bal Imm / Adv Coll Plan</th>';
        doc += '<th style="padding: 30px;background-color: #efefef">Total Shortfall /<br/> Excess in Coll Plan</th>';
        doc += '<th style="padding: 30px;background-color: #efefef">Plan Vs<br/> Actuals</th>';
        doc += '</tr>';
        doc += '</thead>';

        // Table body with report data
        doc += '<tbody>';
        this.collectionLoadingList.forEach(item => {
            doc += `<tr><td style="padding: 30px;text-align:justify;font-weight:bold;" colspan="22">${item.ParameterPGName}</td></tr>`;
            item.lineData.forEach(lineItem => {
            doc += `<tr><td style="padding: 30px">${lineItem.Customer_Name_Backend_c}</td>`;

            lineItem.Collection_Plan_Line_Item_r.forEach(childItem => {
                    doc += `<td style="padding: 30px">${childItem.ERP_Collectibles_Due_Previous_Month_c || 0}</td>`;
                    doc += `<td style="padding: 30px">${childItem.ERP_Collectibles_110th_c || 0}</td>`;
                    doc += `<td style="padding: 30px">${childItem.ERP_Collectibles_1120th_c || 0}</td>`;
                    doc += `<td style="padding: 30px">${childItem.ERP_Collectibles_2131st_c || 0}</td>`;
                    doc += `<td style="padding: 30px">${childItem.Total_ERP_Collectibles_c || 0}</td>`;

                    doc += `<td style="padding: 30px">${childItem.Collection_Plan_110th_c || 0}</td>`;
                    doc += `<td style="padding: 30px">${childItem.Collection_Plan_1120th_c || 0}</td>`;
                    doc += `<td style="padding: 30px">${childItem.Collection_Plan_2131st_c || 0}</td>`;
                    doc += `<td style="padding: 30px">${childItem.ERP_Plan_c || 0}</td>`;
                    doc += `<td style="padding: 30px">${childItem.Imm_Adv_Plan_c || 0}</td>`;
                    doc += `<td style="padding: 30px">${childItem.Total_Collection_Plan_c || 0}</td>`;


                    doc += `<td style="padding: 30px">${childItem.Actual_Collection_110th_c || 0}</td>`;
                    doc += `<td style="padding: 30px">${childItem.Actual_Collection_1120th_c || 0}</td>`;
                    doc += `<td style="padding: 30px">${childItem.Actual_Collection_2131st_c || 0}</td>`;
                    doc += `<td style="padding: 30px">${childItem.ERP_Actual_Coll_c || 0}</td>`;
                    doc += `<td style="padding: 30px">${childItem.Imm_Adv_Actual_Coll_c || 0}</td>`;
                    doc += `<td style="padding: 30px">${childItem.Total_Actual_Collection_c || 0}</td>`;

                    doc += `<td style="padding: 30px">${childItem.Bal_ERP_Coll_Plan_c || 0}</td>`;

                    doc += `<td style="padding: 30px">${childItem.Bal_Imm_Adv_Coll_Plan_c || 0}</td>`;
                    doc += `<td style="padding: 30px">${childItem.Total_Shortfall_Excess_in_Coll_Plan_c || 0}</td>`;
                    doc += `<td style="padding: 30px">${childItem.Plan_Vs_Actuals_c || 0}</td>`;
               });
               doc += '</tr>';
            
            });
               doc += `<tr style="background: #efefef;"><td style="padding: 30px;background: #efefef">${item.totalLabel}</td>`;
               doc += `<td style="padding: 30px;background: #efefef">${item.total.total_ERP_Collectibles_Due_Previous_Month_c || 0}</td>`;
               doc += `<td style="padding: 30px;background: #efefef">${item.total.total_ERP_Collectibles_110th_c || 0}</td>`;
               doc += `<td style="padding: 30px;background: #efefef">${item.total.total_ERP_Collectibles_1120th_c || 0}</td>`;
               doc += `<td style="padding: 30px;background: #efefef">${item.total.total_ERP_Collectibles_2131st_c || 0}</td>`;
               doc += `<td style="padding: 30px;background: #efefef">${item.total.total_Total_ERP_Collectibles_c || 0}</td>`;
               doc += `<td style="padding: 30px;background: #efefef">${item.total.total_ERP_Collectibles_110th_c || 0}</td>`;
               doc += `<td style="padding: 30px;background: #efefef">${item.total.total_Collection_Plan_1120th_c || 0}</td>`;
               doc += `<td style="padding: 30px;background: #efefef">${item.total.total_Collection_Plan_2131st_c || 0}</td>`;
               doc += `<td style="padding: 30px;background: #efefef">${item.total.total_ERP_Plan_c || 0}</td>`;
               doc += `<td style="padding: 30px;background: #efefef">${item.total.total_Imm_Adv_Plan_c || 0}</td>`;
               doc += `<td style="padding: 30px;background: #efefef">${item.total.total_Total_Collection_Plan_c || 0}</td>`;
               doc += `<td style="padding: 30px;background: #efefef">${item.total.total_Actual_Collection_110th_c || 0}</td>`;
               doc += `<td style="padding: 30px;background: #efefef">${item.total.total_Actual_Collection_1120th_c || 0}</td>`;
               doc += `<td style="padding: 30px;background: #efefef">${item.total.total_Actual_Collection_2131st_c || 0}</td>`;
               doc += `<td style="padding: 30px;background: #efefef">${item.total.total_ERP_Actual_Coll_c || 0}</td>`;
               doc += `<td style="padding: 30px;background: #efefef">${item.total.total_Imm_Adv_Actual_Coll_c || 0}</td>`;
               doc += `<td style="padding: 30px;background: #efefef">${item.total.total_Total_Actual_Collection_c || 0}</td>`;
               doc += `<td style="padding: 30px;background: #efefef">${item.total.total_Bal_ERP_Coll_Plan_c || 0}</td>`;
               doc += `<td style="padding: 30px;background: #efefef">${item.total.total_Bal_Imm_Adv_Coll_Plan_c || 0}</td>`;
               doc += `<td style="padding: 30px;background: #efefef">${item.total.Total_Shortfall_Excess_in_Coll_Plan_c || 0}</td>`;
               doc += `<td style="padding: 30px;background: #efefef">${item.total.total_Plan_Vs_Actuals_c || 0}</td>`;
               doc += '</tr>';
        
       })

        // Total Grand row
        

        doc += `<tr background: #efefef;><td style="padding: 30px;background: #efefef;">GRAND TOTAL</td>`;
        doc += `<td style="padding: 30px;background: #efefef">${this.grandTotals.grandTotal_ERP_Collectibles_Due_Previous_Month_c || 0}</td>`;
        doc += `<td style="padding: 30px;background: #efefef">${this.grandTotals.grandTotal_ERP_Collectibles_110th_c || 0}</td>`;
        doc += `<td style="padding: 30px;background: #efefef">${this.grandTotals.grandTotal_ERP_Collectibles_1120th_c || 0}</td>`;
        doc += `<td style="padding: 30px;background: #efefef">${this.grandTotals.grandTotal_ERP_Collectibles_2131st_c || 0}</td>`;
        doc += `<td style="padding: 30px;background: #efefef">${this.grandTotals.grandTotal_Total_ERP_Collectibles_c || 0}</td>`;
        doc += `<td style="padding: 30px;background: #efefef">${this.grandTotals.grandTotal_ERP_Collectibles_110th_c || 0}</td>`;
        doc += `<td style="padding: 30px;background: #efefef">${this.grandTotals.grandTotal_Collection_Plan_1120th_c || 0}</td>`;
        doc += `<td style="padding: 30px;background: #efefef">${this.grandTotals.grandTotal_Collection_Plan_2131st_c || 0}</td>`;
        doc += `<td style="padding: 30px;background: #efefef">${this.grandTotals.grandTotal_ERP_Plan_c || 0}</td>`;
        doc += `<td style="padding: 30px;background: #efefef">${this.grandTotals.grandTotal_Imm_Adv_Plan_c || 0}</td>`;
        doc += `<td style="padding: 30px;background: #efefef">${this.grandTotals.grandTotal_Total_Collection_Plan_c || 0}</td>`;
        doc += `<td style="padding: 30px;background: #efefef">${this.grandTotals.grandTotal_Actual_Collection_110th_c || 0}</td>`;
        doc += `<td style="padding: 30px;background: #efefef">${this.grandTotals.grandTotal_Actual_Collection_1120th_c || 0}</td>`;
        doc += `<td style="padding: 30px;background: #efefef">${this.grandTotals.grandTotal_Actual_Collection_2131st_c || 0}</td>`;
        doc += `<td style="padding: 30px;background: #efefef">${this.grandTotals.grandTotal_ERP_Actual_Coll_c || 0}</td>`;
        doc += `<td style="padding: 30px;background: #efefef">${this.grandTotals.grandTotal_Imm_Adv_Actual_Coll_c || 0}</td>`;
        doc += `<td style="padding: 30px;background: #efefef">${this.grandTotals.grandTotal_Total_Actual_Collection_c || 0}</td>`;
        doc += `<td style="padding: 30px;background: #efefef">${this.grandTotals.grandTotal_Bal_ERP_Coll_Plan_c || 0}</td>`;
        doc += `<td style="padding: 30px;background: #efefef">${this.grandTotals.grandTotal_Bal_Imm_Adv_Coll_Plan_c || 0}</td>`;
        doc += `<td style="padding: 30px;background: #efefef">${this.grandTotals.grandTotal_Shortfall_Excess_in_Coll_Plan_c || 0}</td>`;
        doc += `<td style="padding: 30px;background: #efefef">${this.grandTotals.grandTotal_Plan_Vs_Actuals_c || 0}</td>`;
        doc += '</tr>';
        doc += '</tbody>';
        doc += '</table>';

        return doc;
    }



    downloadTableAsXls() {
        let tableContent = '';
        tableContent = this.generateTable();
         
        
        if (tableContent) {
            var element = 'data:application/vnd.ms-excel,' + encodeURIComponent(tableContent);

            let downloadElement = document.createElement('a');
            downloadElement.href = element;
            downloadElement.target = '_self';
            const currentDate = new Date();

            const formattedDate = currentDate.toISOString().split('T')[0];

            const hours = currentDate.getHours().toString().padStart(2, '0'); // Ensures two-digit hours
            const minutes = currentDate.getMinutes().toString().padStart(2, '0'); // Ensures two-digit minutes
            const formattedTime = `${hours}:${minutes}`;

            //currentMonthName = this.currentMonthName+'_'+formattedDate+'_' +formattedTime;
        downloadElement.download = this.currentMonthName+'_'+formattedDate+'.xls';  // File name

        document.body.appendChild(downloadElement);
        downloadElement.click();

        document.body.removeChild(downloadElement);
    }
}



    showToastMessage(title, Variant, message) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: Variant
        });
        this.dispatchEvent(event);
    }


    filterData() {
        this.collectionLoadingList = this.collectionLoadingList.filter(item => item.lineData && item.lineData.length > 0);

        this.calculateTotal();

    }
    @track grandTotals = {}
    calculateTotal() {
        // Initialize grand total variables to accumulate the totals for each field
        let grandTotal_Actual_Collection_110th_c = 0;
        let grandTotal_Actual_Collection_1120th_c = 0;
        let grandTotal_Imm_Adv_Plan_c = 0;
        let grandTotal_Actual_Collection_2131st_c = 0;
        let grandTotal_Bal_ERP_Coll_Plan_c = 0;
        let grandTotal_Bal_Imm_Adv_Coll_Plan_c = 0;
        let grandTotal_Collection_Plan_110th_c = 0;
        let grandTotal_Collection_Plan_1120th_c = 0;
        let grandTotal_Collection_Plan_2131st_c = 0;
        let grandTotal_ERP_Actual_Coll_c = 0;
        let grandTotal_ERP_Collectibles_110th_c = 0;
        let grandTotal_ERP_Collectibles_1120th_c = 0;
        let grandTotal_ERP_Collectibles_2131st_c = 0;
        let grandTotal_ERP_Collectibles_Due_Previous_Month_c = 0;
        let grandTotal_ERP_Plan_c = 0;
        let grandTotal_Plan_Vs_Actuals_c = 0;
        let grandTotal_Total_Actual_Collection_c = 0;
        let grandTotal_Imm_Adv_Actual_Coll_c = 0;
        let grandTotal_Total_Collection_Plan_c = 0;
        let grandTotal_Total_ERP_Collectibles_c = 0;
        let grandTotal_Shortfall_Excess_in_Coll_Plan_c = 0;

        // Iterate through each entry in collectionLoadingList and calculate totals for each field
        this.collectionLoadingList.forEach(ele => {
            // Initialize individual totals for each entry
            let total_Actual_Collection_110th_c = 0;
            let total_Actual_Collection_1120th_c = 0;
            let total_Imm_Adv_Plan_c = 0;
            let total_Actual_Collection_2131st_c = 0;
            let total_Bal_ERP_Coll_Plan_c = 0;
            let total_Bal_Imm_Adv_Coll_Plan_c = 0;
            let total_Collection_Plan_110th_c = 0;
            let total_Collection_Plan_1120th_c = 0;
            let total_Collection_Plan_2131st_c = 0;
            let total_ERP_Actual_Coll_c = 0;
            let total_ERP_Collectibles_110th_c = 0;
            let total_ERP_Collectibles_1120th_c = 0;
            let total_ERP_Collectibles_2131st_c = 0;
            let total_ERP_Collectibles_Due_Previous_Month_c = 0;
            let total_ERP_Plan_c = 0;
            let total_Plan_Vs_Actuals_c = 0;
            let total_Total_Actual_Collection_c = 0;
            let total_Imm_Adv_Actual_Coll_c = 0;
            let total_Total_Collection_Plan_c = 0;
            let total_Total_ERP_Collectibles_c = 0;
            let Total_Shortfall_Excess_in_Coll_Plan_c = 0;

            // Iterate through lineData and calculate totals for each Collection_Plan_Line_Item_r
            ele.lineData.forEach(efx => {
                efx.Collection_Plan_Line_Item_r.forEach(etx => {
                    // Accumulate totals for each field in the entry
                    total_Actual_Collection_110th_c += etx.Actual_Collection_110th_c || 0;
                    total_Actual_Collection_1120th_c += etx.Actual_Collection_1120th_c || 0;
                    total_Actual_Collection_2131st_c += etx.Actual_Collection_2131st_c || 0;
                    total_Bal_ERP_Coll_Plan_c += etx.Bal_ERP_Coll_Plan_c || 0;
                    total_Bal_Imm_Adv_Coll_Plan_c += etx.Bal_Imm_Adv_Coll_Plan_c || 0;
                    total_Collection_Plan_110th_c += etx.Collection_Plan_110th_c || 0;
                    total_Collection_Plan_1120th_c += etx.Collection_Plan_1120th_c || 0;
                    total_Collection_Plan_2131st_c += etx.Collection_Plan_2131st_c || 0;
                    total_ERP_Actual_Coll_c += etx.ERP_Actual_Coll_c || 0;
                    total_ERP_Collectibles_110th_c += etx.ERP_Collectibles_110th_c || 0;
                    total_ERP_Collectibles_1120th_c += etx.ERP_Collectibles_1120th_c || 0;
                    total_ERP_Collectibles_2131st_c += etx.ERP_Collectibles_2131st_c || 0;
                    total_ERP_Collectibles_Due_Previous_Month_c += etx.ERP_Collectibles_Due_Previous_Month_c || 0;
                    total_ERP_Plan_c += etx.ERP_Plan_c || 0;
                    total_Plan_Vs_Actuals_c += etx.Plan_Vs_Actuals_c || 0;
                    total_Total_Actual_Collection_c += etx.Total_Actual_Collection_c || 0;
                    total_Total_Collection_Plan_c += etx.Total_Collection_Plan_c || 0;
                    total_Total_ERP_Collectibles_c += etx.Total_ERP_Collectibles_c || 0;
                    Total_Shortfall_Excess_in_Coll_Plan_c += etx.Total_Shortfall_Excess_in_Coll_Plan_c || 0;
                    total_Imm_Adv_Actual_Coll_c += etx.Imm_Adv_Actual_Coll_c || 0;
                    total_Imm_Adv_Plan_c += etx.Imm_Adv_Plan_c || 0;
                });
            });

            // Store the calculated totals in the total object for each entry
            ele.total = {
                total_Actual_Collection_110th_c,
                total_Actual_Collection_1120th_c,
                total_Actual_Collection_2131st_c,
                total_Bal_ERP_Coll_Plan_c,
                total_Bal_Imm_Adv_Coll_Plan_c,
                total_Collection_Plan_110th_c,
                total_Collection_Plan_1120th_c,
                total_Collection_Plan_2131st_c,
                total_ERP_Actual_Coll_c,
                total_ERP_Collectibles_110th_c,
                total_ERP_Collectibles_1120th_c,
                total_ERP_Collectibles_2131st_c,
                total_ERP_Collectibles_Due_Previous_Month_c,
                total_ERP_Plan_c,
                total_Plan_Vs_Actuals_c,
                total_Total_Actual_Collection_c,
                total_Imm_Adv_Actual_Coll_c,
                total_Total_Collection_Plan_c,
                total_Total_ERP_Collectibles_c,
                Total_Shortfall_Excess_in_Coll_Plan_c,
                total_Imm_Adv_Plan_c
            };

            // Accumulate the grand totals for each field
            grandTotal_Actual_Collection_110th_c += total_Actual_Collection_110th_c;
            grandTotal_Actual_Collection_1120th_c += total_Actual_Collection_1120th_c;
            grandTotal_Imm_Adv_Plan_c += total_Imm_Adv_Plan_c;
            grandTotal_Actual_Collection_2131st_c += total_Actual_Collection_2131st_c;
            grandTotal_Bal_ERP_Coll_Plan_c += total_Bal_ERP_Coll_Plan_c;
            grandTotal_Bal_Imm_Adv_Coll_Plan_c += total_Bal_Imm_Adv_Coll_Plan_c;
            grandTotal_Collection_Plan_110th_c += total_Collection_Plan_110th_c;
            grandTotal_Collection_Plan_1120th_c += total_Collection_Plan_1120th_c;
            grandTotal_Collection_Plan_2131st_c += total_Collection_Plan_2131st_c;
            grandTotal_ERP_Actual_Coll_c += total_ERP_Actual_Coll_c;
            grandTotal_ERP_Collectibles_110th_c += total_ERP_Collectibles_110th_c;
            grandTotal_ERP_Collectibles_1120th_c += total_ERP_Collectibles_1120th_c;
            grandTotal_ERP_Collectibles_2131st_c += total_ERP_Collectibles_2131st_c;
            grandTotal_ERP_Collectibles_Due_Previous_Month_c += total_ERP_Collectibles_Due_Previous_Month_c;
            grandTotal_ERP_Plan_c += total_ERP_Plan_c;
            grandTotal_Plan_Vs_Actuals_c += total_Plan_Vs_Actuals_c;
            grandTotal_Total_Actual_Collection_c += total_Total_Actual_Collection_c;
            grandTotal_Imm_Adv_Actual_Coll_c += total_Imm_Adv_Actual_Coll_c;
            grandTotal_Total_Collection_Plan_c += total_Total_Collection_Plan_c;
            grandTotal_Total_ERP_Collectibles_c += total_Total_ERP_Collectibles_c;
            grandTotal_Shortfall_Excess_in_Coll_Plan_c += Total_Shortfall_Excess_in_Coll_Plan_c;
        });

        // Store the grand totals in an object for display
        this.grandTotals = {
            grandTotal_Actual_Collection_110th_c: grandTotal_Actual_Collection_110th_c.toFixed(2),
            grandTotal_Actual_Collection_1120th_c: grandTotal_Actual_Collection_1120th_c.toFixed(2),
            grandTotal_Imm_Adv_Plan_c: grandTotal_Imm_Adv_Plan_c.toFixed(2),
            grandTotal_Actual_Collection_2131st_c: grandTotal_Actual_Collection_2131st_c.toFixed(2),
            grandTotal_Bal_ERP_Coll_Plan_c: grandTotal_Bal_ERP_Coll_Plan_c.toFixed(2),
            grandTotal_Bal_Imm_Adv_Coll_Plan_c: grandTotal_Bal_Imm_Adv_Coll_Plan_c.toFixed(2),
            grandTotal_Collection_Plan_110th_c: grandTotal_Collection_Plan_110th_c.toFixed(2),
            grandTotal_Collection_Plan_1120th_c: grandTotal_Collection_Plan_1120th_c.toFixed(2),
            grandTotal_Collection_Plan_2131st_c: grandTotal_Collection_Plan_2131st_c.toFixed(2),
            grandTotal_ERP_Actual_Coll_c: grandTotal_ERP_Actual_Coll_c.toFixed(2),
            grandTotal_ERP_Collectibles_110th_c: grandTotal_ERP_Collectibles_110th_c.toFixed(2),
            grandTotal_ERP_Collectibles_1120th_c: grandTotal_ERP_Collectibles_1120th_c.toFixed(2),
            grandTotal_ERP_Collectibles_2131st_c: grandTotal_ERP_Collectibles_2131st_c.toFixed(2),
            grandTotal_ERP_Collectibles_Due_Previous_Month_c: grandTotal_ERP_Collectibles_Due_Previous_Month_c.toFixed(2),
            grandTotal_ERP_Plan_c: grandTotal_ERP_Plan_c.toFixed(2),
            grandTotal_Plan_Vs_Actuals_c: grandTotal_Plan_Vs_Actuals_c.toFixed(2),
            grandTotal_Total_Actual_Collection_c: grandTotal_Total_Actual_Collection_c.toFixed(2),
            grandTotal_Imm_Adv_Actual_Coll_c: grandTotal_Imm_Adv_Actual_Coll_c.toFixed(2),
            grandTotal_Total_Collection_Plan_c: grandTotal_Total_Collection_Plan_c.toFixed(2),
            grandTotal_Total_ERP_Collectibles_c: grandTotal_Total_ERP_Collectibles_c.toFixed(2),
            grandTotal_Shortfall_Excess_in_Coll_Plan_c: grandTotal_Shortfall_Excess_in_Coll_Plan_c.toFixed(2)
        };
        console.log('Grand Totals:', JSON.stringify(this.grandTotals));
    }




}