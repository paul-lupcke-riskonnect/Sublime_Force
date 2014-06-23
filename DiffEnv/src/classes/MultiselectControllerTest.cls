/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class MultiselectControllerTest { //(PAL) 100% coverage
    static testMethod void testMultiselectController() {


        MultiselectController c = new MultiselectController();
        
        //c.leftOptions = new SelectOption[]{};
        //c.rightOptions = new SelectOption[]{};

        List<SelectOption[]> left = new List<SelectOption[]>();
        left.add(new SelectOption[]{});
        left[0].add(new SelectOption('0','Zero'));
        left[0].add(new SelectOption('1','One'));
        left[0].add(new SelectOption('2','Two'));
        left[0].add(new SelectOption('3','Three'));
        left[0].add(new SelectOption('4','Four'));

        List<SelectOption[]> right = new List<SelectOption[]>();
        right.add(new SelectOption[]{});
        right[0].add(new SelectOption('1','One'));

        c.indexID = null;

        System.assertEquals('0', c.indexID);

        c.indexID = '0';
        c.rightSelection = right;
        c.leftSelection = left;
        //c.rightSelection = right;

        System.assertEquals(4, c.leftOptions.size());
        System.assertEquals(1, c.rightOptions.size());

        c.leftOptionsHidden = '5&Five&4&Four&C&c';
        c.rightOptionsHidden = '3&Three&2&Two';
        
        System.assertEquals(3, c.leftOptions.size());
        System.assertEquals(2,c.rightOptions.size());
    }
}