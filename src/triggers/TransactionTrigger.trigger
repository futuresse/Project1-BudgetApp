trigger TransactionTrigger on Transaction__c (before insert, before update, after delete) {
    if (Trigger.isBefore){
    	if (Trigger.isInsert){
        	TransactionValidator.validateFunds(Trigger.new[0]);
        }
        else if (Trigger.isUpdate)
            TransactionValidator.determineUpdate(Trigger.new[0], Trigger.old[0]);
    } else {
        if (Trigger.isDelete){
            TransactionValidator.removeTransaction(Trigger.old[0]);
        }
    }
}