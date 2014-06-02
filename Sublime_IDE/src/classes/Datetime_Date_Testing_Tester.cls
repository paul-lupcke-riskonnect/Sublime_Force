@isTest
private class Datetime_Date_Testing_Tester {
	
	@isTest static void test_method_one() {
		Datetime_Date_Testing first = new Datetime_Date_Testing();
		//System.debug(Datetime.valueOf('2012-12-30 12:00:00'));
		//System.debug(Datetime.valueOfGmt('2012-12-30 12:00:00'));
		first.worker = Datetime.valueOfGmt('2012-12-30 12:00:00');
		first.offset = 2;
		first.runCalculation();
		first.runCalculation2();
	}
	
	@isTest static void test_method_two() {
		Datetime_Date_Testing first = new Datetime_Date_Testing();
		first.worker = Datetime.valueOfGmt('2012-12-30 18:00:00');
		first.offset = 10;
		first.runCalculation();
		first.runCalculation2();
	}

	@isTest static void test_method_three() {
		Datetime_Date_Testing first = new Datetime_Date_Testing();
		first.worker = Datetime.valueOfGmt('2012-12-30 08:00:00');
		first.offset = 24;
		first.runCalculation();
		first.runCalculation2();
	}

	@isTest static void test_method_four() {
		Datetime_Date_Testing first = new Datetime_Date_Testing();
		first.worker = Datetime.valueOfGmt('2012-12-30 18:00:00');
		first.offset = 40;
		first.runCalculation();
		first.runCalculation2();
	}

	@isTest static void test_method_five() {
		Datetime_Date_Testing first = new Datetime_Date_Testing();
		first.worker = Datetime.valueOfGmt('2012-11-30 18:00:00');
		first.offset = 2;
		first.runCalculation();
		first.runCalculation2();
	}
	
}