import { LightningElement, wire, track, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CurrentPageReference } from 'lightning/navigation';
import getPicklistValues from '@salesforce/apex/lwcProductInterested.getPicklistValues';
import saveProductInterested from '@salesforce/apex/lwcProductInterested.saveProductInterested';

import getExistingProducts from '@salesforce/apex/lwcProductInterested.getExistingProducts';

import getProducts from '@salesforce/apex/lwcProductInterested.getProducts';



export default class Pagination extends LightningElement {

    @track showSpinner = false;
    recordId;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            console.log('this.recordId ', this.recordId);
        }
    }

    @track allData = [];
    options = [];
    selectedValue = '';
    searchBy = '';

    // Wire the Apex method to fetch picklist values
    @wire(getPicklistValues)
    wiredPicklist({ error, data }) {
        if (data) {
            // If data is returned, format it into the required options format for combobox
            this.options = data.map(item => ({
                label: item.label,  // The label is displayed in the combobox
                value: item.value   // The API value is used for the selected value
            }));
        }
    }

    connectedCallback() {

        this.ShowTableData = [];
        this.AllProductData = [];
        this.getData();
        this.getExist();

    }

    @track Exist =[]; 
    getExist(){
    getExistingProducts({Id:this.recordId}).then(result=>{
        if(result.length> 0)
            this.Exist = result;
        else 
            this.Exist =[];  

    })
 }

    getData() {
        this.ShowTableData = [];
        this.allData = [];
        this.showSpinner = true;
        getProducts({ family: this.selectedValue,ids:this.Exist}).then(result => {
            console.log('result length -->', result.length);

            // Hide spinner as soon as data is received
            this.showSpinner = false;

            if (result != null) {
                // Use map to prepare the new data objects
                let data = result.map((element, index) => {
                    return {
                        "select": false,
                        "disable": true,
                        "index": index,
                        "Id": element.Id,
                        "ProductCode": element.ProductCode,
                        "Name": element.Name,
                        "family":element.Family,
                        "volume": 0,
                        "price": 0
                    };
                });

                // Merge the new data with the existing data array
                this.allData = [...this.allData, ...data];
                console.log('this.allData Total ->', this.allData.length);
                this.syncSelectedToAllData();

                // Now that the data is fully loaded, call paginateData
                this.paginiateData(JSON.stringify(this.allData));
            }
        }).catch(error => {
            console.error('Error fetching products:', error);
            // Handle error (e.g., display a message)
        });

    }

    syncSelectedToAllData() {
        console.log('this.selectedData',this.selectedData.length);
        
        this.allData.forEach(product => {
            let selectedProduct = this.selectedData.find(item => item.Id == product.Id);
            if (selectedProduct) {
                product.select = selectedProduct.select;
                product.volume = selectedProduct.volume;
                product.price = selectedProduct.price;
            }
        });
    }    


    handlePriceChange(event) {

        let eve_Id = event.target.dataset.id;
        let label = event.target.dataset.label;
        let index = this.allData.findIndex(item => item.Id == eve_Id);
        this.allData[index][label] = event.target.value;
        this.recordPerPage(this.page, this.allData);
        console.log('Changed->', JSON.stringify(this.allData[index]));

    }

    showSuccess(title, msg, varinat) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: varinat,
        });
        this.dispatchEvent(evt);

    }

    handleValueChange(event) {
        this.selectedValue = event.target.value;
        this.page = 1;
        this.getData();
    }


    @track selectedData =  [];
    handleSelect(event) {
        //if(event.target.checked){
        let eve_Id = event.target.dataset.id;
        let index = this.allData.findIndex(item => item.Id == eve_Id);
        this.allData[index].select = event.target.checked;
        this.allData[index].volume = '';
        this.allData[index].price = '';
        this.recordPerPage(this.page, this.allData);
        if(this.allData[index].select){
            this.selectedData.push(this.allData[index]);
        }else {
            // Check if item is already in selectedData before splicing it
            let indexInSelectedData = this.selectedData.findIndex(item => item.Id == eve_Id);
            if (indexInSelectedData !== -1) {
                // Only remove if the item exists in selectedData
                this.selectedData.splice(indexInSelectedData, 1);
            }
        }
    
        
    }


    save(){

        let tempSaveData = [];
        let validate = true;
        
        for (let element of this.selectedData) {
            if (element.select) {
                // Validate Volume
                if (element.volume === '' || element.volume === undefined || element.volume === 0) {
                    this.showSuccess('Error', `Please Fill Volume in Kgs for Product ${element.Name}`, 'Error');
                    validate = false;
                    break; // Exit the loop early since validation failed
                }
                // Validate Price
                else if (element.price === '' || element.price === undefined || element.price === 0) {
                    this.showSuccess('Error', `Please Fill Expected Price for Product ${element.Name}`, 'Error');
                    validate = false;
                    break; // Exit the loop early since validation failed
                } else {
                    tempSaveData.push(element); // Only push if both validations pass
                }
            }
        }
        
    if(tempSaveData.length > 0){

    }else{
        this.showSuccess('Error', 'Please Select Atleast One Product', 'Error');
        validate =false;
    }

  console.log('validate-->',validate);
  
    if(validate){

        console.log('inside Cmp-->', JSON.stringify(tempSaveData));
        
        saveProductInterested({ Id: this.recordId, JS: JSON.stringify(tempSaveData) }).then(result => {
            console.log('result-->',JSON.stringify(result));
            
            if (result.message == 'success') {
                this.showSuccess('success', 'Record Created Successfully !!!', 'Success');
                this.handleCancel();

                setTimeout(() => {
                    window.location.reload();
                }, 1000);
            } else {
                this.showSuccess('Error', result.message, 'error');
            }
        })
    }

    }
    handleCancel() {
        const closeActionEvent = new CloseActionScreenEvent();
        this.dispatchEvent(closeActionEvent);
    }

    //pagination
    @track filteredData = [];

   

    @track SelectedRecordCount = 0;
    @track isModalOpen = false;
    @track ShowSelected = true;
    @track PriceBook = '';
    @track ShowTableData = [];

    @track AllProductData = [];
    @track lstResult = [];
    @track hasRecords = true;
    @track isFirstPage = true;
    @track isProductSelect = true;

    handleSearch(event) {
        this.searchBy = event.target.value;
        console.log('searchBy-->', this.searchBy);
        this.filteredData = [];

     if(this.searchBy !=null && this.searchBy !='' && this.searchBy!=undefined){
        this.paginationDataList = this.allData;
        for (let i = 0; i < this.paginationDataList.length; i++) {


            if (this.paginationDataList[i].ProductCode != '' && this.allData[i].ProductCode != null) 
                {
                if (this.paginationDataList[i].ProductCode.toLowerCase().includes(this.searchBy.toLowerCase() ||
                    this.paginationDataList[i].ProductCode.toLowerCase().includes(this.searchBy.toLowerCase()))
                ){
                    this.filteredData.push(this.paginationDataList[i]);
                    }
                 {
                }
            }
        }

        // Reset pagination to first page whenever search changes
        this.page = 1;
        this.paginiateData(JSON.stringify(this.filteredData));
       // this.recordPerPage(this.page, this.filteredData);
        
       }else{
        this.page = 1;
        this.paginiateData(JSON.stringify(this.allData));
       // this.recordPerPage(this.page, this.paginationDataList);
       }
    }

    @track paginationDataList;
    paginiateData(results) {
        let data = JSON.parse(results);
        this.paginationDataList = data;
        this.totalRecountCount = data.length;
        this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
        this.ShowTableData = this.paginationDataList.slice(0, this.pageSize);
        ////console.log('totalRecountCount ', this.totalRecountCount);
        this.endingRecord = this.pageSize;
        this.error = undefined;

    }

    


    page = 1;
    items = [];
    data = [];

    startingRecord = 1;
    endingRecord = 0;
    pageSize = 10;
    totalRecountCount = 0;
    totalPage = 0;


    get bDisableFirst() {
        return this.page == 1;
    }
    get bDisableLast() {
        return this.page == this.totalPage;
    }


    firstPage() {
        this.page = 1;

        this.recordPerPage(this.page, this.paginationDataList);
        //console.log('this.SelectedProductData 604', this.SelectedProductData.length);
        //this.template.querySelector('[data-id="datatable"]').selectedRows = this.SelectedProductData;

    }

    previousHandler() {
        if (this.page > 1) {
            this.page = this.page - 1;
            //console.log('this.SelectedProductData 611', this.SelectedProductData.length);
            this.recordPerPage(this.page, this.paginationDataList);
        }
        // this.template.querySelector('[data-id="datatable"]').selectedRows = this.SelectedProductData;

    }

    nextHandler() {
        if ((this.page < this.totalPage) && this.page !== this.totalPage) {
            this.page = this.page + 1;
            //console.log('this.SelectedProductData 619', this.SelectedProductData.length);
            this.recordPerPage(this.page, this.paginationDataList);
        }

        //console.log('json -->', JSON.parse(this.template.querySelector('[data-id="datatable"]').selectedRows));



    }

    lastPage() {

        this.page = this.totalPage;
        if (this.page > 1) {
            this.recordPerPage(this.page, this.paginationDataList);
        }
        //this.template.querySelector('[data-id="datatable"]').selectedRows = this.SelectedProductData;

    }


    recordPerPage(page, data) {
        let tempdata = data;
        this.startingRecord = ((page - 1) * this.pageSize);
        this.endingRecord = (this.pageSize * page);
        this.endingRecord = (this.endingRecord > this.totalRecountCount) ? this.totalRecountCount : this.endingRecord;
        this.ShowTableData = tempdata.slice(this.startingRecord, this.endingRecord);
        this.startingRecord = this.startingRecord + 1;
    }
}