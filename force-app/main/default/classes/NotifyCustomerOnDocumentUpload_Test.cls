/**
 * @description - Test class for NotifyCustomerOnDocumentUpload batch and NotifyCustomerOnDocumentUploadScheduler schedulable Method.
 */
@isTest(seeAllData = false)
public without sharing class NotifyCustomerOnDocumentUpload_Test {

    // Fetching the profile Ids and the UserRole Id
    private static final Profile systemAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    private static final Profile communityPlusProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User'];
    private static final UserRole testUserRole = [SELECT Id FROM UserRole LIMIT 1];

    private static final String USERNAME = 'sasnjgnaljngöasdguipahdgpwuetuqjfvnl@sadjguisnhgalög.com'; // Setting the UserName for Admin User
    
    // 2 Documents of each type will be created. Hence, storing document types in a set
    private static final Set<String> documentTypes = new Set<String> {'Report', 'Transactional', 'Legal', 'Contract'}; 

    @TestSetup
    static void createDataForTestClass(){
        // First, start with creating admin
        List<User> usersToInsert = new List<User>{createAdminUser()};
        // usersToInsert.addAll(createPortalUsers(250, testContact));
        insert usersToInsert;

        System.runAs(usersToInsert[0]){
            // Create and insert Test Account
            Account testAccount = new Account(Name = 'Test Account');
            insert testAccount;

            // Create and insert test contacts. These contacts will also be linked to the portal users created in test method
            List<Contact> listOfTestContact = new List<Contact>(); 
            for(Integer i = 0; i < 249; i++){
                listOfTestContact.add(
                    new Contact(LastName = 'Test Contact', AccountId = testAccount.Id)
                );
            }
            insert listOfTestContact;
        }
        
    }

    /**
     * @description - Helper method to create Admin user
     * @return - User
     */
    static User createAdminUser(){
        User userRecord = new User();
        userRecord.ProfileId = systemAdminProfile.Id;
        userRecord.LastName = 'TestUser';
        userRecord.Email = 'testuser@testing.liqid.org';
        userRecord.UserName = USERNAME;
        userRecord.CommunityNickname = 'sjaguinaskgan'; 
        userRecord.EmailEncodingKey='UTF-8';
        userRecord.LanguageLocaleKey='en_US';
        userRecord.LocaleSidKey='en_US';
        userRecord.TimeZoneSidKey='America/Chicago';
        userRecord.Alias='batman';
        userRecord.Is_Customer_and_Portal_User__c = true;
        userRecord.UserRoleId = testUserRole.Id;
        return userRecord;
    }

    /**
     * @description - Helper method to create portal users.
     * @params - 
     *      1. Integer numberOfUsers - Number of users to be created
     *      2. List<Contact> listOfTestContact - Contacts to which the portal users will be linked
     * @return - List<User>
     */
    static List<User> createPortalUsers(Integer numberOfUsers, List<Contact> listOfTestContact){
        List<User> listOfPortalUsers = new List<User>();
        for(Integer i = 0; i < numberOfUsers; i++){
            User userRecord = new User(
                ProfileId = communityPlusProfile.Id,
                LastName = 'TestUser' + String.valueOf(i),
                Email = 'testuser@testing.liqid.org' + String.valueOf(i),
                UserName = USERNAME + String.valueOf(i),
                CommunityNickname = 'sjaguinaskgan' + String.valueOf(i),
                EmailEncodingKey='UTF-8',
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                TimeZoneSidKey='America/Chicago',
                Alias='ban' + String.valueOf(i),
                Is_Customer_and_Portal_User__c = true,
                ContactId = listOfTestContact.get(i).Id
            );
            listOfPortalUsers.add(userRecord);
        }
        return listOfPortalUsers;
    }

    /**
     * @description - Helper method to create customers and link them to the portal users.
     * @params - 
     *      1. Integer numberOfCustomers - Number of customers to be created
     *      2. List<User> relatedUserRecords - Users to which the portal Customers will be linked
     * @return - List<Customer__c>
     */
    static List<Customer__c> createCustomers(Integer numberOfCustomers, List<User> relatedUserRecords){
        List<Customer__c> listOfTestCustomers = new List<Customer__c>{};
        for(Integer i = 0; i < numberOfCustomers; i++){
            Customer__c newCustomer = new Customer__c(
                First_Name__c = String.valueOf(i) + 'TestFName',
                Last_Name__c = String.valueOf(i) + 'TestLName',
                Mobile_Number__c = '+4915743225710',
                Related_User_Record__c = relatedUserRecords.get(i).Id,
                Email__c = 'testemail' + String.valueOf(i) + '@gmail.com'
            );
            listOfTestCustomers.add(newCustomer);
        }
        return listOfTestCustomers;
    }

    /**
     * @description - Helper method to create Product Registrations and link them to customers and products.
     * @params - 
     *      1. List<Customer__c> listOfTestCustomers - List of customers for whom the Product registrations need to be created
     *      2. Product__c testProduct - Main product for the product registrations
     * @return - List<Customer__c>
     */
    static List<Product_Subscription__c> createProductRegistrations(List<Customer__c> listOfTestCustomers, Product__c testProduct){
        List<Product_Subscription__c> listOfTestProductSubscriptions = new List<Product_Subscription__c>{};
        for(Integer i = 0; i < listOfTestCustomers.size(); i++){
            Product_Subscription__c newProductSubscription = new Product_Subscription__c(
                Product__c = testProduct.Id,
                Customer__c = listOfTestCustomers.get(i).Id
            );
            listOfTestProductSubscriptions.add(newProductSubscription);
        }
        return listOfTestProductSubscriptions;
    }

    /**
     * @description - Helper method to create Documents and link them to product registrations and partners.
     * @params - 
     *      1. List<Customer__c> listOfTestProductSubscriptions - List of product registrations for the documents to be created
     *      2. Account testAccount - Partner account for the documents
     * @return - List<Customer__c>
     */
    static List<Document__c> createDocuments(List<Product_Subscription__c> listOfTestProductSubscriptions, Account testAccount){
        List<Document__c> listOfTestDocuments = new List<Document__c>();
        for(Integer i = 0; i < listOfTestProductSubscriptions.size(); i++){
            for(String type: documentTypes){
                // Document 1 initalization
                listOfTestDocuments.add(
                    new Document__c(
                        Account__c = testAccount.Id,
                        File_Name__c = String.valueOf(i) + '1' + type + listOfTestProductSubscriptions.get(i).Id,
                        Generation_Date__c = System.today(),
                        Notification_Status__c = 'New',
                        Product_Subscription__c = listOfTestProductSubscriptions.get(i).Id,
                        Type__c = type
                    )
                );
                // Document 2 initalization
                listOfTestDocuments.add(
                    new Document__c(
                        Account__c = testAccount.Id,
                        File_Name__c = String.valueOf(i) + '2' + type + listOfTestProductSubscriptions.get(i).Id,
                        Generation_Date__c = System.today(),
                        Notification_Status__c = 'New',
                        Product_Subscription__c = listOfTestProductSubscriptions.get(i).Id,
                        Type__c = type
                    )
                );
            }
        }
        return listOfTestDocuments;
    }

    /**
     * @description - Test method to test the execution of NotifyCustomerOnDocumentUpload batch and NotifyCustomerOnDocumentUploadScheduler
     */
    @isTest(seeAllData = false)
    static void NotifyCustomerOnDocumentUpload_Test(){
        // Fetch the records inserted in @TestSetup
        User userRecord = [SELECT Id FROM User WHERE UserName = :USERNAME];
        List<Contact> listOfTestContact = [SELECT Id FROM Contact];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        // Creating portal users
        List<User> usersToInsert = new List<User>();
        usersToInsert.addAll(createPortalUsers(249, listOfTestContact));
        insert usersToInsert;

        System.runAs(userRecord){
            
            //Creating list of customers
            List<Customer__c> listOfTestCustomers = createCustomers(249, usersToInsert);
            insert listOfTestCustomers;

            // Creating product
            Product__c testProduct = new Product__c(
                Name = 'High Risk - Max Profit Equity',
                Type__c = 'Midas Equity',
                Partner__c = testAccount.Id
            );
            insert testProduct;

            // Creating product subscriptions
            List<Product_Subscription__c> listOfTestProductSubscriptions = createProductRegistrations(listOfTestCustomers, testProduct);
            insert listOfTestProductSubscriptions;

            // Creating documents
            List<Document__c> listOfTestDocumentRecords = createDocuments(listOfTestProductSubscriptions, testAccount);
            insert listOfTestDocumentRecords;

            // Running the actual test
            Test.startTest();
            new NotifyCustomerOnDocumentUploadScheduler().execute(null);
            Test.stopTest();

            // Asserting the test execution
            List<Document__c> documentsInStatusNew = [SELECT Id FROM Document__c WHERE Notification_Status__c = 'New' AND Customer_Notified_At__c = NULL];
            System.assert(documentsInStatusNew.size() == 0);

            List<Document__c> documentsNotInStatusNew = [SELECT Id FROM Document__c WHERE Notification_Status__c != 'New' AND Customer_Notified_At__c != NULL];
            System.assert(documentsNotInStatusNew.size() != 0);
        }
    }
}