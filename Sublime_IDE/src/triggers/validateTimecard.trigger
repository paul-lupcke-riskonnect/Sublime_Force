trigger validateTimecard on Timecard__c (before insert, before update) {
	//Do nothing
	TimecardManager.handleTimecardChange(Trigger.old, Trigger.new);
}