@isTest
private class TaskSummarizerTest {

    // --- Mock Classes ---

    // Mock for a successful HTTP callout returning a summary.
    private class SuccessfulCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            // Return a JSON response with a summary.
            res.setBody('{"response": "Test summary"}');
            return res;
        }
    }

    // Mock for a non-200 HTTP response.
    private class Non200CalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(500);
            res.setStatus('500 Internal Server Error');
            res.setBody('{"error": "Something went wrong"}');
            return res;
        }
    }

    // Mock for an HTTP callout that throws an exception.
    private class ExceptionCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Test callout exception');
        }
    }

    // --- Test Methods ---

    // Test when Tasks exist and the callout is successful.
    static testMethod void testSummarizeTasksWithSuccessfulCallout() {
        // Create a Contact record.
        Contact testContact = new Contact(LastName = 'Tester');
        insert testContact;
        
        // Create several Tasks related to the Contact.
        // Task with a normal description.
        Task task1 = new Task(
            WhoId = testContact.Id,
            Subject = 'Follow-up',
            Description = 'Call the client to discuss details.'
        );
        // Task with quotes and newlines to test the escaping.
        Task task2 = new Task(
            WhoId = testContact.Id,
            Subject = 'Review',
            Description = 'He said, "Hello"\nNew line here.'
        );
        // Task with a null description.
        Task task3 = new Task(
            WhoId = testContact.Id,
            Subject = 'No Description'
            // Description remains null.
        );
        insert new List<Task>{ task1, task2, task3 };

        // Set the mock to simulate a successful callout.
        Test.setMock(HttpCalloutMock.class, new SuccessfulCalloutMock());
        
        Test.startTest();
        String result = TaskSummarizer.summarizeTasks(testContact.Id);
        Test.stopTest();
        
        // Verify the success message.
        System.assertEquals('Summary updated successfully!', result);
        
        // Verify the Contact record's custom field is updated.
        Contact updatedContact = [SELECT Summarized_Calls__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('Test summary', updatedContact.Summarized_Calls__c);
    }
    
    // Test when no Tasks exist for the Contact.
    static testMethod void testSummarizeTasksWithNoTasks() {
        // Create a Contact with no related Tasks.
        Contact noTaskContact = new Contact(LastName = 'NoTask');
        insert noTaskContact;
        
        Test.startTest();
        String result = TaskSummarizer.summarizeTasks(noTaskContact.Id);
        Test.stopTest();
        
        // Expect the message indicating no tasks were found.
        System.assertEquals('No tasks found to summarize.', result);
    }
    
    // Test when the HTTP callout returns a non-200 response.
    static testMethod void testSummarizeTasksWithNon200Response() {
        // Create a Contact record.
        Contact testContact = new Contact(LastName = 'Non200');
        insert testContact;
        
        // Create a Task for the Contact.
        Task testTask = new Task(
            WhoId = testContact.Id,
            Subject = 'Follow-up',
            Description = 'Task description.'
        );
        insert testTask;
        
        // Set the mock to simulate a non-200 HTTP response.
        Test.setMock(HttpCalloutMock.class, new Non200CalloutMock());
        
        Test.startTest();
        String result = TaskSummarizer.summarizeTasks(testContact.Id);
        Test.stopTest();
        
        // Expect a failure message that includes the HTTP status.
        System.assertEquals('Failed to get summary: 500 Internal Server Error', result);
        
        // Verify that the Contact was not updated.
        Contact updatedContact = [SELECT Summarized_Calls__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals(null, updatedContact.Summarized_Calls__c);
    }
    
    // Test when the HTTP callout throws an exception.
    static testMethod void testSummarizeTasksWithException() {
        // Create a Contact record.
        Contact testContact = new Contact(LastName = 'ExceptionTest');
        insert testContact;
        
        // Create a Task for the Contact.
        Task testTask = new Task(
            WhoId = testContact.Id,
            Subject = 'Follow-up',
            Description = 'Task description for exception test.'
        );
        insert testTask;
        
        // Set the mock to simulate an exception during the callout.
        Test.setMock(HttpCalloutMock.class, new ExceptionCalloutMock());
        
        Test.startTest();
        String result = TaskSummarizer.summarizeTasks(testContact.Id);
        Test.stopTest();
        
        // Expect the error message to contain the exception text.
        System.assert(result.contains('Error: Test callout exception'));
        
        // Verify that the Contact was not updated.
        Contact updatedContact = [SELECT Summarized_Calls__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals(null, updatedContact.Summarized_Calls__c);
    }
}
