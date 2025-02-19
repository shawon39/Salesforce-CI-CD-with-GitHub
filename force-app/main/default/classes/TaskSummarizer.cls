public with sharing class TaskSummarizer {
    @AuraEnabled
    public static String summarizeTasks(Id contactId) {
        // Get all Task descriptions related to the Contact, ordered by CreatedDate
        List<Task> tasks = [SELECT Id, Description FROM Task WHERE WhoId = :contactId ORDER BY CreatedDate];

        if (tasks.isEmpty()) {
            return 'No tasks found to summarize.';
        }

        // Concatenate all task descriptions and escape quotes
        String combinedText = '';
        for (Task t : tasks) {
            if (t.Description != null) {
                combinedText += t.Description.replaceAll('[\\\\"]', '\\\\$0').replaceAll('[\\r\\n]+', ' ');
            }
        }

        // Fetch values from custom labels
        String baseUrl = System.Label.Base_URL;
        String modelName = System.Label.Model_Name;
        String summaryPrompt = System.Label.Summary_Prompt;
        
        // Append the correct endpoint
        String fullEndpoint = baseUrl + '/api/generate';

        // Prepare the API request
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(fullEndpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(120000);

        // JSON request body
        String requestBody = '{"model": "' + modelName + '", "prompt": "' + summaryPrompt + ' ' + combinedText + '", "stream": false}';
        request.setBody(requestBody);

        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                // Parse the JSON response
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String summary = (String) jsonResponse.get('response');

                // Update the Contact record with the summary
                Contact contactToUpdate = new Contact(Id = contactId, Summarized_Calls__c = summary);
                update contactToUpdate;

                return 'Summary updated successfully!';
            } else {
                return 'Failed to get summary: ' + response.getStatus();
            }
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }
}