import { LightningElement ,track, api, wire} from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CurrentPageReference } from 'lightning/navigation';
export default class LwcAssessmentAnswerClone extends LightningElement {
    recordId;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            
            //it gets executed before the connected callback and avilable to use
            this.recordId = currentPageReference.state.recordId;
            console.log('this.recordId ', this.recordId);
        }
    }

}