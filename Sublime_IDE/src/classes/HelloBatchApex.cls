global class HelloBatchApex implements Database.Batchable<SObject>{
	global Database.QueryLocator start(Database.BatchableContext context) {
		System.debug('start');
		return Database.getQueryLocator([SELECT Name FROM Proj__c ORDER BY Name]);
	}
	global void execute(Database.BatchableContext context,List<SObject> scope){
		System.debug('execute');
		for(SObject rec : scope){
			Proj__c p = (Proj__c)rec;
			System.debug('Project: ' + p.Name);
		}
	}
	global void finish(Database.BatchableContext context) {
		System.debug('finish'); 
	}
}