public class Datetime_Date_Testing {
	public Datetime worker = Datetime.now();
	public Integer offset = 0;

	public Datetime_Date_Testing() {
	}
	public Datetime_Date_Testing(Datetime start, Integer offset) {
		worker = start;
		this.offset = offset;
	}
	public void runCalculation(){
		System.debug('Start: '+worker+' Offset: '+offset);
		Datetime tmp = worker;
		tmp = tmp.addHours(this.offset);
		Date justDate = date.newinstance(tmp.year(),tmp.month(),tmp.day());
		System.debug('New: '+tmp+' Simple: '+justDate);
	}
	public void runCalculation2(){
		System.debug('Start: '+worker+' Offset: '+offset);
		Datetime tmp = worker;
		tmp = tmp.addHours(this.offset);
		Date justDate = tmp.date();
		System.debug('New: '+tmp+' Simple: '+justDate);
	}
}