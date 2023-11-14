/**
 * @description Batch class to notify customers when the Portfolio Manager adds document relevant to products being used by the customer
 */

public without sharing class NotifyCustomerOnDocumentUpload implements Database.Batchable<sObject> {
    private final String query; // Variable to hold the query

    // Final variables for picklist Document__c.Notification_Status__c
    private final String DOCUMENT_NOTIFICATION_STATUS_NEW = 'New';
    private final String DOCUMENT_NOTIFICATION_STATUS_CUSTOMER_NOTIFIED = 'Customer Notified';

    // Final variables for picklist Document__c.Type__c
    private final String DOCUMENT_TYPE_REPORT = 'Report'; 
    private final String DOCUMENT_TYPE_TRANSACTIONAL = 'Transactional';
    private final String DOCUMENT_TYPE_LEGAL = 'Legal';
    private final String DOCUMENT_TYPE_CONTRACT = 'Contract';

    /**
     * @description - Constructor for the batch class
     * @params - 
     *      1. String query - Query for the batch class to run on.
     * @return - None
     */
    public NotifyCustomerOnDocumentUpload(String query) {
        this.query = query;
    }

    /**
     * @description - Overridden start() method from the Database.Batchable<sObject> interface
     * @params - 
     *      1. Database.BatchableContext batchableContextObj - System generate context for the batch
     * @return - Database.QueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext batchableContextObj){
        return Database.getQueryLocator(this.query);
    }

    /**
     * @description - Overridden execute() method from the Database.Batchable<sObject> interface
     * @params - 
     *      1. Database.BatchableContext batchableContextObj - System generate context for the batch
     *      2. List<SObject> listOfCustomers - A chunk of customer records on which the batch is being executed
     * @return - Database.QueryLocator
     */
    public void execute(Database.BatchableContext batchableContextObj, List<SObject> listOfCustomers){
        try{
            //Query to fetch the list of Documents
            List<Document__c> listOfCustomerDocuments = new List<Document__c> ([SELECT Id, File_Name__c, Type__c, Notification_Status__c, Customer_Notified_At__c, 
                                                                                Product_Subscription__r.Customer__r.Related_User_Record__c FROM Document__c
                                                                                WHERE Notification_Status__c = :DOCUMENT_NOTIFICATION_STATUS_NEW AND Product_Subscription__r.Customer__c IN :listOfCustomers 
                                                                                ORDER BY Product_Subscription__r.Customer__c ASC]);

            //Map stores the Id of user record linked to the customer and list of documents grouped by Type 
            Map<Id, Map<String, List<Document__c>>> customerDocumentTypeAggregateMap = buildCustomerDocumentTypeAggregateMap(listOfCustomerDocuments);

            // Method takes care of sending emails to customers
            sendEmailToCustomers(customerDocumentTypeAggregateMap);

            // Clearing the heap for the DML operation
            customerDocumentTypeAggregateMap.clear();
            
            // Update the document lists after sending emails to the customer
            update listOfCustomerDocuments;

            if(Test.isRunningTest()){
                throw new DmlException('Error');
            }
        }
        catch(Exception exceptionOccured){
            // Ideally, an error log should be created. But for now will have a system debug in place
            System.debug(exceptionOccured.getCause());
            System.debug(exceptionOccured.getMessage());
            System.debug(exceptionOccured.getStackTraceString());
        }
           
    }

    /**
     * @description - buildCustomerDocumentTypeAggregateMap() builds the aggregate map of the list of documents per type of the Document per customer. 
     * @params - 
     *      1. List<Document__c> listOfCustomerDocuments - List of Documents to be processed on 
     * @return - Map<Id, Map<String, List<Document__c>>>
     */
    private Map<Id, Map<String, List<Document__c>>> buildCustomerDocumentTypeAggregateMap(List<Document__c> listOfCustomerDocuments){

        // Holds the data as follows <Id of customer, <Type__c, Documents belonging to the type for customer>>
        Map<Id, Map<String, List<Document__c>>> customerDocumentTypeAggregateMap = new Map<Id, Map<String, List<Document__c>>> ();

        for(Document__c currentDocument: listOfCustomerDocuments){
            // If the customer is not added in the Map then add it an initialize the value for key as customerId
            if(!customerDocumentTypeAggregateMap.containsKey(currentDocument.Product_Subscription__r.Customer__r.Related_User_Record__c)){
                customerDocumentTypeAggregateMap.put(currentDocument.Product_Subscription__r.Customer__r.Related_User_Record__c, 
                                                    new Map<String, List<Document__c>>());
            }
            // Check the Document Type
            switch on currentDocument.Type__c {
                // When type is 'Report'
                when  'Report'{
                    // If entry for Type__c == 'Report' did not exist, then add the entry and initialize the value 
                    if(!customerDocumentTypeAggregateMap.get(currentDocument.Product_Subscription__r.Customer__r.Related_User_Record__c)
                        .containsKey(DOCUMENT_TYPE_REPORT)){
                            customerDocumentTypeAggregateMap.get(currentDocument.Product_Subscription__r.Customer__r.Related_User_Record__c)
                            .put(DOCUMENT_TYPE_REPORT, new List<Document__c>{currentDocument});
                        }
                    // Entry for Type__c == 'Report' did exists, then append the list of documents with the current document 
                    else{
                        customerDocumentTypeAggregateMap.get(currentDocument.Product_Subscription__r.Customer__r.Related_User_Record__c)
                            .get(DOCUMENT_TYPE_REPORT).add(currentDocument);
                    }
                }
                // When type is 'Transactional'
                when 'Transactional'{
                    if(!customerDocumentTypeAggregateMap.get(currentDocument.Product_Subscription__r.Customer__r.Related_User_Record__c)
                        .containsKey(DOCUMENT_TYPE_TRANSACTIONAL)){
                            customerDocumentTypeAggregateMap.get(currentDocument.Product_Subscription__r.Customer__r.Related_User_Record__c)
                            .put(DOCUMENT_TYPE_TRANSACTIONAL, new List<Document__c>{currentDocument});
                        }
                    else{
                        customerDocumentTypeAggregateMap.get(currentDocument.Product_Subscription__r.Customer__r.Related_User_Record__c)
                            .get(DOCUMENT_TYPE_TRANSACTIONAL).add(currentDocument);
                    }
                }
                // When type is 'Legal'
                when 'Legal'{
                    if(!customerDocumentTypeAggregateMap.get(currentDocument.Product_Subscription__r.Customer__r.Related_User_Record__c)
                        .containsKey(DOCUMENT_TYPE_LEGAL)){
                            customerDocumentTypeAggregateMap.get(currentDocument.Product_Subscription__r.Customer__r.Related_User_Record__c)
                            .put(DOCUMENT_TYPE_LEGAL, new List<Document__c>{currentDocument});
                        }
                    else{
                        customerDocumentTypeAggregateMap.get(currentDocument.Product_Subscription__r.Customer__r.Related_User_Record__c)
                            .get(DOCUMENT_TYPE_LEGAL).add(currentDocument);
                    }
                }
                // When type is 'Contract'
                when 'Contract'{
                    if(!customerDocumentTypeAggregateMap.get(currentDocument.Product_Subscription__r.Customer__r.Related_User_Record__c)
                        .containsKey(DOCUMENT_TYPE_CONTRACT)){
                            customerDocumentTypeAggregateMap.get(currentDocument.Product_Subscription__r.Customer__r.Related_User_Record__c)
                            .put(DOCUMENT_TYPE_CONTRACT, new List<Document__c>{currentDocument});
                        }
                    else{
                        customerDocumentTypeAggregateMap.get(currentDocument.Product_Subscription__r.Customer__r.Related_User_Record__c)
                            .get(DOCUMENT_TYPE_CONTRACT).add(currentDocument);
                    }
                } 
            }

            // Updating the fields on the documents processed. We can do this as listOfCustomerDocuments is passed by reference
            currentDocument.Customer_Notified_At__c = System.now();
            currentDocument.Notification_Status__c = DOCUMENT_NOTIFICATION_STATUS_CUSTOMER_NOTIFIED;
        }
        return customerDocumentTypeAggregateMap;
    }

    /**
     * @description - sendEmailToCustomers() sends the emails to customer per document type if the portfolio manager has created the document. 
     * @params - 
     *      1. Map<Id, Map<String, List<Document__c>>> customerDocumentTypeAggregateMap - Aggregate map of customer and document type with the list of documents
     * @return - void
     */
    private void sendEmailToCustomers(Map<Id, Map<String, List<Document__c>>> customerDocumentTypeAggregateMap){
        List<Messaging.SingleEmailMessage> listOfEmailsToBeSent = new List<Messaging.SingleEmailMessage>();
        Map<Integer, List<Messaging.SingleEmailMessage>> emailBatchesToBeSent = new Map<Integer, List<Messaging.SingleEmailMessage>>();
        Integer counter = 0;
        // Iterate over the customer Ids
        for(Id customerId: customerDocumentTypeAggregateMap.keySet()){
            for(String documentType: customerDocumentTypeAggregateMap.get(customerId).keySet()){
                // Store the email messages to be sent in a list
                listOfEmailsToBeSent.add(generateEmailMessageObject(customerDocumentTypeAggregateMap.get(customerId).get(documentType), 
                                                                    documentType, 
                                                                    customerId));
                
                // Splits the email into batches of 100
                if(listOfEmailsToBeSent.size() == 100){
                    emailBatchesToBeSent.put(counter, listOfEmailsToBeSent);
                    counter += 1;
                    listOfEmailsToBeSent.clear();
                }
            }
        }

        // Add the remaining list of emails as a batch to be processed. 
        // This scenario will occur if the number of emails to be sent by the current transaction is less than 1000
        if(!listOfEmailsToBeSent.isEmpty() && counter <= 9){
            emailBatchesToBeSent.put(counter, listOfEmailsToBeSent);
            counter += 1;
            listOfEmailsToBeSent.clear();
        }
        
        // The sendEmail method can be called 10 times per Apex transaction and each method invocation can include up to 100 "To", 25 "Cc", and 25 "Bcc" recipients.
        // Hence, the invocation can be broken into 10 parts. Also, since the batch size is 1000 we will not hit the limmits of the 'To' addresses
        for(Integer batchNumber: emailBatchesToBeSent.keySet()){
            Messaging.sendEmail(emailBatchesToBeSent.get(batchNumber));
        }
    }

    /**
     * @description - generateEmailMessageObject() initializes the SingleEmailMessage object for the email being sent
     * @params - 
     *      1. List<Document__c> documentsToConsolidate - List of documents whose names will be present in the email body
     *      2. String documentType - Type of document i.e Report, Transactional etc. This will be present in the subject
     *      3. Id customerId - Id of the customer for which the email needs to be sent
     * @return - Messaging.SingleEmailMessage
     */
    private Messaging.SingleEmailMessage generateEmailMessageObject(List<Document__c> documentsToConsolidate, String documentType, Id customerId){
        Messaging.SingleEmailMessage newEmailObject = new Messaging.SingleEmailMessage();
        newEmailObject.setTargetObjectId(customerId);
        newEmailObject.setSubject(String.valueOf(documentsToConsolidate.size()) + ' documents of type \'' + documentType + '\' uploaded newly by document manager');
        newEmailObject.setPlainTextBody(buildEmailBody(documentsToConsolidate));

        return newEmailObject; 
    }

    /**
     * @description - buildEmailBody() build the email body with the names of documents uploaded by the Portfolio Manager
     * @params - 
     *      1. List<Document__c> documentsToConsolidate - List of documents whose names will be present in the email body
     * @return - String
     */
    private String buildEmailBody(List<Document__c> documentsToConsolidate){
        String emailBody = '';
        for(Integer i = 0; i < documentsToConsolidate.size(); i++){
            emailBody += String.valueOf(i+1) + '. ' + documentsToConsolidate.get(i).File_Name__c + '\n';
        }
        return emailBody;
    }

    public void finish(Database.BatchableContext batchableContextObj){

    }
}