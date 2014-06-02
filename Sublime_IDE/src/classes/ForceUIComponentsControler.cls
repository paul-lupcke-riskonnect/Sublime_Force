public class ForceUIComponentsControler {
	public Resource__c subject { get;private set;}
	public ForceUIComponentsControler(){
		subject = [SELECT Id, Name FROM Resource__c LIMIT 1];
	}
}