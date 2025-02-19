@isTest
private class AccountControllerTest {
    @isTest
    static void testGetTop10Accounts() {
        // Create test accounts
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 15; i++) {
            testAccounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert testAccounts;

        // Run the method
        Test.startTest();
        List<Account> accounts = new AccountController().getTop10Accounts();
        Test.stopTest();

        // Assertions
        System.assertEquals(10, accounts.size(), 'Method should return exactly 10 accounts.');
    }
}