public class MyPageController {
	/*private ApexPages.StandardController controller;
	public MyPageController(ApexPages.StandardController controller){
		this.controller=controller;
	}
	public PageReference doSomething(){
		return null;
	}
	*/
	public List<ResourceWrapper> resources{get;set;}
	public MyPageController(){
		resources = new List<ResourceWrapper>();
		List<Resource__c> records = [SELECT Name FROM Resource__c];
		for(Resource__c record:records){
			resources.add(new ResourceWrapper(record));
		}
	}
	public PageReference doSomething(){
		for(ResourceWrapper wrapper : resources){
			if(wrapper.selected){
				System.debug(wrapper.data.Id);
			}
		}
		return null;
	}
	class ResourceWrapper{
		public Resource__c data {get; private set;}
		public Boolean selected{get;set;}
		public ResourceWrapper(Resource__c data){
			this.data = data;
			this.selected = false;
		}
	}
	public String name {get;set;}
	public String message {get; private set;}
	public PageReference hello(){
		message = 'Hello, ' + name;
		return null;
	}
}