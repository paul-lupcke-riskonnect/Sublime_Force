@isTest
private class TestTimecardManager {
	private static ID resourceId, ProjectId;
	
	static{
		Resource__c resource = new Resource__c(Name='Bob');
		insert resource;
		resourceId = resource.Id;
		Proj__c proj = new Proj__c(Name='Proj1');
		insert proj;
		ProjectId = proj.Id;
	}
	
	static testMethod void positiveTest(){
		Date weekEnding = Date.valueOf('2009-04-11');
		insert new Assignment__c(Project__c = projectId, Start_Date__c = weekEnding - 6, End_Date__c = weekEnding, Resource__c = resourceID);
		insert new Timecard__c(Project__c = projectId, Week_Ending__c = weekEnding, Resource__c = resourceId);
	}
	
	static testMethod void testNoAssignments(){
		Timecard__c timecard = new Timecard__c(Project__c = projectId, Week_Ending__c = Date.valueOf('2009-04-11'), Resource__c = resourceId);
		try{
			insert timecard;
		}
		catch(DmlException e){
			System.assert(e.getMessage().indexOf('No assignments')>0);
			return;
		}
		System.assert(false);
	}
	
	static testMethod void testNoValidAssignments(){
		Date weekEnding = Date.valueOf('2009-04-04');
		insert new Assignment__c(Project__c = projectId, Start_Date__c = weekEnding - 6, End_Date__c = weekEnding, Resource__c = resourceID);
		try{
			insert new Timecard__c(Project__c = projectId, Week_Ending__c = Date.today(), Resource__c = resourceId);
		}
		catch (DmlException e){
			System.assert(e.getMessage().indexOf('No assignment for resource') > 0);
			return;
		}
		System.assert(false);	
	}
	
	static testMethod void testBatch(){
		Date weekEnding = Date.valueOf('2009-04-11');
		insert new Assignment__c(Project__c = projectId, Start_Date__c = weekEnding - 6, End_Date__c = weekEnding, Resource__c = resourceID);
		List<Timecard__c> timecards = new List<Timecard__c>();
		for (Integer i=0; i<200; ++i){
			timecards.add(new Timecard__c(Project__c = projectId, Week_Ending__c = weekEnding, Resource__c = resourceId));
		}
		insert timecards;
	}
}