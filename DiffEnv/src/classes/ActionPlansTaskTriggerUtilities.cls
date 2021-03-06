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
public with sharing class ActionPlansTaskTriggerUtilities {

    public  List<String>            closedTasks     { get; set; }
    public  List<String>            inProgressTasks { get; set; }
    private List<APTaskTemplate__c> dependentAptts  { get; set; }
    private Map<String, Task>       newTaskMap      { get; set; }
    private List<APTaskTemplate__c> updateApttsList { get; set; }
    private List<Task> tasksSendEmail				{ get; set; }
    private List<Task> tasksSendNoEmail 			{ get; set; }

    /**
     * Constructor
     */
    public ActionPlansTaskTriggerUtilities(){
    	
        tasksSendEmail		= new List<Task>();
        tasksSendNoEmail 	= new List<Task>();
    }
    
    /**
    * Initialize the functionalities to Create All dependent Tasks
    * @parms cTasks
    */
    @future
    public static void initDependentTaskWork( List<String> cTasks) {
    	
    	ActionPlansTaskTriggerUtilities apUtils = new ActionPlansTaskTriggerUtilities();
    	apUtils.closedTasks = cTasks;
    	
        if( !apUtils.closedTasks.isEmpty() ){
            
            
            //Mark all APTask as 'Completed' 
            apUtils.updateActionPlansTemplateTask('Completed');
            
            //Get all dependent APTask
            apUtils.dependentActionPlansTemplateTask();
            
            //Create actual Task Map
            apUtils.populateNewTaskMap();
            
            //Finaly, Create all New Tasks and Send DMLOption Emails
            apUtils.populateUpdateApttsList();
            
            Database.DMLOptions dmlo = new Database.DMLOptions();
            
            if(!apUtils.tasksSendEmail.isEmpty()){
            	dmlo.EmailHeader.triggerUserEmail = true;	
            	Database.insert( apUtils.tasksSendEmail, dmlo );
            }
            
            if(!apUtils.tasksSendNoEmail.isEmpty()){
            	dmlo.EmailHeader.triggerUserEmail = false;
            	Database.insert( apUtils.tasksSendNoEmail, dmlo );
            }
            
            Database.update( apUtils.updateApttsList );
        }
    }
 
    /**
     * Update associated aptt of completed task to completed as well
     */
    private void updateActionPlansTemplateTask(String newStatus){
        
        
        List<String>  tasksId = (newStatus=='Completed')? this.closedTasks : this.inProgressTasks;
        
        List<APTaskTemplate__c> closeApttList = new List<APTaskTemplate__c>();
        APTaskTemplate__c[] tempApttList = [ select ap.Status__c from APTaskTemplate__c ap where ap.Id IN : tasksId ];
        
        for ( APTaskTemplate__c aptt : tempApttList ){
            aptt.Status__c = newStatus;
            closeApttList.add( aptt );
        }
        
        update closeApttList ;
    }
    
    /**
     * Get list of dependent Action Plans Template Task
     */
    private void dependentActionPlansTemplateTask() {///BANANA comeback and clean up
        
        System.debug('Closed Tasks::'+this.closedTasks+'::');

        this.dependentAptts = new List<APTaskTemplate__c>();
        List<APTaskTemplate__c> placeHolder_TMP     = new List<APTaskTemplate__c>();
        List<APTaskTemplate__c> unfinishedAptts     = new List<APTaskTemplate__c>();
        List<APTaskTemplate__c> finishedAptts       = new List<APTaskTemplate__c>();
        List<List<String>>      dependent_fields    = new List<List<String>>();
        Set<Integer>            taskIndexID         = new Set<Integer>();
        //Add Action Plan custom object reference Field.
        ////////////Selects any record who had this guy as a parent.
        this.dependentAptts = [select a.Action_Plan__r.SkipWeekends__c, a.Action_Plan__r.Account__c, a.Priority__c, a.Status__c, 
                                 a.Action_Plan__r.Contact__c, a.Action_Plan__r.Lead__c, a.Action_Plan__r.Opportunity__c,
                                 a.Action_Plan__r.Contract__c, a.Action_Plan__r.Case__c, a.Action_Plan__r.Campaign__c ,
                                 a.Action_Plan__r.Start_Date_Time__c, a.Action_Plan__c, a.Type__c, a.Subject__c, a.Due_Date_Time__c, 
                                 a.Dependent__c, a.Name, a.User__c, a.User__r.Name, a.Id, a.Hours_After_Start__c, a.CreatedById,
                                 a.APTaskTemplate__r.Subject__c, a.APTaskTemplate__c, a.SendEmail__c,  a.APTaskTemplate__r.Name, 
                                 a.Reminder__c, a.Comments__c, a.Minutes_Reminder__c
                          from APTaskTemplate__c a where a.APTaskTemplate__c IN : this.closedTasks ];
        /////////////Need to get all records that not have all pre-reqs meet
        unfinishedAptts = [select a.Action_Plan__r.SkipWeekends__c, a.Action_Plan__r.Account__c, a.Priority__c, a.Status__c, 
                                 a.Action_Plan__r.Contact__c, a.Action_Plan__r.Lead__c, a.Action_Plan__r.Opportunity__c,
                                 a.Action_Plan__r.Contract__c, a.Action_Plan__r.Case__c, a.Action_Plan__r.Campaign__c ,
                                 a.Action_Plan__r.Start_Date_Time__c, a.Action_Plan__c, a.Type__c, a.Subject__c, a.Due_Date_Time__c, 
                                 a.Dependent__c, a.Name, a.User__c, a.User__r.Name, a.Id, a.Hours_After_Start__c, a.CreatedById,
                                 a.APTaskTemplate__r.Subject__c, a.APTaskTemplate__c, a.SendEmail__c,  a.APTaskTemplate__r.Name, 
                                 a.Reminder__c, a.Comments__c, a.Minutes_Reminder__c, a.taskIndex__c
                          from APTaskTemplate__c a];

        Set<String> recentFinishedS = new Set<String>();
        
        Set<String> finishedTasks = new Set<String>(this.closedTasks);
        for(Integer i=0;i<unfinishedAptts.size();++i){
            if(finishedTasks.contains(unfinishedAptts[i].Id)){
                if(unfinishedAptts[i].Status__c=='Completed'){
                    recentFinishedS.add(unfinishedAptts[i].Action_Plan__c);
                }
                else{
                    System.debug('This was not suppose to be able to happen.');
                }
            }
        }
        List<String> recentFinishedL = new List<String>(recentFinishedS);
        List<Set<Integer>> completedTasks = new List<Set<Integer>>();
        //List<List<APTaskTemplate__c>> taskGroups = new List<List<APTaskTemplate__c>>();
        for(Integer i=0;i<recentFinishedL.size();++i){
            completedTasks.add(new Set<Integer>());
            //taskGroups.add(new List<APTaskTemplate__c>());
            for(Integer j=0;j<unfinishedAptts.size();++j){
                if(recentFinishedL[i]==unfinishedAptts[j].Action_Plan__c && unfinishedAptts[j].Status__c=='Completed'){
                    completedTasks[i].add( Integer.valueOf(unfinishedAptts[j].taskIndex__c));
                    unfinishedAptts.remove(j);
                    --j;
                }
            }
        }
        System.debug('recentFinishedL::'+recentFinishedL+'::');
        System.debug('completedTasks::'+completedTasks+'::');
        Boolean addToFinish;
        for(Integer i=0;i<recentFinishedL.size();++i){
            for(Integer j=0;j<unfinishedAptts.size();++j){
                if(recentFinishedL[i]==unfinishedAptts[j].Action_Plan__c){
                    System.debug('Looking at AP:'+recentFinishedL[i]+'and task::'+unfinishedAptts[j]+'::');
                    List<String> tmp = ActionPlansUtilities.parseMultiSelect(unfinishedAptts[j].Dependent__c);
                    addToFinish=true;
                    for(Integer k=0;k<tmp.size();++k){
                        System.debug('Check::'+completedTasks[i]+':::'+tmp[k]+';;;;;'+completedTasks[i].contains( Integer.valueOf(tmp[k]))+'::');
                        if(completedTasks[i].contains( Integer.valueOf(tmp[k]) )== false){
                            addToFinish = false;
                            System.debug('Set to false');
                        }
                    }
                    if(addToFinish==true){
                        System.debug('Adding to output'+unfinishedAptts[j]+'::');
                        placeHolder_TMP.add(unfinishedAptts[j]);
                    }
                }
            }
        }     

        System.debug('Initial list::'+this.dependentAptts+'::');
        System.debug('Proper_List??::'+placeHolder_TMP+'::');
        this.dependentAptts = placeHolder_TMP;

    }
    /*private void dependentActionPlansTemplateTask() {
        
        this.dependentAptts = new List<APTaskTemplate__c>();
        //Add Action Plan custom object reference Field.
        this.dependentAptts = [select a.Action_Plan__r.SkipWeekends__c, a.Action_Plan__r.Account__c, a.Priority__c, a.Status__c, 
                                 a.Action_Plan__r.Contact__c, a.Action_Plan__r.Lead__c, a.Action_Plan__r.Opportunity__c,
                                 a.Action_Plan__r.Contract__c, a.Action_Plan__r.Case__c, a.Action_Plan__r.Campaign__c ,
                                 a.Action_Plan__r.Start_Date_Time__c, a.Action_Plan__c, a.Type__c, a.Subject__c, a.Due_Date_Time__c, 
                                 a.Dependent__c, a.Name, a.User__c, a.User__r.Name, a.Id, a.Hours_After_Start__c, a.CreatedById,
                                 a.APTaskTemplate__r.Subject__c, a.APTaskTemplate__c, a.SendEmail__c,  a.APTaskTemplate__r.Name, 
                                 a.Reminder__c, a.Comments__c, a.Minutes_Reminder__c
                          from APTaskTemplate__c a where a.APTaskTemplate__c IN : this.closedTasks ];  

    }*/
    
    /**
     * Cycle through list of dependent Action Plans Template Task and create actual tasks
     */
     private void populateNewTaskMap(){
		List<APTaskTemplate__c> updList = new List<APTaskTemplate__c>();
		Task auxTask;
        this.newTaskMap = new Map<String, Task>();
            
        for( APTaskTemplate__c dependentAptts: this.dependentAptts ){
        	
        	//Create the new task and template
            //check if the task was already created
            List<Task> lt = [Select Id from Task where TaskTemplateId__c   =: dependentAptts.Id];
            if (lt.size()>0){
            	auxTask	= lt[0];
            }else{
   				//Create the new task and template
				auxTask	= new Task();
          	}
           
            auxTask.Subject             = dependentAptts.Subject__c;
            auxTask.Priority            = dependentAptts.Priority__c;
            auxTask.OwnerId             = dependentAptts.User__c;
            auxTask.TaskTemplateId__c   = dependentAptts.Id;
            
            if( dependentAptts.Status__c == null ){
                 auxTask.Status = 'Not Started';
                 dependentAptts.Status__c = 'Not Started';//update status of Task Template
                 updList.add(dependentAptts);
            }
            Datetime dueDate        = this.getCompletedATPTaskDate(dependentAptts.Id);
            Datetime suggestedDate  = System.now();
            Map<Integer, Business_Hours__c> workingHours = ActionPlansUtilities.getWorkingHours();

            dueDate = ActionPlansUtilities.getTimeShift(workingHours, dueDate, dependentAptts.Hours_After_Start__c.intValue());
            suggestedDate = ActionPlansUtilities.getTimeShift(workingHours, suggestedDate, dependentAptts.Hours_After_Start__c.intValue());

            dependentAptts.Due_Date_Time__c = dueDate;
            dependentAptts.Suggested_Due__c = suggestedDate;
            // calculate the due date of the tasks for skip weekends feature
            /*if( dependentAptts.Action_Plan__r.SkipWeekends__c ){
                
                Datetime dueDate        = this.getCompletedATPTaskDate(dependentAptts.Id);
                dueDate                 = dueDate.addHours(dependentAptts.Hours_After_Start__c.intValue());
                Integer addDays         = 0;
                
                // find if the due date fall on a Saturday or Sunday.  Add 1 day for Sunday and 2 for Saturday
                Date refDate        = Date.newInstance( 1900, 1, 7 );  // Jan 7 1900 = Sun
               
                Integer dayOfWeek   = Math.mod( refDate.daysBetween( dueDate.date() ), 7 ); // 0 = Sun ... 6 = Sat
                
                addDays = ( dayOfWeek == 0 )? addDays + 1 : addDays; 
                addDays = ( dayOfWeek == 6 )? addDays + 2 : addDays;
                
                dueDate = dueDate.addDays( addDays );
                
                if(addDays!=0){
                    dueDate = Datetime.newInstance(dueDate.date(), Time.newInstance(8, 0, 0, 0));
                    dependentAptts.Suggested_Due__c = dueDate;//BANANA2
                }

                auxTask.ActivityDate = dueDate.date();
                auxTask.Time_Due__c = dueDate;
                dependentAptts.Suggested_Due__c = d2.addHours( dependentAptts.Hours_After_Start__c.intValue() );//BANANA2
                
            } 
            else{
                //System.debug('Setting time in trigger utils | populateNewTaskMap');
                Datetime d = this.getCompletedATPTaskDate(dependentAptts.Id);
            	dependentAptts.Due_Date_Time__c = d.addHours( dependentAptts.Hours_After_Start__c.intValue() );
                dependentAptts.Suggested_Due__c = d2.addHours( dependentAptts.Hours_After_Start__c.intValue() );//BANANA2
                //System.debug('Due_Date_Time__c:'+dependentAptts.Due_Date_Time__c+'  ::  Suggested_Due__c:'+dependentAptts.Suggested_Due__c +';');
            }*/
            
            this.newTaskMap.put( auxTask.TaskTemplateId__c, auxTask );
        } // end for loop
        
        //will update records for AP Tasks templates whose related tasks was created as Non Started
        if (updList.size()>0){
        	upsert updList;
        }
     }
     
     /**
     * Cycle through list of dependent Action Plans Template Task and create tasks
     */
     private void populateUpdateApttsList(){
        Task t2 ;
        this.updateApttsList = new List<APTaskTemplate__c>();
          
        for( APTaskTemplate__c dependentAptt: this.dependentAptts ){
            
            //Create the new task and template
            List<Task> lt = [Select Id from Task where TaskTemplateId__c   =: dependentAptt.Id];
            if (lt.size()>0){
            	t2	= lt[0];
            }else{
   				//Create the new task and template
				t2	= new Task();
          	}
            
            t2.Subject           = dependentAptt.Subject__c;
            t2.Priority          = dependentAptt.Priority__c;
            t2.OwnerId           = dependentAptt.User__c;
            t2.TaskTemplateId__c = dependentAptt.Id;

            Datetime dueDate        = this.getCompletedATPTaskDate(dependentAptt.Id);
            Datetime suggestedDate  = System.now();
            Map<Integer, Business_Hours__c> workingHours = ActionPlansUtilities.getWorkingHours();

            dueDate = ActionPlansUtilities.getTimeShift(workingHours, dueDate, dependentAptt.Hours_After_Start__c.intValue());
            suggestedDate = ActionPlansUtilities.getTimeShift(workingHours, suggestedDate, dependentAptt.Hours_After_Start__c.intValue());

            dependentAptt.Due_Date_Time__c = dueDate;
            dependentAptt.Suggested_Due__c = suggestedDate;
            //System.debug('Setting time in trigger utils | populateUpdateApttsList');
            /*Datetime d = this.getCompletedATPTaskDate(dependentAptt.Id);
            dependentAptt.Due_Date_Time__c = d.addHours( dependentAptt.Hours_After_Start__c.intValue() );
            Datetime d2 = System.now();
            dependentAptt.Suggested_Due__c = d2.addHours( dependentAptt.Hours_After_Start__c.intValue() );*/
            //System.debug('Due_Date_Time__c:'+dependentAptt.Due_Date_Time__c+'  ::  Suggested_Due__c:'+dependentAptt.Suggested_Due__c +';');

            if( dependentAptt.Comments__c != null ){
                t2.Description = dependentAptt.Comments__c;
            }
            
            //set reminder based on user's default reminder setting
            if( dependentAptt.Reminder__c ){
                t2.isReminderSet 	= dependentAptt.Reminder__c;
                t2.ReminderDateTime = datetime.newInstance( dependentAptt.Due_Date_Time__c.year(), dependentAptt.Due_Date_Time__c.month(), dependentAptt.Due_Date_Time__c.day(), 0, 0, 0 );
                t2.ReminderDateTime = t2.ReminderDateTime.addMinutes( Integer.valueOf( dependentAptt.Minutes_Reminder__c ) );
            } 
            
            //Get Action Plan WhatID
            if( dependentAptt.Action_Plan__r.Account__c != null ){
                t2.WhatId = dependentAptt.Action_Plan__r.Account__c;
            }
            
            if( dependentAptt.Action_Plan__r.Contact__c != null ){
                t2.WhoId = dependentAptt.Action_Plan__r.Contact__c;
            }
            
            if( dependentAptt.Action_Plan__r.Lead__c != null ){
                t2.WhoId = dependentAptt.Action_Plan__r.Lead__c;
            }
            
            if( dependentAptt.Action_Plan__r.Opportunity__c != null ){
                t2.WhatId = dependentAptt.Action_Plan__r.Opportunity__c;
            }
            
            //Add new version Support to Cases , Contracts ans Campaigns
            if( dependentAptt.Action_Plan__r.Campaign__c != null ){
                t2.WhatId = dependentAptt.Action_Plan__r.Campaign__c;
            } 
            
            if( dependentAptt.Action_Plan__r.Case__c != null ){
                t2.WhatId = dependentAptt.Action_Plan__r.Case__c;
            }
            
            if( dependentAptt.Action_Plan__r.Contract__c != null ){
                t2.WhatId = dependentAptt.Action_Plan__r.Contract__c;
            } 
            //Add custom object code
            /*
            if( dependentAptt.Action_Plan__r.CustomObject__c != null ){
                t2.WhatId = dependentAptt.Action_Plan__r.CustomObject __c;
            }
            */
            
                
            t2.Type         = dependentAptt.Type__c;
            t2.Status       = 'Not Started';
            t2.ActivityDate = dependentAptt.Due_Date_Time__c.date();
            t2.Time_Due__c  = dependentAptt.Due_Date_Time__c;
            
            this.newTaskMap.put( t2.TaskTemplateId__c, t2 );
            this.updateApttsList.add( dependentAptt ) ;
            
            //populate the list to send emails or not.
            if(dependentAptt.SendEmail__c){
            	tasksSendEmail.add(t2);
            }else{
            	tasksSendNoEmail.add(t2);
            }
        }
     }
     
     private Datetime getCompletedATPTaskDate( String aptTaskId ){
		Datetime d;
		APTaskTemplate__c lAPT = [Select APTaskTemplate__r.id, APTaskTemplate__r.Due_Date_Time__c from APTaskTemplate__c where id =: aptTaskId];
		
		if ( lAPT != null &&  lAPT.APTaskTemplate__r.Due_Date_Time__c != null){
			d = lAPT.APTaskTemplate__r.Due_Date_Time__c;
		}else{
			d = System.now();
		}
		
		return d;
	}
     
    /**
    * Return a map the user preference associated with a user.
    * @param aptTasks	a list of APTaskTemplate__c custom object 
    * @return userPrefbyUserMap  a map with key UserId and value a user preference.
    */
     private Map<Id,UserPreference> getUserPrefFromAPTaskTemplates( List<APTaskTemplate__c> aptTasks ){
     	
    	Set<Id> usersSet = new Set<Id>();
		for( APTaskTemplate__c apTask : aptTasks){
			usersSet.add(apTask.User__c);
		}
		Map<Id,UserPreference> userPrefsMap = new Map<Id,UserPreference>([ Select u.Value, u.UserId, u.Preference, u.Id From UserPreference u where u.Preference = '58' and u.UserId in :usersSet ]);
		
		// create a map with key TaskTemplateId
		Map<Id,UserPreference> userPrefbyUserMap = new Map<Id,UserPreference>();
		for( UserPreference userPref : userPrefsMap.values()){
			userPrefbyUserMap.put(userPref.UserId,userPref);
		}
		return userPrefbyUserMap; 
    }
    
    /**
    * Update APTasks status to InProgress 
    * @parms cTasks
    */
    @future
    public static void updateAPTasksStatus( List<String> cTasks ) {
    	
    	ActionPlansTaskTriggerUtilities apUtils = new ActionPlansTaskTriggerUtilities();
    	apUtils.inProgressTasks = cTasks;
    	
        if( !apUtils.inProgressTasks.isEmpty() ){
            
            //Mark all APTask as 'Completed' 
            apUtils.updateActionPlansTemplateTask('In Progress');
            
        }
    }    
    
    /**
    * Delete Action Plan Tasks
    * @parms aPTasks
    */
    @future
    public static void deleteAPTasks( List<String> aPTasks ) {
    	
        if( !aPTasks.isEmpty() ){
            
        	delete [select aPT.id from APTaskTemplate__c aPT where aPT.id in : aPTasks];
        }
    }
    
	/**
    * Delete Action Plan Tasks related Tasks
    * @parms apttIds
    */
    @future
    public static void deleteTasks( set<ID> apttIds ) {
    	
        if( !apttIds.isEmpty() ){
            
        	delete [ select Id from Task where Status != 'Completed' and id in :apttIds ];
        }
    }    
    
    /**
    * Generate Action Plan Feeds updates
    * @parms aPTasks
    */
    @future
    public static void generateActioPlanFeeds( List<String> aPlansIds ) {
    	ActionPlansUtilities apUtil = new ActionPlansUtilities();
        if( !aPlansIds.isEmpty() ){
            for( String apId : aPlansIds ) {
                apUtil.generateObjectFeed( apId );
            }
        }
    }
    
    /*
    	This method reviews the task list and removes the one with taskIndex__c field matching tmp_taskIndex. 
    	Rearranges the dependencies between tasks.
    
    */
    private static void generateDependentTasksAndReset(List<APTaskTemplate__c> apTasks, Double tmp_taskIndex ){
        List<String> pendingIdsToDelete = new List<String>();
            
		Integer taskIndex ;
        APTaskTemplate__c apTask;
        Integer dependentApTask;       
      
		for( Integer t_i = 0; t_i < apTasks.size();  t_i++ ){			
			apTask = apTasks.get(t_i);
			if (apTask.taskIndex__c == tmp_taskIndex){
				taskIndex = t_i;
			}
		}
		
		
        //update the current dependent position from tasks below of deleted one.
        for( Integer i = 0; i < apTasks.size(); i++ ){

        	apTask = apTasks.get( i );
        	
    		if( apTask.Dependent__c != 'None' && apTask.Dependent__c != null ){
	    		dependentApTask = Integer.valueOf( apTask.Dependent__c );
	    		
	    		if( dependentApTask > taskIndex ){
	    			apTask.Dependent__c = String.valueOf( dependentApTask - 1 );	
	    		}else {
		    		if( dependentApTask == taskIndex ){
	    				apTask.Dependent__c 		= 'None';
	    				apTask.APTaskTemplate__c    = null;
	    			}
	    		}
    		}
        }
            
        // before remove check if it's exists in the DB, if so, add to pendingDeletes to be deleted on save.
        if( apTasks[taskIndex].Id != null ){
            pendingIdsToDelete.add(apTasks[taskIndex].Id);
        }

        apTasks.remove( taskIndex );
       
        ActionPlansTaskTriggerUtilities apUtils = new ActionPlansTaskTriggerUtilities();
		apUtils.closedTasks = pendingIdsToDelete;
    	
		if( !apUtils.closedTasks.isEmpty() ){
	            
			//Get all dependent APTask
			apUtils.dependentActionPlansTemplateTask();
	            
			//Create actual Task Map
			apUtils.populateNewTaskMap();
	            
			//Finaly, Create all New Tasks and Send DMLOption Emails
			apUtils.populateUpdateApttsList();
	            
            Database.DMLOptions dmlo = new Database.DMLOptions();
            
            if(!apUtils.tasksSendEmail.isEmpty()){
            	dmlo.EmailHeader.triggerUserEmail = true;	
            	Database.insert( apUtils.tasksSendEmail, dmlo );
            }
            
            if(!apUtils.tasksSendNoEmail.isEmpty()){
            	dmlo.EmailHeader.triggerUserEmail = false;
            	Database.insert( apUtils.tasksSendNoEmail, dmlo );
            }

        }
            /* */
            
			Database.update(apTasks);
    }
    
    /**
    * Before deleting a APTemplate task , Initialize the functionalities to Create All dependent Tasks and reset index
    * @parms cTasks list with Task templates to be deleted
    */
    public static void initDependentTasksAndReset( List<String> cTasks ) {
    	
    	
    	try{
	    	
	    	ActionPlansTaskTriggerUtilities apUtils = new ActionPlansTaskTriggerUtilities();
	   		Map<String,APTaskTemplate__c> apIdsMaps = new Map<String,APTaskTemplate__c>();
	    	List<APTaskTemplate__c>  lAPT = [select  a.Id , a.Action_Plan__c , a.taskIndex__c , a.Dependent__c
											from APTaskTemplate__c a 
											where id  in: cTasks ];
			
			//create a map with : (APTaskId, APTaskTemplate)
			for(APTaskTemplate__c ap : lAPT){
				apIdsMaps.put(ap.Action_Plan__c,ap);
			}								
	    	
	    	List<APTaskTemplate__c>  tmp_lAPT;
	    	APTaskTemplate__c aux;
	    	for(String apId : apIdsMaps.keySet()){
	    		
				tmp_lAPT = [select  a.Id ,a.Action_Plan__c ,a.taskIndex__c , a.Dependent__c
									from APTaskTemplate__c a 
									where a.Action_Plan__c  =: apId ];
				//
				aux = apIdsMaps.get(apId);
				ActionPlansTaskTriggerUtilities.generateDependentTasksAndReset(tmp_lAPT,aux.taskIndex__c);
				
	    	}
    	}catch(Exception e){
    		system.debug(Logginglevel.INFO,'\n\n====EXEPTION : '+e);
    	}
    
    }
}