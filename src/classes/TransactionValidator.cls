// This class contains methods used to validate transactions and 
// update Budget__c and BankAccount__c records accordingly
public class TransactionValidator {
    /* This method validates that the user has enough funds in their 
* account for this transaction. If they do, it calls the appropriate
* function to update the account.
* Called By: Before Insert trigger
* Parameters: a list of sObjects of type Transaction__c
* Return: void
*/
    public static void validateFunds(Transaction__c t){
        BankAccount__c acc = [SELECT Balance__c
                              FROM BankAccount__c
                              WHERE Id = :t.Account__c
                              LIMIT 1];
        // if deposit
        if(Schema.SObjectType.Transaction__c.getRecordTypeInfosById().get(t.recordtypeid).getname() == 'Deposit'){
            addFundsBack(t, acc);
        }
        // withdrawl/spending
        else{
            if(t.Amount__c > acc.Balance__c)
                t.addError('Insufficient funds in account: ' + t.AccountName__c);
            else if(t.Amount__c <= 0)
                t.addError('You may not enter a negative transaction amount.');
            else {
                subtractFunds(t, acc);
            }
        }
    }
    public static void validateFunds(Transaction__c t, BankAccount__c acc){
        // if deposit
        if(Schema.SObjectType.Transaction__c.getRecordTypeInfosById().get(t.recordtypeid).getname() == 'Deposit'){
            addFundsBack(t, acc);
        }
        // withdrawl/spending
        else{
            if(t.Amount__c > acc.Balance__c)
                t.addError('Insufficient funds in account: ' + t.AccountName__c);
            else if(t.Amount__c <= 0)
                t.addError('You may not enter a negative transaction amount.');
            else {
                subtractFunds(t, acc);
            }
        }
    }
    
    public static void subtractFunds(Transaction__c t, BankAccount__c acc){ 
        if (t.Amount__c < acc.Balance__c) {
            acc.Balance__c -= t.Amount__c;
            update acc;
            SubtractFromBudget(t);
        }
        else{t.addError('Invalid change: This would drop your balance below 0.');}
        
    }
    public static void subtractFunds(Transaction__c t){
        BankAccount__c acc = [SELECT Balance__c
                              FROM BankAccount__c
                              WHERE Id = :t.Account__c
                              LIMIT 1];
        if (t.Amount__c < acc.Balance__c) {
            acc.Balance__c -= t.Amount__c;
            update acc;
            SubtractFromBudget(t);
        } else{
            t.addError('Invalid change: This would drop your balance below 0.');
        }

    }
    
    public static void addFundsBack(Transaction__c t, BankAccount__c acc){
        if(t.Amount__c <= 0)
            t.addError('Deposits must be $0.01 or greater.');
        acc.Balance__c += t.Amount__c;
        update acc;
        AddToBudget(t);
    }
    public static void addFundsBack(Transaction__c t){
        BankAccount__c acc = [SELECT Balance__c
                              FROM BankAccount__c
                              WHERE Id = :t.Account__c
                              LIMIT 1];
        acc.Balance__c += t.Amount__c;
        update acc;
        AddToBudget(t);
    }    
    
    
    public static void determineUpdate(Transaction__c tNew, Transaction__c tOld){
        // if update is to account
        if (!(tOld.Account__c == tNew.Account__c)){
            validateFunds(tNew);
            if(Schema.SObjectType.Transaction__c.getRecordTypeInfosById().get(tNew.recordtypeid).getname() == 'Deposit')
                subtractFunds(tOld);
            else{
                addFundsBack(tOld);
            } 
        }
        // if update is to amount
        if (!(tOld.Amount__c == tNew.Amount__c)){
            BankAccount__c acc = [SELECT Balance__c
                                  FROM BankAccount__c
                                  WHERE Id = :tOld.Account__c
                                  LIMIT 1];
            if(Schema.SObjectType.Transaction__c.getRecordTypeInfosById().get(tNew.recordtypeid).getname() == 'Deposit'){
                acc.Balance__c -= tOld.Amount__c;
                acc.Balance__c += tNew.Amount__c;
                if(acc.Balance__c < 0)
                    tNew.addError('Invalid change: This would drop your balance below 0.');
            } 
            else {
                acc.Balance__c += tOld.Amount__c;
                acc.Balance__c -= tNew.Amount__c;
                if(acc.Balance__c < 0)
                    tNew.addError('Invalid change: This would drop your balance below 0.');
            }
            update acc;
        }
        // if update is to budget
        if (!(tOld.Budget__c == tNew.Budget__c)){
        	tOld.Budget__c = tNew.Budget__c;
			AddToBudget(tOld);
            SubtractFromBudget(tNew);
        }
    }
    
    public static void removeTransaction(Transaction__c t){
        BankAccount__c acc = [SELECT Balance__c
                              FROM BankAccount__c
                              WHERE Id = :t.Account__c
                              LIMIT 1];
        if(Schema.SObjectType.Transaction__c.getRecordTypeInfosById().get(t.recordtypeid).getname() == 'Deposit'){
            acc.Balance__c -= t.Amount__c;
            if(acc.Balance__c < 0){
                t.addError('Cannot delete deposit: Balance would drop below 0');
            }
            update acc;
        } else{
            acc.Balance__c += t.Amount__c;
            update acc;
            AddToBudget(t);
        }
    }
    
    public static void SubtractFromBudget(Transaction__c t){
    	if(t.Type__c == 'Bills'){
            Budget__c b = [SELECT Bills__c
                       	   FROM Budget__c
                      	   WHERE Id = :t.Budget__c
                       	   LIMIT 1];
            b.Bills__c -= t.Amount__c;
            update b;
        }
        else if(t.Type__c == 'Entertainment'){
            Budget__c b = [SELECT Entertainment__c
                           FROM Budget__c
                           WHERE Id = :t.Budget__c
                           LIMIT 1];
            b.Entertainment__c -= t.Amount__c;
            update b;
        } else{
            Budget__c b = [SELECT FeesAndExpenses__c
                           FROM Budget__c
                           WHERE Id = :t.Budget__c
                           LIMIT 1];
            b.FeesAndExpenses__c -= t.Amount__c;
            update b;
        }
    }
    public static void AddToBudget(Transaction__c t){
        if(t.Type__c == 'Bills'){
            Budget__c b = [SELECT Bills__c
                       	   FROM Budget__c
                      	   WHERE Id = :t.Budget__c
                       	   LIMIT 1];
            b.Bills__c += t.Amount__c;
            update b;
        }
        else if(t.Type__c == 'Entertainment'){
            Budget__c b = [SELECT Entertainment__c
                           FROM Budget__c
                           WHERE Id = :t.Budget__c
                           LIMIT 1];
            b.Entertainment__c += t.Amount__c;
            update b;
        } else{
            Budget__c b = [SELECT FeesAndExpenses__c
                           FROM Budget__c
                           WHERE Id = :t.Budget__c
                           LIMIT 1];
            b.FeesAndExpenses__c += t.Amount__c;
            update b;

        }
    }
}