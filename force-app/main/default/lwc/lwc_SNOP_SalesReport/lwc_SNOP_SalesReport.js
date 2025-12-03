import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSalesDetail from '@salesforce/apex/Lwc_SNOP_SalesReportController.getSalesDetail';
import getSaleSave from '@salesforce/apex/Lwc_SNOP_SalesReportController.getSaleSave';
import getProductsData from '@salesforce/apex/Lwc_SNOP_SalesReportController.getProductsData';
const monthNames = [
    "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
    "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"
];

export default class Lwc_SNOP_SalesReport extends LightningElement {
    @track allReportData = [];
    @track generatedIds = new Set();
    @track currentMonthName = '';
    @track currentMonth_production = '';
    @track isSalesReport = false;
    @track isProductionReport = false;
    @track activeTab = 'sales';
    @track showSpinner = false

    handleTabChange(event) {
        const selectedTab = event.target.value;
        console.log('selectedTab-->', selectedTab);

        if (selectedTab == 'sales') {
            this.isSalesReport = true;
            this.isProductionReport = false;
        } else if (selectedTab == 'production') {
            this.isSalesReport = false;
            this.isProductionReport = true;
        }
    }

    connectedCallback() {
        let currentDate = new Date();
        let currentMonth = monthNames[currentDate.getMonth()];
        this.currentMonthName = 'OPG ' + currentMonth + ' ' + currentDate.getFullYear() + ' Sales';
        this.currentMonth_production = 'OPG ' + currentMonth + ' ' + currentDate.getFullYear() + ' Production';
        
        //this.currentMonthName = 'March 2020';
        this.getMonthList();
        this.getProductCategory();
        
    }

    @track loadAllData = [];
    getProductCategory(){
        getProductsData().then(result=>{
            let data = JSON.parse(result);
            this.loadAllData = data.map(item => {
                return {
                    ...item,
                    rowSpan:0,
                   lineData:[]
            }
        });
        this.getData();
       })
       
    }
    generateRandomNum() {
        let randomId;
        do {
            randomId = Math.floor(Math.random() * 9000) + 1000;  // Generates a random number between 1000 and 9999
        } while (this.generatedIds.has(randomId)); // If the number already exists, regenerate

        // Add the randomId to the set of generated ids to avoid duplicates
        this.generatedIds.add(randomId);
        return randomId;

    }

saveFile(){
    let tempData = this.getFilteredParameters();
    if(tempData.length > 0){    
        console.log(JSON.stringify(tempData));
        
    getSaleSave({js:JSON.stringify(tempData)}).then(result=>{
        
        if(result=='Success'){
            this.showToast('Success','Success','Rate Updated Successfully');
            setTimeout(()=>{
                //window.location.reload();
            },1000)
        }
        else{
        this.showToast('Error','Error',result);
        }
    })
    }else{
    this.showToast('Error','Error','Rate Value should be greater than 0')
    }

}

showToast(label,varinat,message){
    const event = new ShowToastEvent({
        label:label,
        variant:varinat,
        message:message,
    })

    this.dispatchEvent(event);
}

getFilteredParameters() {
    let filteredChildData = [];
    this.loadAllData.forEach(parameter => {
        parameter.lineData.forEach(line => {
        filteredChildData.push(...line.childData.filter(child => child.rate > 0));
    });
    });
    return filteredChildData;
}


@track currentMonthLabel = '';

    @track monthList = [];
    monthlySales = [];

    getMonthList() {
        const currentDate = new Date();
        const currentMonthIndex = currentDate.getMonth();
        const currentYear = currentDate.getFullYear();

        this.monthList = [];

        const monthsToInclude = 4;
        let monthCount = 0;

        while (monthCount < monthsToInclude) {
            const monthIndex = (currentMonthIndex + monthCount) % 12;
            const year = currentYear + Math.floor((currentMonthIndex + monthCount) / 12);
            const monthName = monthNames[monthIndex].toUpperCase();
            if (monthCount === 0) {
                this.monthList.push(`PLAN ${monthName}`);
                this.monthList.push(`ACTUAL ${monthName}`);
                this.currentMonthLabel = `ACTUAL ${monthName}`;

            } else {
                this.monthList.push(monthName);
            }

            monthCount++;
        }

        this.monthList.forEach((month, index) => {
            let temp = {
                'name': month,
                'index': index,
                'Actual_Dispatch': 0,
                'total': 0  // Set initial value of 0 for each month

            }
            this.monthlySales.push(temp);
        });




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
        doc += `<tr class="slds-text-title_caps"><th colspan="16" style="padding: 30px;background-color: #efefef">${this.currentMonthName}</th></tr>`;
        doc += '<tr class="slds-text-title_caps">';
        doc += '<th style="padding: 30px;background-color: #efefef"></th>';  // Empty cell
        doc += `<th colspan="5" style="padding: 30px;background-color: #efefef"><div class="commonLeftForSecondcol">Sale Qty MT</div></th>`;
        doc += `<th colspan="5" style="padding: 30px;background-color: #efefef"><div class="commonLeftForSecondcol">Rate</div></th>`;
        doc += `<th colspan="5" style="padding: 30px;background-color: #efefef"><div class="commonLeftForSecondcol">Value In Cr</div></th>`;
        doc += '</tr>';

        // Product category and month list headers
        doc += '<tr class="slds-text-title_caps">';
        doc += '<th style="padding: 30px;background-color: #efefef">Product Category</th>';
        this.monthList.forEach(month => {
            doc += `<th style="padding: 30px;background-color: #efefef">${month}</th>`;
        });
        this.monthList.forEach(month => {
            doc += `<th style="padding: 30px;background-color: #efefef">${month}</th>`;
        });
        this.monthList.forEach(month => {
            doc += `<th style="padding: 30px;background-color: #efefef">${month}</th>`;
        });
        doc += '</tr>';
        doc += '</thead>';

        // Table body with report data
        doc += '<tbody>';
        this.loadAllData.forEach(item => {
            doc += `<tr><td style="padding: 30px;text-align:justify;font-weight:bold;" colspan="16">${item.ParameterPGName}</td></tr>`;
            item.lineData.forEach(lineItem => {
            doc += `<tr><td style="padding: 30px">${lineItem.ParameterName}</td>`;

            // Sale Qty MT section
            lineItem.childData.forEach(childItem => {
    let cellValue = '';

    // Check for Actual_Domestic_Sales first
    if (childItem.hasOwnProperty('Actual_Domestic_Sales')) {
        cellValue = childItem.Actual_Domestic_Sales ?? '';
    } 
    // Otherwise fallback to Domestic_Sales (Plan)
    else if (childItem.hasOwnProperty('Domestic_Sales')) {
        cellValue = childItem.Domestic_Sales ?? '';
    }

    // Add a single <td> for the matched value (Actual or Plan)
    doc += `<td style="padding: 30px">${cellValue}</td>`;
});

// For Rate
lineItem.childData.forEach(childItem => {
    // Directly check for rate
    doc += `<td style="padding: 30px">${childItem.rate || ''}</td>`;
});

// For Sales Value (in Cr)
lineItem.childData.forEach(childItem => {
    // Directly check for salesValue
    doc += `<td style="padding: 30px">${childItem.salesValue || ''}</td>`;
});

            doc += '</tr>';
        });
       })

        // Total row
        
        this.MonthTotal.forEach(item => {
            doc += '<tr style="padding: 30px" class="slds-text-title_caps">';
        doc += `<td style="padding: 30px;text-align:justify;font-weight:bold;" ><strong>${item.label}</strong></td>`;
        doc += '<td style="padding: 30px" colspan="10"></td>';
            item.totalMonthViseValue.forEach(totalValue => {
            doc += `<td style="padding: 30px"><strong>${totalValue.total || 0}</strong></td>`;
        })
        doc += '</tr>';
        });

        doc += '<tr style="padding: 30px" class="slds-text-title_caps"><td style="padding: 30px;text-align:justify;font-weight:bold;" colspan="1">GRAND TOTAL</td>';
        doc += '<td style="padding: 30px" colspan="10"></td>';
        this.monthlySales.forEach(item => {
        doc += `<td style="padding: 30px"><strong>${item.total}</strong></td>`;
        });
        doc += '</tr>';


        doc += '<tr style="padding: 30px" class="slds-text-title_caps"><td style="padding: 30px;text-align:justify;font-weight:bold;" colspan="1">INCOMING ROLL OVER</td>';
        doc += '<td style="padding: 30px" colspan="10"></td>';
        doc += '<td style="padding: 30px" colspan="">-</td>';
        doc += `<td style="padding: 30px"><strong>${this.IncommingRollOver}</strong></td>`;
        doc += '<td style="padding: 30px" colspan="">-</td>';
        doc += '<td style="padding: 30px" colspan="">-</td>';
        doc += '<td style="padding: 30px" colspan="">-</td>';
        doc += '</tr>';


        doc += '<tr style="padding: 30px" class="slds-text-title_caps"><td style="padding: 30px;text-align:justify;font-weight:bold;" colspan="1">OUTGOING REVERSAL</td>';
        doc += '<td style="padding: 30px" colspan="10"></td>';
        doc += '<td style="padding: 30px" colspan="">-</td>';
        doc += `<td style="padding: 30px"><strong>${this.OutgoingRollOver}</strong></td>`;
        doc += '<td style="padding: 30px" colspan="">-</td>';
        doc += '<td style="padding: 30px" colspan="">-</td>';
        doc += '<td style="padding: 30px" colspan="">-</td>';
        doc += '</tr>';


        doc += '<tr style="padding: 30px" class="slds-text-title_caps"><td style="padding: 30px;text-align:justify;font-weight:bold;" colspan="1">ACTUAL DISPATCH</td>';
        doc += '<td style="padding: 30px" colspan="10"></td>';
        this.monthlySales.forEach(item => {
            if(item.Actual_Dispatch)
            doc += `<td style="padding: 30px"><strong>${item.Actual_Dispatch}</strong></td>`; 
            if(!item.Actual_Dispatch)
            doc += `<td style="padding: 30px"><strong>${item.total}</strong></td>`;
        });
        doc += '</tr>';

        doc += '</tbody>';
        doc += '</table>';

        return doc;
    }

    generateTable_Production() {
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
        doc += `<tr class="slds-text-title_caps"><th colspan="6" style="padding: 30px;background-color: #efefef">${this.currentMonth_production}</th></tr>`;
        doc += '<tr class="slds-text-title_caps">';
        doc += `<th colspan="6" style="padding: 30px;background-color: #efefef"><div class="commonLeftForSecondcol">Production  Qty MT</div></th>`;
        // doc += `<th colspan="5" style="padding: 30px;background-color: #efefef"><div class="commonLeftForSecondcol">Rate</div></th>`;
        // doc += `<th colspan="5" style="padding: 30px;background-color: #efefef"><div class="commonLeftForSecondcol">Value In Cr</div></th>`;
        doc += '</tr>';

        // Product category and month list headers
        doc += '<tr class="slds-text-title_caps">';
        doc += '<th style="padding: 30px;background-color: #efefef">Product Category</th>';
        this.monthList.forEach(month => {
            doc += `<th style="padding: 30px;background-color: #efefef">${month}</th>`;
        });
        // this.monthList.forEach(month => {
        //     doc += `<th style="padding: 30px;background-color: #efefef">${month}</th>`;
        // });
        // this.monthList.forEach(month => {
        //     doc += `<th style="padding: 30px;background-color: #efefef">${month}</th>`;
        // });
        doc += '</tr>';
        doc += '</thead>';

        // Table body with report data
        doc += '<tbody>';
        this.loadAllData.forEach(item => {

            doc += `<tr><td style="padding: 30px;text-align:justify;font-weight:bold;" colspan="6">${item.ParameterPGName}</td></tr>`;
            item.lineData.forEach(lineItem => {
            doc += `<tr><td style="padding: 30px">${lineItem.ParameterName}</td>`;




            // Sale Qty MT section

lineItem.childData.forEach(childItem => {
    let cellValue = '';

    // Check for Actual_Production first
    if (childItem.hasOwnProperty('Actual_Production')) {
        cellValue = childItem.Actual_Production ?? '';
    } 
    // Otherwise fallback to Production
    else if (childItem.hasOwnProperty('Production')) {
        cellValue = childItem.Production ?? '';
    }

    // Add a single <td> for the matched value (actual or plan)
    doc += `<td style="padding: 30px">${cellValue}</td>`;
});



            // lineItem.childData.forEach(childItem => {
            //     console.log('OUTPUT : ',childItem);
            //     if (childItem.Actual_Production) {
            //         doc += `<td style="padding: 30px">${childItem.Actual_Production || 0}</td>`;
            //     }
            //     if (childItem.Domestic_Sales) {
            //         doc += `<td style="padding: 30px">${childItem.Production || 0}</td>`;
            //     }
            // });
            


            doc += '</tr>';
        });
    })



    this.MonthProductionTotal.forEach(item => {
        doc += '<tr style="padding: 30px" class="slds-text-title_caps">';
    doc += `<td style="padding: 30px"><strong>${item.label}</strong></td>`;
        item.totalMonthProdValue.forEach(totalValue => {
        doc += `<td style="padding: 30px"><strong>${totalValue.total || 0}</strong></td>`;
    })
    doc += '</tr>';
    });


        doc += '</tbody>';

        doc += '</table>';

        return doc;
    }



    downloadTableAsXls(event) {
        let reportName = '';
        let tableContent = '';
        if (event.target.value == "sales") {
            tableContent = this.generateTable();
            reportName = this.currentMonthName;
        } 
        else if (event.target.value == "production") {
            tableContent = this.generateTable_Production();
            reportName = this.currentMonth_production;
        }
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

            reportName = reportName+'_'+formattedDate+'_' +formattedTime;
        downloadElement.download = reportName + '.xls';  // File name

        document.body.appendChild(downloadElement);
        downloadElement.click();

        document.body.removeChild(downloadElement);
    }
}


handleDataInput(event) {
    console.log(event.target.dataset.label);
    console.log(event.target.dataset.pgroup);
    let pgroupId = event.target.dataset.pgroup; 

    let label = event.target.dataset.label; // Either Actual_Domestic_Sales or Domestic_Sales
    let pId = event.target.dataset.parent; // Report Id
    let currentId = event.target.dataset.index; // Child Id
    let valueLabel = event.target.dataset.val;
    let pIndex = this.loadAllData.findIndex(item => item.ParameterId === pgroupId);
    let iIndex = this.loadAllData[pIndex].lineData.findIndex(item => item.Id === pId);
    let cuuIndex = this.loadAllData[pIndex].lineData[iIndex].childData.findIndex(item => item.index == currentId);

    this.loadAllData[pIndex].lineData[iIndex].childData[cuuIndex][label] = event.target.value;
    console.log(Number(event.target.value));

    let rate = Number(event.target.value);
    let salesValue = 0;

    if (valueLabel === "Actual_Domestic_Sales") {
        salesValue = (Number(this.loadAllData[pIndex].lineData[iIndex].childData[cuuIndex].Actual_Domestic_Sales) * rate)/10000;
    } else if (valueLabel === "Domestic_Sales") {
        salesValue = (Number(this.loadAllData[pIndex].lineData[iIndex].childData[cuuIndex].Domestic_Sales) * rate)/10000;
    }

    // Update the salesValue after calculation
    this.loadAllData[pIndex].lineData[iIndex].childData[cuuIndex].salesValue = salesValue;
    //this.calculateSalesValue(this.loadAllData[iIndex].childData[cuuIndex].monthName);
    this.calculateUpdatedSalesValue(this.loadAllData[pIndex].lineData[iIndex].childData[cuuIndex].monthName,pgroupId);
    //calculateUpdatedSalesValue
}

@track hasNewData = [];


isRateInputVisible(childItem) {
    return childItem?.Actual_Domestic_Sales >= 0;
}

isDomRateInputVisible(childItem) {
    return childItem?.Domestic_Sales >= 0;
}


getData() {
    // Show spinner while loading data
    this.showSpinner = true;

    // Fetch sales data
    getSalesDetail()
        .then(result => {
            // Parse the sales data and assign it to allReportData
            this.allReportData = JSON.parse(result);

            setTimeout(() => {
                // Iterate through all the report data
                this.allReportData.forEach(report => {
                    // Check if the report has childData and process it
                    if (report.childData) {
                        report.childData.forEach(child => {
                            // Calculate sales value for each child based on the month
                            //this.calculateSalesValue(child.monthName);
                            
                        });
                    }

                    // Check if loadAllData exists
                    if (this.loadAllData) {
                        // Find the index of the matching product in loadAllData
                        let index = this.loadAllData.findIndex(item => item.ParameterId ==report.ParameterPGId);

                        // If a matching product is found, add the report to lineData
                        if (index !== -1) {
                             this.loadAllData[index].lineData.push(report);
                             this.loadAllData[index].rowSpan = this.loadAllData[index].rowSpan+1;

                            // Log the updated product data for debugging
                            console.log('Updated loadAllData with new report:', JSON.stringify(this.loadAllData[index]));
                        }
                    }
                });

                // Hide the spinner after the processing is done
                this.showSpinner = false;

                // Log the final updated loadAllData for debugging
                console.log('Final loadAllData:', JSON.stringify(this.loadAllData));
                this.filterData();
            }, 1000); // You can adjust this delay if necessary
        })
        .catch(error => {
            // Handle error fetching sales data
            console.error('Error fetching sales data:', error);
            this.showSpinner = false; // Hide the spinner in case of an error
        });
}

@track MonthTotal = [];
@track MonthProductionTotal = [];
@track GrandTotal = [];


filterData(){
        this.loadAllData = this.loadAllData.filter(item => item.lineData && item.lineData.length > 0);

    //console.log('OUTPUT : ',JSON.stringify(this.loadAllData));
        const defaultTemplate = (monthName, index, parameterId) => ({
        salesValue: 0,
        rate: 0,
        targetAmountEdit: false,
        isCurrentMonth: false,
        Production: 0,
        Domestic_Sales: 0,
        monthName: monthName,
        randomNum: 0,
        index: index,
        ParameterId: parameterId
        });


this.loadAllData.forEach(parameter => {
  parameter.lineData.forEach(line => {
    const existingMonths = line.childData.map(item => item.monthName.toUpperCase());
    console.log('existingMonths : ',existingMonths);
    console.log('this.monthList : ',this.monthList);
    this.monthList.forEach((monthName, index) => {
      if (!existingMonths.includes(monthName.toUpperCase())) {
        console.log('iniside if : ',existingMonths);
        line.childData.push(
          defaultTemplate(monthName, index, parameter.ParameterId)
        );
      }
    });

    line.childData.sort((a, b) => a.index - b.index);
  });
});


setTimeout(()=>{
    this.loadAllData.forEach(item => {
        let temp = {
            'label': 'Total of ' + item.ParameterPGName,
            'Id':item.ParameterId, // Use ParameterPGName for the label
            'totalMonthViseValue': [], // Initialize MonthTotal array
        };

        this.monthList.forEach((month, index) => {
            let lineTotal = {
                'name': month, // Month name
                'index': index, // Month index
                'total': 0 // Initialize total value to 0 for each month
            };
            temp.totalMonthViseValue.push(lineTotal);
        });

        let temp1 = {
            'label': 'Total of ' + item.ParameterPGName,
            'Id':item.ParameterId, // Use ParameterPGName for the label
            'totalMonthProdValue': [], // Initialize MonthTotal array
        };

        

        this.monthList.forEach((month, index) => {
            let lineTotal = {
                'name': month, // Month name
                'index': index, // Month index
                'total': 0 // Initialize total value to 0 for each month
            };
            temp1.totalMonthProdValue.push(lineTotal); // Add lineTotal to MonthTotal
        });
        this.MonthTotal.push(temp);
        this.MonthProductionTotal.push(temp1);
    });
    
    setTimeout(() => {
        this.loadAllData.forEach(item => {
            if(item.ParameterId && item.lineData.length > 0){
                item.lineData.forEach(ele=>{
    
                    if(ele.childData.length > 0){
                        ele.childData.forEach(childItem => {
                            if (childItem.monthName) {
                                this.calculateUpdatedProductionValue(childItem.monthName,ele.ParameterPGId);
                                if(childItem.salesValue){
                                this.calculateUpdatedSalesValue(childItem.monthName,ele.ParameterPGId);
                                }

                            }

                    })
                }
            });
        }
        });
        
    }, 1000);

    // setTimeout(() => {
    //     this.loadAllData.forEach(item => {
    //         if(item.ParameterId && item.lineData.length > 0){
    //             item.lineData.forEach(ele=>{
    
    //                 if(ele.childData.length > 0){
    //                     ele.childData.forEach(childItem => {
    //                         if (childItem.monthName && childItem.salesValue) {
    //                             this.calculateUpdatedProductionValue(childItem.monthName,ele.ParameterPGId);
    //                           //  this.calculateUpdatedSalesValue(childItem.monthName,ele.ParameterPGId);

    //                         }

    //                 })
    //             }
    //         });
    //     }
    //     });
        
    // }, 3000);
    },2000)
    
}

generateData(childData) {
    this.monthList.forEach(month => {
        let monthData = childData.find(item => item.monthName === month);
        this.monthValues[month] = monthData ? monthData.Domestic_Sales || 0 : 0;
    });

}

calculateGrandValue(){

}


calculateUpdatedSalesValue(monthName,pId) {
    let total = 0.00;
    this.loadAllData.forEach(item => {
        if(item.ParameterId == pId && item.lineData.length > 0){
            item.lineData.forEach(ele=>{
                if(ele.childData.length > 0){
                    ele.childData.forEach(childItem => {
                        if (childItem.monthName === monthName && childItem.salesValue) {
                            total = total + childItem.salesValue;
                        }
                })
            }
        });
    }
    });

    let pIndex = this.MonthTotal.findIndex(item => item.Id == pId);
    let iIndex = this.MonthTotal[pIndex].totalMonthViseValue.findIndex(item => item.name == monthName);
    this.MonthTotal[pIndex].totalMonthViseValue[iIndex].total = total;
    //this.MonthTotal[pIndex].totalMonthViseValue[iIndex].total = this.MonthTotal[pIndex].totalMonthViseValue[iIndex].total.toFixed(2);
    //setTimeout(() => {
        this.calculateGrand(monthName);
    //}, 10);
    

    
}

calculateGrand(monthName){
    let toatal = 0
    let mindex = this.monthlySales.findIndex(item => item.name == monthName);

this.MonthTotal.forEach(item => {
    item.totalMonthViseValue.forEach(monthData => {
        if(monthName ==monthData.name){
        toatal = toatal + monthData.total;
        }
    });
});

   this.monthlySales[mindex].total = toatal.toFixed(2);
   this.calculateValue();
}

calculateUpdatedProductionValue(monthName,pId) {
    let total = 0;
    this.loadAllData.forEach(item => {
        if(item.ParameterId == pId && item.lineData.length > 0){
            item.lineData.forEach(ele=>{

                if(ele.childData.length > 0){
                    ele.childData.forEach(childItem => {
                        if (childItem.monthName === monthName) {
                            if(childItem.Production){
                                total = total + childItem.Production;
                            }else if(childItem.Actual_Production){
                                total = total + childItem.Actual_Production;
                            }
                        }
                })
            }
        });
    }
    });

    let pIndex = this.MonthProductionTotal.findIndex(item => item.Id == pId);
    let iIndex = this.MonthProductionTotal[pIndex].totalMonthProdValue.findIndex(item => item.name == monthName);

    this.MonthProductionTotal[pIndex].totalMonthProdValue[iIndex].total = total;
}

@track IncommingRollOver = 0;
@track OutgoingRollOver = 0;


handleIncomingReversal(event){
    this.IncommingRollOver = Number(event.target.value);
    this.calculateValue();
}

handleOutgoingReversal(event){
    this.OutgoingRollOver = Number(event.target.value);
    this.calculateValue();

}
 
calculateValue(){
    let fIndex = this.monthlySales.findIndex(item=>item.name==this.currentMonthLabel);
    this.monthlySales[fIndex].Actual_Dispatch = ((Number(this.monthlySales[fIndex].total) + Number(this.IncommingRollOver)/10000) - (this.OutgoingRollOver)/10000).toFixed(2);
}



}