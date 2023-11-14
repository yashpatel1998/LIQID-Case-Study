/**
 * @description - Schedulable class to schedule a job to run NotifyCustomerOnDocumentUpload batch
 */
global  without sharing class NotifyCustomerOnDocumentUploadScheduler implements System.Schedulable{
    global  void execute(SchedulableContext sc) {
        // Batch size of 250 is used because there are 4 type of Document Types per customer.
        // Hence total emails can be 1000, which is also the limit of maximum emails we can trigger from the code. 

       Database.executeBatch(new NotifyCustomerOnDocumentUpload('SELECT Id FROM Customer__c'), 250);
    }
}