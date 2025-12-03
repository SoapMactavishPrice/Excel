import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDefaultFilterValues from '@salesforce/apex/ProductionSalesController.getDefaultFilterValues';
import getProductsData from '@salesforce/apex/ProductionSalesController.getProductsData';
import getProductionDetail from '@salesforce/apex/ProductionSalesController.getProductionDetail';
import save from '@salesforce/apex/ProductionSalesController.save';
import getSelectedFiscalYear from '@salesforce/apex/ProductionSalesController.getSelectedFiscalYear';

const monthNames = [
    "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
    "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"
];



export default class Lwc_SNOPLevelOne extends LightningElement {
    @track fiscId;
    @track allProductData = [];
    @track filters = [];
    @track showSpinner = false;
    @track startDate;
    @track fyEndDate;
    @track isFirstPage = true;
    @track isLastPage = false;

    @track generatedIds = new Set();


    connectedCallback() {
        this.getDefaultFilterValues();
        this.getProductWrap();
    }



    @track monthList = [];
    getMonthList(startDate, endDate) {
        this.startDate = new Date(startDate); // Start date of the fiscal year
        this.fyEndDate = new Date(endDate);   // End date of the fiscal year
        const currentDate = new Date();  // Current date
        const currentMonthIndex = currentDate.getMonth();  // Current month index (0-11)
        const currentYear = currentDate.getFullYear();    // Current year

        this.monthList = [];  // Will hold the list of months to return

        const monthsToInclude = 4; // Total months to return (1 current month + next 3 months)
        let monthCount = 0;  // Counter to keep track of the number of months included

        // Loop through the current month and the next three months
        while (monthCount < monthsToInclude) {
            const monthIndex = (currentMonthIndex + monthCount) % 12;  // Get the month index, wrapping around the year if needed
            const year = currentYear + Math.floor((currentMonthIndex + monthCount) / 12); // Handle year rollover

            const monthName = monthNames[monthIndex].toUpperCase();  // Get month name
            if (monthCount === 0) {
                 // If it's the current month, add "Plan" and "Actual"
                this.monthList.push(`PLAN ${monthName}`);
                this.monthList.push(`ACTUAL ${monthName}`);
                
            } else {
                this.monthList.push(monthName);
            }

            monthCount++;  // Increment the month counter
        }

        return this.monthList;

    }

    @track fy_startDate;
    @track fy_endDate;
    @track OriginaData = [];
    getDefaultFilterValues() {
        new Promise((resolve, reject) => {
            setTimeout(() => {
                getDefaultFilterValues()
                    .then((data) => {
                        this.filters = JSON.parse(data);
                        this.fiscId = this.filters.Fiscal_Year__c;
                        this.fy_startDate = this.filters.startDate;
                        this.fy_endDate = this.filters.endDate;
                        console.log('this.filters', this.fiscId);
                        this.getMonthList(this.filters.startDate, this.filters.endDate);

                        resolve('Ok');
                    })
                    .catch((error) => {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            variant: 'error',
                            message: error.message
                        }));

                        reject('Error');
                    })
                    .finally(() => {
                        this.showSpinner = false;
                    });
            }, 0);
        });
    }

    onFilterInputChange(event) {
        this.displayedData = [];
        this.allPaginationData = [];
        this.OriginaData = [];
        console.log('88:>> ', event.target.fieldName);
        if (event.target.fieldName == 'Fiscal_Year__c') {
            this.fiscId = event.target.value;
            if (this.fiscId) {
                this.getSelectedFiscal();
                this.getProductionDetailWrap();
            }
        }
    }

    getSelectedFiscal() {
        getSelectedFiscalYear({ Id: this.fiscId }).then(result => {
            this.filters = JSON.parse(result);
            this.fy_startDate = this.filters.startDate;
            this.fy_endDate = this.filters.endDate;
        })
    }

    @track AllProductData = [];
    @track allProductionLineData = [];
    getProductWrap() {
        new Promise((resolve, reject) => {
            setTimeout(() => {
                getProductsData()
                    .then((data) => {
                        this.AllProductData = JSON.parse(data);
                        console.log('this.AllProductData-->', JSON.stringify(this.AllProductData));

                        resolve('Ok');
                        if (this.fiscId) {

                            this.getProductionDetailWrap();
                        }
                    })
                    .catch((error) => {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            variant: 'error',
                            message: error.message
                        }));

                        reject('Error');
                    })
                    .finally(() => {
                        this.showSpinner = false;
                    });
            }, 0);
        });
    }

    getProductionDetailWrap() {
        console.log('call this');

        new Promise((resolve, reject) => {
            setTimeout(() => {
                getProductionDetail({ fiscalYear: this.fiscId })
                    .then((data) => {
                        this.allProductionLineData = JSON.parse(data);
                        console.log('getProductionDetailWrap-->', JSON.stringify(this.allProductionLineData));

                        resolve('Ok');
                        this.arrangeData();
                        this.showSpinner = true;

                    })
                    .catch((error) => {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            variant: 'error',
                            message: error.message
                        }));

                        reject('Error');
                    })
                    .finally(() => {
                        this.showSpinner = false;
                    });
            }, 0);
        });
    }

    @track allPaginationData = [];

    arrangeData() {


        if (Array.isArray(this.allProductionLineData) && this.allProductionLineData != null) {
            console.log('inside if');

            const productionLineMap = new Map(this.allProductionLineData.map(item => [item.ParameterId, item]));
            this.AllProductData.forEach(el => {
                let matchingEle = this.allProductionLineData.find(ele => ele.ParameterId == el.ParameterId);
                if (!matchingEle) {
                    let tempResult = this.createTempResult(el); // Create a result based on AllProductData element
                    this.allPaginationData.push(tempResult);
                } else {
                    let tempResult = this.createTempResult(matchingEle); // Create a result based on matching element
                    this.allPaginationData.push(tempResult);
                }


            });

        } else {
            console.log('inside else');

            this.AllProductData.forEach(ele => {
                let tempResult = this.createTempResult(ele);
                this.allPaginationData.push(tempResult);
            });
        }

        console.log('-->', JSON.stringify(this.allPaginationData));
        this.OriginaData = this.allPaginationData;
        this.updatePagination();
        setTimeout(() => {
            this.showSpinner = false;
        }, 3000);
    }


    getCurrentMonth() {
        const currentMonth = new Date().toLocaleString('default', { month: 'long' }); // Returns the current month in full text format (e.g., "March")
        return currentMonth;
    }

    createTempResult(ele) {
        let tempResult = {
            'Id': ele.Id, // Unique identifier
            'ParameterId': ele.ParameterId,
            'ParameterName': ele.ParameterName,
            'childData': [],
        };

        if (ele.childData != null && ele.childData != undefined) {
            // Step 1: Map the ele.childData to a dictionary for faster lookup by monthName
            const monthDataMap = new Map();
            ele.childData.forEach(e => {
                monthDataMap.set(e.monthName, e); // Use monthName as the key for quick lookup
            });
            console.log('monthDataMap-->',monthDataMap);
            this.monthList.forEach((month, index) => {
                console.log('monthDataMap-->',month);
                const monthData = monthDataMap.get(month);
                if (monthData) {
                    let childMap = this.createChildMap(
                        ele.ParameterId,
                        month,
                        index,
                        monthData.ParameterId,
                        monthData.Closing_Stock,
                        monthData.Domestic_Sales,
                        monthData.Export_Sales,
                        monthData.Opening_Stock,
                        monthData.production_Stock,
                        monthData.Total_Stock,
                        monthData.Total_Sales,
                        monthData.CC_Sales,
                        monthData.isCurrentMonth,
                        monthData.Actual_Closing_Stock,
                        monthData.Actual_Domestic_Sales,
                        monthData.Actual_Export_Sales,
                        monthData.Actual_Opening_Stock,
                        monthData.Actual_production_Stock,
                        monthData.Actual_Total_Stock,
                        monthData.Actual_Total_Sales,
                        monthData.Actual_CC_Sales
                    );
                    tempResult.childData.push(childMap);
                } else {
                    let childMap = this.createChildMap(
                        ele.ParameterId,
                        month,
                        index,
                        '',0,0,0,0,0,0,0,0,false, 0, 0, 0, 0, 0, 0, 0, 0
                    );
                    tempResult.childData.push(childMap);
                }
            });
        }
        else {
            this.monthList.forEach((month, index) => {
               
                let childMap = this.createChildMap(ele.ParameterId, month, index, '', 0, 0, 0, 0, 0, 0, 0, 0,false, 0, 0, 0, 0, 0, 0, 0, 0);
                tempResult.childData.push(childMap);
            });
        }

        return tempResult;
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
    getMonthStartEndDates(monthName) {
        let fyStartDate = new Date(this.fy_startDate);  // Example: '2024-04-01'
        let fyEndDate = new Date(this.fy_endDate);      // Example: '2025-03-31'

        const targetMonthIndex = monthNames.indexOf(monthName.toUpperCase());

        let targetYear = fyStartDate.getFullYear();
        if (targetMonthIndex < fyStartDate.getMonth()) {
            targetYear += 1;  // We need to move to the next fiscal year if the month is before the fiscal start
        }

        let monthStartDate = new Date(targetYear, targetMonthIndex, 1);

        let monthEndDate = new Date(targetYear, targetMonthIndex + 1, 0);

        return { monthStartDate, monthEndDate };
    }

    setMonthStatus(monthName) {
        const { monthStartDate, monthEndDate } = this.getMonthStartEndDates(monthName);
        let currentDate = new Date();

        let targetAmountEdit = false;

        let fyStartDate = new Date(this.fy_startDate);  // Example: '2024-04-01'
        if (fyStartDate < currentDate) {
            if (monthStartDate < currentDate && monthEndDate < currentDate) {
                targetAmountEdit = true;
            }
            else if (monthStartDate <= currentDate && monthEndDate >= currentDate) {
                targetAmountEdit = false;
            }
        } else {
            targetAmountEdit = false;
        }
        return targetAmountEdit;
    }


    @track currentDateNew = new Date();
    @track currentMonthNew = this.currentDateNew.getMonth(); // March is 2 (0-based index)
    @track currentYearNew = this.currentDateNew.getFullYear();

    createChildMap(parameterId, month, index, id, Closing_Stock, Domestic_Sales, Export_Sales, Opening_Stock, production_Stock, Total_Stock, Total_Sales, CC_Sales,isCurrentMonth,
        Actual_Closing_Stock, Actual_Domestic_Sales, Actual_Export_Sales, Actual_Opening_Stock, Actual_production_Stock, Actual_Total_Stock, Actual_Total_Sales,Actual_CC_Sales
    ) {

        const isCurrentMonthCheck = month.includes('ACTUAL');


        let monthIndex = new Date(`${month} 1, ${this.currentYearNew}`).getMonth(); // This will give month index for "March", "April", etc.
        let randomId = this.generateRandomNum();
        let childMap = {
            'index': index,
            'Id': id,
            'pId': `${parameterId}-${month}-${index}-${randomId}`, // Added current timestamp (milliseconds) to the key
            'ParameterId': parameterId,
            'Closing_Stock': Closing_Stock,
            'Domestic_Sales': Domestic_Sales,
            'Export_Sales': Export_Sales,
            'monthName': month,
            'Opening_Stock': Opening_Stock,
            'production_Stock': production_Stock,
            'Total_Stock': Total_Stock,
            'Total_Sales': Total_Sales,
            'CC_Sales': CC_Sales,
            'isCurrentMonth':isCurrentMonthCheck,
            'Actual_Closing_Stock': isCurrentMonthCheck ? Actual_Closing_Stock : null,
            'Actual_Domestic_Sales': isCurrentMonthCheck ? Actual_Domestic_Sales : null,
            'Actual_Export_Sales': isCurrentMonthCheck ? Actual_Export_Sales : null,
            'Actual_Opening_Stock': isCurrentMonthCheck ? Actual_Opening_Stock : null,
            'Actual_production_Stock': isCurrentMonthCheck ? Actual_production_Stock : null,
            'Actual_Total_Stock': isCurrentMonthCheck ? Actual_Total_Stock : null,
            'Actual_Total_Sales': isCurrentMonthCheck ? Actual_Total_Sales : null,
            'Actual_CC_Sales': isCurrentMonthCheck ? Actual_CC_Sales : null,
            'targetAmountEdit': this.setMonthStatus(month),
        };
        return childMap;
    }

    //pagination

    @track currentPage = 1;
    @track rowsPerPage = 10;
    @track totalPages = 1;
    @track displayedData = []; // The data to be shown on the current page
    @track searchQuery = '';

    updatePagination() {
        if (this.allPaginationData.length === 0) {
            this.totalPages = 0;
        } else {
            this.totalPages = Math.ceil(this.allPaginationData.length / this.rowsPerPage);
        }
        // Always reset to the first page if no data is available
        this.currentPage = 1;
        this.displayDataForPage(this.currentPage);
    }
    
    displayDataForPage(page) {
        this.displayedData = [];
        this.showSpinner = true;
        setTimeout(() => {
        this.showSpinner = false;
            const start = (page - 1) * this.rowsPerPage;
        const end = page * this.rowsPerPage;
        this.displayedData = this.allPaginationData.slice(start, end);
        console.log('displayedData-->',this.displayedData.length);
        }, 10);
        
        
    }

    changePage(event) {
        const page = event.target.dataset.page;
        if (page === 'next' && this.currentPage < this.totalPages) {
            this.currentPage++;
        } 
        else if (page === 'prev' && this.currentPage > 1) {
            this.currentPage--;
        }
        this.displayDataForPage(this.currentPage);
        this.getDisabledButton();
    }
    


    getDisabledButton() {
        this.isFirstPage = this.currentPage == 1 ? true : false;
        this.isLastPage = this.currentPage == this.totalPages ? true : false;
    }




    //searching



    handleSearch(event) {
        this.searchQuery = event.target.value;
        this.filterData();
    }

    filterData() {
        if (this.searchQuery.trim()) {
            this.allPaginationData = this.OriginaData.filter(item => {
                return item.ParameterName.toLowerCase().includes(this.searchQuery.toLowerCase());
            });

        } else {
            this.allPaginationData = this.OriginaData;
        }
        this.currentPage = 1;
        this.updatePagination();
    }

    //onChangeEvent


    ActualonDataInput(event) {
        console.log(event);
        let label = event.target.dataset.label;
        let pId = event.target.dataset.parent;
        let currentId = event.target.dataset.id;
        let iIndex = this.OriginaData.findIndex(item => item.ParameterId === pId);
        let cuuIndex = this.OriginaData[iIndex].childData.findIndex(item => item.pId === currentId);
        this.OriginaData[iIndex].childData[cuuIndex][label] = event.target.value;
        //console.log(' varlidate-v1->', JSON.stringify(this.OriginaData[iIndex].childData[cuuIndex]));
        this.calculateTotalSales_Actual(iIndex, cuuIndex);


        
        //this.calculateTotalSales(index,cIndex);
    }


    calculateTotalSales_Actual(pIndex, cindex) {
        let g_Opening_Stock = this.OriginaData[pIndex].childData[cindex]['Actual_Opening_Stock'] > 0 ? this.OriginaData[pIndex].childData[cindex]['Actual_Opening_Stock'] : 0;
        let g_production_Stock = this.OriginaData[pIndex].childData[cindex]['Actual_production_Stock'] > 0 ? this.OriginaData[pIndex].childData[cindex]['Actual_production_Stock'] : 0;
        let g_Domestic_Sales = this.OriginaData[pIndex].childData[cindex]['Actual_Domestic_Sales'] > 0 ? this.OriginaData[pIndex].childData[cindex]['Actual_Domestic_Sales'] : 0;
        let g_Export_Sales = this.OriginaData[pIndex].childData[cindex]['Actual_Export_Sales'] > 0 ? this.OriginaData[pIndex].childData[cindex]['Actual_Export_Sales'] : 0;
        let g_CC_Sales = this.OriginaData[pIndex].childData[cindex]['Actual_CC_Sales'] > 0 ? this.OriginaData[pIndex].childData[cindex]['Actual_CC_Sales'] : 0;
        this.OriginaData[pIndex].childData[cindex]['Actual_Total_Stock'] = Number(g_Opening_Stock) + Number(g_production_Stock);
        this.OriginaData[pIndex].childData[cindex]['Actual_Total_Sales'] = Number(g_Domestic_Sales) + Number(g_Export_Sales) + Number(g_CC_Sales);;
        this.OriginaData[pIndex].childData[cindex]['Actual_Closing_Stock'] = Number(this.OriginaData[pIndex].childData[cindex]['Actual_Total_Stock']) - Number(this.OriginaData[pIndex].childData[cindex]['Actual_Total_Sales']);
        let tempIndex = cindex;
        this.OriginaData[pIndex].childData.forEach(ele => {
            setTimeout(() => {
            if (ele.index > cindex) {
                        tempIndex = ele.index-1;
                        if(this.OriginaData[pIndex].childData[tempIndex]['Actual_Closing_Stock']  !=null ){
                          ele['Opening_Stock'] = this.OriginaData[pIndex].childData[tempIndex]['Actual_Closing_Stock'] ;
                        }else {
                            ele['Opening_Stock'] = this.OriginaData[pIndex].childData[tempIndex]['Closing_Stock'] ;
                        }
                        this.calculateTotalSales(pIndex, ele.index);

            }
        }, 100);
        });
    }

    onDataInput(event) {
        let label = event.target.dataset.label;
        let pId = event.target.dataset.parent;
        let currentId = event.target.dataset.id;

        console.log(label, pId, currentId, event.target.value);
        

        let iIndex = this.OriginaData.findIndex(item => item.ParameterId === pId);
        let cuuIndex = this.OriginaData[iIndex].childData.findIndex(item => item.pId === currentId);
        this.OriginaData[iIndex].childData[cuuIndex][label] = event.target.value;
        console.log(' varlidate-->', JSON.stringify(this.OriginaData[iIndex].childData[cuuIndex]));
        this.calculateTotalSales(iIndex, cuuIndex);

        let tempIndex = cuuIndex;
        if(cuuIndex > 1){
        this.OriginaData[iIndex].childData.forEach(ele => {
            setTimeout(() => {
            if (ele.index > cuuIndex) {
                        tempIndex = ele.index-1;
                        ele['Opening_Stock'] = this.OriginaData[iIndex].childData[tempIndex]['Closing_Stock'] ;
                        this.calculateTotalSales(iIndex, ele.index);

            }
        }, 100);
        
        });
    }
    }


    calculateTotalSales(pIndex, cindex) {
        let g_Opening_Stock = this.OriginaData[pIndex].childData[cindex]['Opening_Stock'] >= 0 ? this.OriginaData[pIndex].childData[cindex]['Opening_Stock'] : 0;
        let g_production_Stock = this.OriginaData[pIndex].childData[cindex]['production_Stock'] >= 0 ? this.OriginaData[pIndex].childData[cindex]['production_Stock'] : 0;
        let g_Domestic_Sales = this.OriginaData[pIndex].childData[cindex]['Domestic_Sales'] >= 0 ? this.OriginaData[pIndex].childData[cindex]['Domestic_Sales'] : 0;
        let g_Export_Sales = this.OriginaData[pIndex].childData[cindex]['Export_Sales'] >= 0 ? this.OriginaData[pIndex].childData[cindex]['Export_Sales'] : 0;
        let g_CC_Sales = this.OriginaData[pIndex].childData[cindex]['CC_Sales'] >= 0 ? this.OriginaData[pIndex].childData[cindex]['CC_Sales'] : 0;

        this.OriginaData[pIndex].childData[cindex]['Total_Stock'] = Number(g_Opening_Stock) + Number(g_production_Stock);
        this.OriginaData[pIndex].childData[cindex]['Total_Sales'] = Number(g_Domestic_Sales) + Number(g_Export_Sales) + Number(g_CC_Sales);;
        this.OriginaData[pIndex].childData[cindex]['Closing_Stock'] = Number(this.OriginaData[pIndex].childData[cindex]['Total_Stock']) - Number(this.OriginaData[pIndex].childData[cindex]['Total_Sales']);
         
    }


    SaveData() {
        console.log('this.OriginaData-->', JSON.stringify(this.OriginaData));

        // Deep clone the original data to avoid mutating it
        let dataToSave = this.cleanData(JSON.parse(JSON.stringify(this.OriginaData)));

        console.log('dataToSave-->', dataToSave.length,JSON.stringify(dataToSave));

        this.showSpinner = true;
        if (dataToSave.length > 0) {
            save({ jsonData: JSON.stringify(dataToSave), fiscalYear: this.fiscId }).then(result => {
                if (result == 'Success') {
                    this.showToastEvent('Success', 'Success', 'Data Saved Successfully');
                    setTimeout(() => {
                        this.showSpinner = false;
                        window.location.reload();
                    }, 2000);
                } else {
                    this.showToastEvent('Error', 'Error', result);
                    setTimeout(() => {
                        this.showSpinner = false;
                    }, 2000);
                }
            })
        } else {
            this.showToastEvent('Error', 'Error', 'Please fill Product Plan Details');
            setTimeout(() => {
                this.showSpinner = false;
            }, 2000);
        }

    }



    showToastEvent(title, varian, vari) {

        this.dispatchEvent(new ShowToastEvent({
            title: title,
            variant: varian,
            message: vari
        }));
    }

    cleanData(data) {
        const hasValidValue = (child) => {
        return parseFloat(child.Total_Stock) > 0 || parseFloat(child.Total_Sales) > 0 || parseFloat(child.Closing_Stock) > 0 ||
        parseFloat(child.Actual_Total_Stock) > 0 || parseFloat(child.Actual_Total_Sales) > 0 || parseFloat(child.Actual_Closing_Stock) > 0;
                
        };

        return data
            .map(parent => {
                
                const validChildren = parent.childData.filter(child => hasValidValue(child));

                if (validChildren.length > 0) {
                    parent.childData = validChildren;
                    return parent;
                } else {
                    return null;
                }
            })
            .filter(parent => parent !== null);
    }

   
}