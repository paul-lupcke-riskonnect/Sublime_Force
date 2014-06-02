public class MyPageController2{
	public Integer value { get; set; }
	public String test2 {get; set;}

	public MyPageController2() {
		value = 1;
		test2 = 'test';
	}
	public PageReference timesTwo(){
		value *= 2;
		addInfo('The result is: ' + value + ' & the field is: '+ test2);
		return null;
	}

	private void addInfo(String msg){
		ApexPages.addMessage(new ApexPages.Message( ApexPages.Severity.INFO, msg));
	} 
}