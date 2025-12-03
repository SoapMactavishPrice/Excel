public class QuotePdfController {
    public Quote quoteRecord { get; set; }
    public List<QuoteLineItemWrapper> lineItems { get; set; }

    public Decimal totalTax { get; set; } // Placeholder, not used
    public Decimal grandTotal { get; set; }
    public String formattedDate { get; set; }
    public String salespersonName { get; set; }
    public String packagingTypesString { get; set; } // For comma-separated packaging types

    public QuotePdfController(ApexPages.StandardController stdCtrl) {
        this.quoteRecord = [
            SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, INCO_Terms__c, Offer_Validity__c, Carriers__c, Transport__c, Payment_Terms__c,
                   Ship_To__c, Bill_To__c,
                   Bill_To__r.Name,
            	   Bill_To__r.Address_1__c,
             	   Bill_To__r.Address_2__c,
                   Bill_To__r.City__r.Name,
                   Bill_To__r.State__r.Name,
                   Bill_To__r.Postal_Code__r.Name,
            	   Bill_To__r.Country__r.Name,
            	   
                   (SELECT Id, Product2Id, Product2.Name, Quantity, UnitPrice, Unit__c,
                           Type_of_Packing__c, TotalPrice, CreatedBy.Name
                    FROM QuoteLineItems)
            FROM Quote
            WHERE Id = :stdCtrl.getId()
        ];

        this.lineItems = new List<QuoteLineItemWrapper>();
        Integer serial = 1;
        Decimal subtotal = 0;
        totalTax = 0;

        Set<String> packagingTypes = new Set<String>();

        for (QuoteLineItem qli : quoteRecord.QuoteLineItems) {
            subtotal += qli.TotalPrice;

            if (qli.Type_of_Packing__c != null) {
                packagingTypes.add(qli.Type_of_Packing__c);
            }

            lineItems.add(new QuoteLineItemWrapper(
                serial++,
                qli.Product2 != null ? qli.Product2.Name : '',
                qli.TotalPrice,
                qli.Quantity,
                qli.Unit__c,
                qli.Type_of_Packing__c,
                '', // No CGST
                '', // No SGST
                ''  // No IGST
            ));
        }

        // Set the packaging types as a comma-separated string
        packagingTypesString = String.join(new List<String>(packagingTypes), ', ');

        grandTotal = subtotal; // No tax included
        formattedDate = quoteRecord.CreatedDate.format('dd-MM-yyyy');
        salespersonName = quoteRecord.CreatedBy.Name;
    }

    public class QuoteLineItemWrapper {
        public Integer serialNo { get; set; }
        public String productName { get; set; }
        public Decimal price { get; set; }
        public Decimal quantity { get; set; }
        public String unit { get; set; }
        public String packaging { get; set; }
        public String cgst { get; set; }
        public String sgst { get; set; }
        public String igst { get; set; }
        public Decimal Subtotal { get; set; }

        public QuoteLineItemWrapper(Integer serialNo, String productName, Decimal price, Decimal quantity, String unit, String packaging, String cgst, String sgst, String igst) {
            this.serialNo = serialNo;
            this.productName = productName;
            this.price = price;
            this.quantity = quantity;
            this.unit = unit;
            this.packaging = packaging;
            this.cgst = cgst;
            this.sgst = sgst;
            this.igst = igst;
            this.Subtotal = price;
        }
    }
}