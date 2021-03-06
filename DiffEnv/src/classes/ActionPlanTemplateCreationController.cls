/*
Action Plans v3
Force.com Labs
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

Copyright (c) 2011, salesforce.com, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, 
    this list of conditions and the following disclaimer in the documentation 
    and/or other materials provided with the distribution.
    * Neither the name of the salesforce.com, Inc. nor the names of its contributors 
    may be used to endorse or promote products derived from this software 
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
OF THE POSSIBILITY OF SUCH DAMAGE.

*/
public with sharing class ActionPlanTemplateCreationController{
	
	private Double					taskIndex				{ get; set; }
	public ActionPlanTemplates		actionPlanTemplates		{ get; set; }
	public ActionPlanTemplate__c 	actionPlanTemplate		{ get; set; }
	public String           		actionPlanTemplateId	{ get; set; }
	public Boolean					addedTask				{ get; set; }
	public Boolean					displayReminder			{ get; set; }

    public List<SelectOption[]>     savedDependencies       { get; set; }
    public List<SelectOption[]>     possibleOptions         { get; set; }
    public List<SelectOption[]>     selectedOptions         { get; set; }
    public List<Integer>            removeOptions           { get; set; }
	
	/**
     * Constructor
     * If we can obtain the Id from the page parameters then we search for that template and set the variable for that template.
     * If we can't obtain the Id from the page parameters then we create a new template and obtain from the controller.
     * Then we need to check if we are cloning the template, in that case clone the template without Id.
     */
    public ActionPlanTemplateCreationController( ApexPages.StandardController stdController ){

        this.taskIndex = 0;
        this.addedTask = false;

        this.savedDependencies       = new List<SelectOption[]>();
        this.possibleOptions         = new List<SelectOption[]>();
        this.selectedOptions         = new List<SelectOption[]>();
        this.removeOptions           = new List<Integer>();
        
        if( System.currentPageReference().getParameters().get( 'id' ) != null ){//Modified PAL
        	
			this.actionPlanTemplateId 	= System.currentPageReference().getParameters().get( 'id' );
			this.actionPlanTemplate 	= [ select a.Id, a.Name, a.Description__c, a.SkipWeekends__c, a.SkipDay__c, a.LastModifiedDate, 
												a.LastModifiedBy.Name, a.LastModifiedById, a.CreatedDate, a.CreatedBy.Name, a.CreatedById, 
												a.Owner.Name from ActionPlanTemplate__c a
												Where a.Id =: this.actionPlanTemplateId limit 1 ];
			
			this.taskIndex = this.calculateTaskIndexValue();
            Map<Integer, APTTaskTemplate__c> savedRecords = this.grabAPTasks();
            List<List<SelectOption[]>> recordsToPush = this.generateFields(savedRecords);

            this.possibleOptions = recordsToPush[0];
            this.selectedOptions = recordsToPush[1];
		}
		else{
			this.actionPlanTemplate = ( ActionPlanTemplate__c ) stdController.getRecord();
		}
		
       	if( System.currentPageReference().getParameters().get( 'clone' ) == '1' ){
       		ActionPlanTemplate__c apC = actionPlanTemplate.clone( false );
            this.actionPlanTemplate.clear();
            this.actionPlanTemplate = apC;
       	}
       	
        this.actionPlanTemplates = new ActionPlanTemplates( this.actionPlanTemplate );
        this.actionPlanTemplates.taskIndexOrder = this.taskIndex;
        this.displayReminder = this.actionPlanTemplates.getDisplayReminder();
    }

    public Map<Integer, APTTaskTemplate__c> grabAPTasks(){//Custom PAL
        
        List<APTTaskTemplate__c> apTasks = [ select Id, Subject__c, Dependent__c, taskIndex__c from APTTaskTemplate__c 
                                                where Action_Plan_Template__c =: this.actionPlanTemplateId ];
        Map<Integer, APTTaskTemplate__c> retVal = new Map<Integer, APTTaskTemplate__c>();
        for(APTTaskTemplate__c t: apTasks){
            retVal.put(t.taskIndex__c.intValue(), t);
        }
        return retVal;
    }

    public List<List<SelectOption[]>> generateFields(Map<Integer, APTTaskTemplate__c> input){//Custom PAL
        List<List<SelectOption[]>> retVal = new List<List<SelectOption[]>>();
        List<SelectOption[]> leftField = new List<SelectOption[]>();
        List<SelectOption[]> rightField = new List<SelectOption[]>();

        List<Integer> all = new List<Integer>(input.keySet());
        //System.debug('All size:'+all.size()+': ALL:'+all);
        for(Integer i=0;i<all.size();++i){
            APTTaskTemplate__c t = input.get(all[i]);
            if(t.Dependent__c==null){
                t.Dependent__c='None';
            }
            List<String> deps = ActionPlansUtilities.parseMultiSelect(t.Dependent__c);
            leftField.add(new SelectOption[]{});
            rightField.add(new SelectOption[]{});
            for(Integer j=0;j<all.size();++j){
                APTTaskTemplate__c listTask = input.get(all[j]);
                Boolean leftList = true;
                for(Integer k=0;k<deps.size();++k){
                    if(listTask.taskIndex__c.intValue() == Integer.valueOf(deps[k])){
                        leftList=false;
                        break;
                    }
                }
                if(leftList==true){
                    //t.Subject__c+' ('+ (i+1) +')'
                    leftField[leftField.size()-1].add( new SelectOption(String.valueOf(listTask.taskIndex__c.intValue()),
                                                                        listTask.Subject__c+' ('+String.valueOf(listTask.taskIndex__c.intValue()+1)+')') );
                }
                else{
                    rightField[leftField.size()-1].add( new SelectOption(String.valueOf(listTask.taskIndex__c.intValue()),
                                                                        listTask.Subject__c+' ('+String.valueOf(listTask.taskIndex__c.intValue()+1)+')') );
                }
            }
        }

        retVal.add(leftField);
        retVal.add(rightField);

        return retVal;
    }

	/**
	 * Call method saveTemplate() inside the class ActionPlanTemplates
	 * @return PageReference
	 */
	public PageReference saveTemplate(){
		return actionPlanTemplates.saveTemplate();
	} 
	
	/**
	 * Call method cancelTemplate() inside the class ActionPlanTemplates
	 * @return PageReference
	 */
	public PageReference cancelTemplate(){
		return actionPlanTemplates.cancelTemplate();
	}
	
	/**
	 * Call method addTemplateTask() inside the class ActionPlanTemplates
	 */
	public void addTemplateTask(){
        this.savedDependencies.clear();
        this.possibleOptions.clear();
        this.removeOptions.clear();
        this.selectedOptions.clear();
        this.possibleOptions.add(this.getTemplateSubjectItems());

		this.taskIndex++;
		this.actionPlanTemplates.taskIndexOrder = this.taskIndex;
		this.addedTask = actionPlanTemplates.addTemplateTask();
	}
	
	/**
	 * Call method removeTemplateTask() inside the class ActionPlanTemplates
	 */
	public void removeTemplateTask(){
        this.savedDependencies.clear();
        this.possibleOptions.clear();
        this.selectedOptions.clear();
        this.removeOptions.clear();
        
		addedTask = !actionPlanTemplates.removeTemplateTask();
        this.possibleOptions.add(this.getTemplateSubjectItems());
	}
	
	/**
	 * Call method getTemplateTasks() inside the class ActionPlanTemplates
	 */
	public List<ApTTaskWrapper> getTemplateTasks(){
		
		ApTTaskWrapper apTTaskWrapper;
    	List<ApTTaskWrapper> tasksList = new List<ApTTaskWrapper>();
    	
    	if( this.actionPlanTemplates != null ){
    		Integer i = 0;
    		for( APTTaskTemplate__c aptTaskTemplate : this.actionPlanTemplates.getTemplateTasks() ){
    			ApTTaskWrapper = new ApTTaskWrapper( aptTaskTemplate, i );
    			tasksList.add( ApTTaskWrapper );
    			i++;
    		}
    		if( this.addedTask ){
    			tasksList.get( i - 1 ).isLast = true;	
    		}	
    	}
    	
    	return tasksList;
	}
	
	/**
	 * Call method getTemplateTaskSize() inside the class ActionPlanTemplates
	 */
	public Integer getTemplateTaskSize(){
		return actionPlanTemplates.getTemplateTaskSize();
	}
	
	/**
	 * Call method getTemplateSubjectItems() inside the class ActionPlanTemplates
	 */
	public List<SelectOption> getTemplateSubjectItems(){
	    return actionPlanTemplates.getTemplateSubjectItems();
	}
	
	/**
    * Checks if Action Plan Tasks has cycling dependency.
    * @return PageReference
    */
    public PageReference checkCycleDependent(){
        System.debug('Attempting to save dependencies from page');
    	this.actionPlanTemplates.setDependencies2(savedDependencies);
        System.debug('saved dependencies from page');
    	if( this.actionPlanTemplates.checkCycleDependent() ){
            this.savedDependencies.clear();
    		return null;
    	}
    	else{
            System.debug('saving template');
    		return this.saveTemplate();
    	}
    }
    
    /**
    * Getter method to return the error message from
    * action plans utilities
    * @return actionPlanTemplates.errorMsg
    */
    public String getErrorMsg(){
    	return actionPlanTemplates.errorMsg;
    }
    
    /**
    * Calculates the highest task index value
    * @return maxIndex
    */
    public Double calculateTaskIndexValue(){
    	
    	List<APTTaskTemplate__c> aptTasks = [ select id, taskIndex__c from APTTaskTemplate__c 
    											where Action_Plan_Template__c =: this.actionPlanTemplateId ];
    	
    	Double maxIndex = 0;
    	for( APTTaskTemplate__c tsk : aptTasks ){
    		if( tsk.taskIndex__c > maxIndex ){
    			maxIndex = tsk.taskIndex__c;
    		}
    	}
    	
    	return maxIndex;
    }
    
    /**
    * Inner Wrapper Class for Action Plan Template Tasks
    * @author Matias Menafra
    * @createddate 08/08/2010
    */
    public class ApTTaskWrapper{
    	
    	public APTTaskTemplate__c task 	{ get; set; }
		public 	Integer 	position 	{ get; set; }
    	public 	Boolean 	isLast 		{ get; set; }
    	
    	public ApTTaskWrapper( APTTaskTemplate__c apTask, Integer pos ){
    		task 		= apTask;
    		position 	= pos;
    		isLast 		= false;
    	}
    }
    
    public static testMethod void testConstructor(){
    	
    	Test.StartTest();
    	
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ActionPlanTemplate__c apTemplate 	= testUtil.createNewActionPlanTemplate(3);
    	
    	System.currentPageReference().getParameters().put( 'id', null );
    	ActionPlanTemplateCreationController apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( new ActionPlanTemplate__c() ) );
    	
        try{
        	System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
        	apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( new ActionPlanTemplate__c() ) );
        }
        catch(Exception ex){

        }
    	
        try{
        	System.currentPageReference().getParameters().put( 'clone', '1' );
        	apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );
        }
    	catch(Exception ex){

        }

    	Test.StopTest();
    }

    public static testMethod void testgrabAPTasks(){
        
        Test.StartTest();
        
        ActionPlansTestUtilities testUtil   = new ActionPlansTestUtilities();
        ActionPlanTemplate__c apTemplate    = testUtil.createNewActionPlanTemplate(3);// new ActionPlanTemplate__c();
        
        ActionPlanTemplateCreationController apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );

        apTemplateController.grabAPTasks();
        
        
        
        Test.StopTest();
    }
    
    public static testMethod void testgenerateFields(){
        
        Test.StartTest();
        
        ActionPlansTestUtilities testUtil   = new ActionPlansTestUtilities();
        ActionPlanTemplate__c apTemplate    = new ActionPlanTemplate__c();

        APTTaskTemplate__c newAPTTask   = new APTTaskTemplate__c();
        APTTaskTemplate__c newAPTTask2  = new APTTaskTemplate__c();
        APTTaskTemplate__c newAPTTask3  = new APTTaskTemplate__c();
        
        newAPTTask.Subject__c           = testUtil.createRandomWord();
        newAPTTask.Hours_After_Start__c     = 2;
        newAPTTask.Dependent__c         = 'None';
        newAPTTask.Type__c              = 'Email';
        newAPTTask.Priority__c          = 'Hight';
        newAPTTask.taskIndex__c         = 0;
        
        newAPTTask2.Subject__c          = testUtil.createRandomWord();
        newAPTTask2.Hours_After_Start__c    = 2;
        newAPTTask2.Dependent__c        = '0';
        newAPTTask2.Type__c             = 'Email';
        newAPTTask2.Priority__c         = 'Hight';
        newAPTTask2.taskIndex__c         = 1;
        
        newAPTTask3.Subject__c          = testUtil.createRandomWord();
        newAPTTask3.Hours_After_Start__c    = 2;
        newAPTTask3.Dependent__c        = '0,1';
        newAPTTask3.Type__c             = 'Email';
        newAPTTask3.Priority__c         = 'Hight';
        newAPTTask3.taskIndex__c         = 2;

        Map<Integer, APTTaskTemplate__c> input = new Map<Integer, APTTaskTemplate__c>();
        input.put(0, newAPTTask);
        input.put(1, newAPTTask2);
        input.put(2, newAPTTask3);

        ActionPlanTemplateCreationController apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );

        apTemplateController.generateFields(input);
        
        
        
        Test.StopTest();
    }

    public static testMethod void testSave(){
    
    	Test.StartTest();
    	
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ActionPlanTemplate__c apTemplate 	= new ActionPlanTemplate__c();
    	
    	apTemplate.Name = testUtil.createRandomWord();
    	
    	APTTaskTemplate__c newAPTTask = new APTTaskTemplate__c();
 		
 		newAPTTask.Subject__c 			= testUtil.createRandomWord();
 		newAPTTask.Hours_After_Start__c 	= 2;
 		newAPTTask.Type__c 				= 'Email';
 		newAPTTask.Priority__c 			= 'Hight';
 		
		ActionPlanTemplateCreationController apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );
		apTemplateController.actionPlanTemplates.aptTasks = new List<APTTaskTemplate__c>();
		apTemplateController.actionPlanTemplates.aptTasks.add( newAPTTask );
		Pagereference page = apTemplateController.saveTemplate();
		
		System.assert( page != null );
		
    	Test.StopTest();
    }
    
    public static testMethod void testCancel(){
    	
       Test.StartTest();
        
        ActionPlansTestUtilities testUtil   = new ActionPlansTestUtilities();
        ActionPlanTemplate__c apTemplate    = new ActionPlanTemplate__c();
        
        apTemplate.Name = testUtil.createRandomWord();
        
        APTTaskTemplate__c newAPTTask = new APTTaskTemplate__c();
        
        newAPTTask.Subject__c           = testUtil.createRandomWord();
        newAPTTask.Hours_After_Start__c     = 2;
        newAPTTask.Type__c              = 'Email';
        newAPTTask.Priority__c          = 'Hight';
        
        System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
        ActionPlanTemplateCreationController apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );
        apTemplateController.actionPlanTemplates.aptTasks = new List<APTTaskTemplate__c>();
        apTemplateController.actionPlanTemplates.aptTasks.add( newAPTTask );
        apTemplateController.cancelTemplate();
        
        //System.assert( page != null );
        
        Test.StopTest();

    	/*Test.StartTest();
    	
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ActionPlanTemplate__c apTemplate 	= testUtil.createNewActionPlanTemplate( 2 );
    	
    	System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
    	ActionPlanTemplateCreationController apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( new ActionPlanTemplate__c() ) );
    	apTemplateController.cancelTemplate();
    	
    	Test.StopTest();*/
    }
    
    public static testMethod void testAddTemplateTask(){
    	
    	Test.StartTest();
    	
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ActionPlanTemplate__c apTemplate    = new ActionPlanTemplate__c();
        
        apTemplate.Name = testUtil.createRandomWord();
        
        APTTaskTemplate__c newAPTTask = new APTTaskTemplate__c();
        
        newAPTTask.Subject__c           = testUtil.createRandomWord();
        newAPTTask.Hours_After_Start__c     = 2;
        newAPTTask.Type__c              = 'Email';
        newAPTTask.Priority__c          = 'Hight';
        
        System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
        ActionPlanTemplateCreationController apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );
        apTemplateController.actionPlanTemplates.aptTasks = new List<APTTaskTemplate__c>();
        apTemplateController.actionPlanTemplates.aptTasks.add( newAPTTask );
    	apTemplateController.addTemplateTask();
    	
    	Test.StopTest();
    }
    
    public static testMethod void testRemoveTemplateTask(){
    
    	Test.StartTest();
    	
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ActionPlanTemplate__c apTemplate    = new ActionPlanTemplate__c();
        
        apTemplate.Name = testUtil.createRandomWord();
        
        APTTaskTemplate__c newAPTTask = new APTTaskTemplate__c();
        
        newAPTTask.Subject__c           = testUtil.createRandomWord();
        newAPTTask.Hours_After_Start__c     = 2;
        newAPTTask.Type__c              = 'Email';
        newAPTTask.Priority__c          = 'Hight';
        
        System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
        ActionPlanTemplateCreationController apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );
        apTemplateController.actionPlanTemplates.aptTasks = new List<APTTaskTemplate__c>();
        apTemplateController.actionPlanTemplates.aptTasks.add( newAPTTask );
    	apTemplateController.removeTemplateTask();
    	
    	Test.StopTest();
    }
    
    public static testMethod void testRetrievingTemplateTasks(){
    
    	Test.StartTest();
    	
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ActionPlanTemplate__c apTemplate    = new ActionPlanTemplate__c();
        
        apTemplate.Name = testUtil.createRandomWord();
        
        APTTaskTemplate__c newAPTTask = new APTTaskTemplate__c();
        
        newAPTTask.Subject__c           = testUtil.createRandomWord();
        newAPTTask.Hours_After_Start__c     = 2;
        newAPTTask.Type__c              = 'Email';
        newAPTTask.Priority__c          = 'Hight';
        
        System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
        ActionPlanTemplateCreationController apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );
        apTemplateController.actionPlanTemplates.aptTasks = new List<APTTaskTemplate__c>();
        apTemplateController.actionPlanTemplates.aptTasks.add( newAPTTask );
    	List<ApTTaskWrapper> taskList =  apTemplateController.getTemplateTasks();
    	
    	//checks that the list is not empty
    	System.assert( !taskList.isEmpty(), 'Task list was not Empty' );
    	
    	Test.StopTest();
    }
    
    public static testMethod void checkTemplateTaskSize(){
    	
    	Test.StartTest();
    	
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ActionPlanTemplate__c apTemplate    = new ActionPlanTemplate__c();
        
        apTemplate.Name = testUtil.createRandomWord();
        
        APTTaskTemplate__c newAPTTask = new APTTaskTemplate__c();
        
        newAPTTask.Subject__c           = testUtil.createRandomWord();
        newAPTTask.Hours_After_Start__c     = 2;
        newAPTTask.Type__c              = 'Email';
        newAPTTask.Priority__c          = 'Hight';
        
        System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
        ActionPlanTemplateCreationController apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );
        apTemplateController.actionPlanTemplates.aptTasks = new List<APTTaskTemplate__c>();
        apTemplateController.actionPlanTemplates.aptTasks.add( newAPTTask );
    	List<ApTTaskWrapper> taskList =  apTemplateController.getTemplateTasks();
    	Integer numTasks = apTemplateController.getTemplateTaskSize();
    	
    	//checks that the list is not empty
    	System.assert( !taskList.isEmpty(), 'Task list was not Empty' );
    	
    	//Checks to see if both methods return same task size
    	System.assertEquals( taskList.size(), numTasks );
    	
    	Test.StopTest();
    }
    
    public static testMethod void checkTemplateSubjectItem(){	
    	
    	Test.StartTest();
    	
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ActionPlanTemplate__c apTemplate    = new ActionPlanTemplate__c();
        
        apTemplate.Name = testUtil.createRandomWord();
        
        APTTaskTemplate__c newAPTTask = new APTTaskTemplate__c();
        
        newAPTTask.Subject__c           = testUtil.createRandomWord();
        newAPTTask.Hours_After_Start__c     = 2;
        newAPTTask.Type__c              = 'Email';
        newAPTTask.Priority__c          = 'Hight';
        
        System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
        ActionPlanTemplateCreationController apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );
        apTemplateController.actionPlanTemplates.aptTasks = new List<APTTaskTemplate__c>();
        apTemplateController.actionPlanTemplates.aptTasks.add( newAPTTask );
    	
    	List<ApTTaskWrapper> taskList	= apTemplateController.getTemplateTasks();
    	List<SelectOption> subjectItems 	= apTemplateController.getTemplateSubjectItems();
    	
    	Test.StopTest();
    }
    
    public static testMethod void testCyclicDependencyFalse(){
    	
    	Test.StartTest();
    	
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ActionPlanTemplate__c apTemplate    = new ActionPlanTemplate__c();
    	
    	APTTaskTemplate__c newAPTTask 	= new APTTaskTemplate__c();
 		APTTaskTemplate__c newAPTTask2 	= new APTTaskTemplate__c();
 		
 		newAPTTask.Subject__c 			= testUtil.createRandomWord();
 		newAPTTask.Hours_After_Start__c 	= 2;
 		newAPTTask.Dependent__c			= 'None';
 		newAPTTask.Type__c 				= 'Email';
 		newAPTTask.Priority__c 			= 'High';
 		
 		newAPTTask2.Subject__c 			= testUtil.createRandomWord();
 		newAPTTask2.Hours_After_Start__c 	= 2;
 		newAPTTask2.Dependent__c		= 'None';
 		newAPTTask2.Type__c 			= 'Email';
 		newAPTTask2.Priority__c 		= 'High';
 		
 		
    	System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
    	ActionPlanTemplateCreationController apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );
    	
    	apTemplateController.actionPlanTemplates.aptTasks = new List<APTTaskTemplate__c>();
		apTemplateController.actionPlanTemplates.aptTasks.add( newAPTTask );

    	apTemplateController.checkCycleDependent();
    	
    	System.assert( apTemplateController.getErrorMsg() == '', 'dependency check failed' );
    	
    	Test.StopTest();
    }
    
    public static testMethod void testCyclicDependencySuccess(){
    	
    	Test.StartTest();
    	
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ActionPlanTemplate__c apTemplate    = new ActionPlanTemplate__c();
    	
    	APTTaskTemplate__c newAPTTask 	= new APTTaskTemplate__c();
 		APTTaskTemplate__c newAPTTask2 	= new APTTaskTemplate__c();
 		APTTaskTemplate__c newAPTTask3 	= new APTTaskTemplate__c();
 		
 		newAPTTask.Subject__c 			= testUtil.createRandomWord();
 		newAPTTask.Hours_After_Start__c 	= 2;
 		newAPTTask.Dependent__c			= '2';
 		newAPTTask.Type__c 				= 'Email';
 		newAPTTask.Priority__c 			= 'Hight';
 		
 		newAPTTask2.Subject__c 			= testUtil.createRandomWord();
 		newAPTTask2.Hours_After_Start__c 	= 2;
 		newAPTTask2.Dependent__c		= '0';
 		newAPTTask2.Type__c 			= 'Email';
 		newAPTTask2.Priority__c 		= 'Hight';
 		
 		newAPTTask3.Subject__c 			= testUtil.createRandomWord();
 		newAPTTask3.Hours_After_Start__c 	= 2;
 		newAPTTask3.Dependent__c		= '1';
 		newAPTTask3.Type__c 			= 'Email';
 		newAPTTask3.Priority__c 		= 'Hight';
 		
 		
    	System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
    	ActionPlanTemplateCreationController apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );
    	
        apTemplateController.savedDependencies = new List<SelectOption[]>();
        apTemplateController.savedDependencies.add(new SelectOption[]{});
        apTemplateController.savedDependencies.add(new SelectOption[]{});
        apTemplateController.savedDependencies.add(new SelectOption[]{});
        apTemplateController.savedDependencies[0].add(new SelectOption('2','Two'));
        apTemplateController.savedDependencies[0].add(new SelectOption('0','Zero'));
        apTemplateController.savedDependencies[0].add(new SelectOption('1','One'));

    	apTemplateController.actionPlanTemplates.aptTasks = new List<APTTaskTemplate__c>();
		apTemplateController.actionPlanTemplates.aptTasks.add( newAPTTask );
		apTemplateController.actionPlanTemplates.aptTasks.add( newAPTTask2 );
		apTemplateController.actionPlanTemplates.aptTasks.add( newAPTTask3 );

    	apTemplateController.checkCycleDependent();
    	System.assert( apTemplateController.getErrorMsg() != null, 'dependency check failed' );
    	Test.StopTest();
    }
}