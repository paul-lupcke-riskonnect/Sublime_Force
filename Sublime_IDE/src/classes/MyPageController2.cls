public class MyPageController2{
	public Integer value { get; set; }
	public MyPageController2() {
		value = 1;
	}
	public PageReference timesTwo(){
		value *= 2;
		addInfo('The result is: ' + value);
		return null;
	}
	private void addInfo(String msg){
		ApexPages.addMessage(new ApexPages.Message( ApexPages.Severity.INFO, msg));
	} 
}