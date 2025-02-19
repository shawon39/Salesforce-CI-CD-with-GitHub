public with sharing class AccountController {
    public List<Account> getTop10Accounts() {
        return [SELECT Id, Name FROM Account LIMIT 10];
    }
}