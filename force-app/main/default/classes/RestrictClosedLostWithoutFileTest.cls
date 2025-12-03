@isTest
public class RestrictClosedLostWithoutFileTest {
    
    // Helper method to create a test Opportunity
    public static Opportunity createOpportunity(String stageName) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = stageName,
            CloseDate = System.today().addDays(30)
        );
        insert opp;
        return opp;
    }
    
    // Helper method to create an attachment (ContentDocumentLink)
    public static void createAttachment(Opportunity opp) {
        // Create ContentVersion (attachment)
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Test file content')  // File content as a Blob
        );
        insert contentVersion;
        
        // Re-query ContentVersion to get the ContentDocumentId
        contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
        
        // Create a ContentDocumentLink to associate the file with the Opportunity
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = opp.Id,
            ContentDocumentId = contentVersion.ContentDocumentId,
            ShareType = 'V'  // View permission
        );
        insert cdl;
    }
    
    @isTest
    static void testRestrictClosedLostWithoutFile() {
        // Create Opportunities for testing
        Opportunity opp1 = createOpportunity('Prospecting');
        Opportunity opp2 = createOpportunity('Prospecting');
        
        // Create an attachment for opp1
        createAttachment(opp1);
        
        // Simulate updating the Opportunities
        Test.startTest();
        
        // Update opp1 to Closed Lost (with attachment) - should succeed
        opp1.StageName = 'Closed Lost';
        
        // Update opp2 to Closed Lost (without attachment) - should fail
        opp2.StageName = 'Closed Lost';
        
        try {
            update new List<Opportunity>{opp1, opp2};
                System.assert(false, 'Expected validation exception was not thrown.');
        } catch (DmlException e) {
        }
        
        Test.stopTest();
        
        // Ensure opp1 was updated successfully
        Opportunity updatedOpp1 = [SELECT Id, StageName FROM Opportunity WHERE Id = :opp1.Id];
    }
    
}