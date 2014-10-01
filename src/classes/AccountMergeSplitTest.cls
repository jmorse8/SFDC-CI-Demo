/**
 * This class contains unit tests for validating the behavior of AccountMergeSplit Trigger
 *  @author  Neena Koli<nkoli@innoveer.com>
 *  @author  Rajesh Wani<rwani@innoveer.com>
 *  @since   April, 2012
 */
@isTest
private class AccountMergeSplitTest {

   static testMethod void AccountMergeTest() {
        //Getting Case Record Type id
		  schema.describesobjectresult r=Case.sobjecttype.getDescribe();
		  map<string,schema.recordTypeInfo> m=r.getRecordTypeInfosByName();
		  id CaseRecordTypeId=m.get('Impl/Enroll').getRecordTypeid();
        
        //Create Accounts to merging
       list<Account> MasterAccs= new list<Account>();
       list<Account> TobeMergedAccs= new list<Account>();
       
       for(integer i=0;i<1;i++){
       Account MA = new Account(Name='Master Merge Account', Sales_Office__c='After',Unum_Id__c='100'+i);
       MasterAccs.add(MA);
       Account TBMA= New Account(Name='To be Merged Account', Sales_Office__c='Before', Unum_Id__c='1000'+i);
       TobeMergedAccs.add(TBMA);
       }
       
       insert MasterAccs;
       insert TobeMergedAccs;
       
       //Associating Opportunities to the accounts
       list<Opportunity> oppMasteracc= new list<Opportunity>();
       list<Opportunity> opptobemergedacc = new list<Opportunity>();
       date d=date.today()+20;
       
       for(integer i=0;i<1;i++){
       Opportunity opp=new Opportunity(Name='Test Opp Master'+i,Stagename='Qualify',Closedate=d, Accountid=MasterAccs[i].id,Account=MasterAccs[i]);
       oppMasteracc.add(opp);
       Opportunity oppty=new Opportunity(Name='Test Opp To be merged'+i,Stagename='Qualify',Closedate=d, Accountid=TobeMergedAccs[i].id,Account=TobeMergedAccs[i]);
       opptobemergedacc.add(oppty);
       }
       
       insert oppMasteracc;
       insert opptobemergedacc;
       
       //Insert Cases
        list<Case> CaseInsertList= new list<Case>();
        for(integer i=0;i<1;i++){
        	Case c= new Case();
        	c.RecordTypeId=CaseRecordTypeId;
        	c.AccountId=TobeMergedAccs[i].id;
        	c.Status='New';
        	CaseInsertList.add(c);
        }
        
        insert CaseInsertList;
       
       //Creating User for assigning of tasks and events
       Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
       User u = new User(Alias = 'stdu', Email = 'standarduser@testuser.com', EmailEncodingKey = 'UTF-8', LastName = 
                            'Test user name', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey =
                            'America/Los_Angeles', UserName = 'stndusr@test.com');
       insert u;
       
       list<Account_Team__c> AccTeamList = new list<Account_Team__c>();
       for(integer i=0;i<1;i++){
       Account_Team__c at = new Account_Team__c();
       at.User__c=u.id;
       at.role__c='Client Manager';
       at.Account__c=TobeMergedAccs[i].id;
       AccTeamList.add(at);
       }
       
       insert AccTeamList;
       
       
       //Associate Tasks to the Accounts
       list<task> MasterTask = new list<task>();
       list<task> ToBeMergedTask = new list<task>();
       date opentaskdate=date.today()+6;
       
       for(integer i=0;i<1;i++){
                 task t=new task(activitydate=opentaskdate,subject='test task to Master Account'+i,status='Not started',priority='Normal',Ownerid=u.id,whatid=MasterAccs[i].id);
                 MasterTask.add(t);
                task tk=new task(activitydate=opentaskdate,subject='test task to To be Merged Account'+i,status='Not started',priority='Normal',Ownerid=u.id,whatid=TobeMergedAccs[i].id);
                 ToBeMergedTask.add(tk);
             }
       insert MasterTask;
       insert ToBeMergedTask;
       test.startTest(); 
       //AccountMerge Insertion Test
       set<string> MergeToIDList = new set<string>();
            
       //Create Data for MessageStaging table for Account Merge
       date LoadDate= date.today();
       list<MessageStaging__c> InsertMS= new list<MessageStaging__c>();
       for(integer i=0;i<1;i++){
       MessageStaging__c ms = new MessageStaging__c();
       ms.name= 'Test Merge'+i;
       ms.LoadDate__c= LoadDate;
       ms.NewPersistentID__c=MasterAccs[i].UNUM_ID__c;
       ms.OldPersistentID__c=TobeMergedAccs[i].UNUM_ID__c;
       ms.MessageType__c='M';
       ms.Notify__c= TRUE; 
       InsertMS.add(ms); 
       MergeToIDList.add(MasterAccs[i].UNUM_ID__c);            
       }
       insert InsertMS;
       test.stopTest();     
       
       //Assert results for Account Merge
       list<Account> MergedAccounts=[Select id , name from Account where name='To be Merged Account'];
       system.assertEquals(MergedAccounts.size(),0); 
       
       list<AccountMerge__c> AccMergeList = [Select Original_Account_Name__c, Notify__c, Name, MergeToId__c, MergeFromID__c, MergeDate__c, Id From AccountMerge__c where MergeToId__c IN: MergeToIDList];     
       system.assertEquals(AccMergeList.size(),1);
       for(integer i=0;i<1;i++){
       system.assertEquals(AccMergeList[i].Original_Account_Name__c,'To be Merged Account');
       //system.assertEquals(AccMergeList[i].MergeToId__c,String.valueof(InsertMS[i].NewPersistentID__c));
       //system.assertEquals(AccMergeList[i].MergeFromID__c,String.valueof(InsertMS[i].OldPersistentID__c));
       }
       
       list<Case> CaseUpdatedList =[Select id, Sales_Office__c from Case where Accountid IN:MergeToIDList];
       for(Case c: CaseUpdatedList){
       //	system.assertequals(c.Sales_Office__c,'After');
       }
    } 
      
       
     static testMethod void AccountSplitTest() {
        
        //Create Accounts to merging
       list<Account> MasterAccs= new list<Account>();
       list<Account> TobeMergedAccs= new list<Account>();
       
       for(integer i=0;i<150;i++){
       Account MA = new Account(Name='Master Merge Account', Unum_Id__c='100'+i);
       MasterAccs.add(MA);
       Account TBMA= New Account(Name='To be Merged Account', Unum_Id__c='1000'+i);
       TobeMergedAccs.add(TBMA);
       }
       
       insert MasterAccs;
       insert TobeMergedAccs;
       
       //Associating Opportunities to the accounts
       list<Opportunity> oppMasteracc= new list<Opportunity>();
       list<Opportunity> opptobemergedacc = new list<Opportunity>();
       date d=date.today()+20;
       
       for(integer i=0;i<150;i++){
       Opportunity opp=new Opportunity(Name='Test Opp Master'+i,Stagename='Qualify',Closedate=d, Accountid=MasterAccs[i].id,Account=MasterAccs[i]);
       oppMasteracc.add(opp);
       Opportunity oppty=new Opportunity(Name='Test Opp To be merged'+i,Stagename='Qualify',Closedate=d, Accountid=TobeMergedAccs[i].id,Account=TobeMergedAccs[i]);
       opptobemergedacc.add(oppty);
       }
       
       insert oppMasteracc;
       insert opptobemergedacc;
       
       //Creating User for assigning of tasks and events
       Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
       User u = new User(Alias = 'stdu', Email = 'standarduser@testuser.com', EmailEncodingKey = 'UTF-8', LastName = 
                            'Test user name', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey =
                            'America/Los_Angeles', UserName = 'stndusr@test.com');
       insert u;
       
       //Associate Tasks to the Accounts
       list<task> MasterTask = new list<task>();
       list<task> ToBeMergedTask = new list<task>();
       date opentaskdate=date.today()+6;
       
       for(integer i=0;i<150;i++){
                 task t=new task(activitydate=opentaskdate,subject='test task to Master Account'+i,status='Not started',priority='Normal',Ownerid=u.id,whatid=MasterAccs[i].id);
                 MasterTask.add(t);
                task tk=new task(activitydate=opentaskdate,subject='test task to To be Merged Account'+i,status='Not started',priority='Normal',Ownerid=u.id,whatid=TobeMergedAccs[i].id);
                 ToBeMergedTask.add(tk);
             }
       insert MasterTask;
       insert ToBeMergedTask;
       
       //Associated AccountTeam Members
       Profile p1 = [SELECT Id FROM Profile WHERE Name = 'System Administrator' limit 1];
        
        User usr1 = new User();
        usr1.Alias = 'stdu';
        usr1.Email = 'standarduser1@testuser.com';
        usr1.EmailEncodingKey = 'UTF-8';
        usr1.LastName = 'Test1';
        usr1.LanguageLocaleKey = 'en_US'; 
        usr1.LocaleSidKey = 'en_US';
        usr1.ProfileId = p1.Id;
        usr1.TimeZoneSidKey ='America/Los_Angeles'; 
        usr1.UserName = 'stndusr1@test.com';
        usr1.Data_Warehouse_User__c=false;
               
        insert usr1;
       
       list<Account_Team__c> AcctTeam = new list <Account_Team__c>();
       for(integer i=0;i<150;i++){
       Account_Team__c a= new Account_Team__c ();
       a.User__c=Usr1.id;
       a.Role__c='Client Manager';
       a.Effective_Date__c=date.today();
       a.Account__c=TobeMergedAccs[i].id;
       a.Account__r=TobeMergedAccs[i];
       AcctTeam.add(a);
       }
       insert AcctTeam;
       
       test.startTest(); 
                   
       //Create Data for MessageStaging table for Account Merge
       date LoadDate1= date.today();
       list<MessageStaging__c> InsertMSforSplit= new list<MessageStaging__c>();
       for(integer i=0;i<150;i++){
       MessageStaging__c ms = new MessageStaging__c();
       ms.name= 'Test Merge'+i;
       ms.LoadDate__c= LoadDate1;
       ms.NewPersistentID__c=MasterAccs[i].UNUM_ID__c;
       ms.OldPersistentID__c=TobeMergedAccs[i].UNUM_ID__c;
       ms.MessageType__c='S';
       ms.Notify__c= TRUE; 
       InsertMSforSplit.add(ms); 
                  
       }
       insert InsertMSforSplit;
       test.stopTest();   
     
     
       //Assert results for Account Split
       set<id> accountId = new set<id>();
         for (account a: MasterAccs){
         accountid.add(a.id);
         }
       
       list<AccountSplit__c> AccSplitList = [Select SplitTo__c, SplitFrom__c, SplitDate__c, Notify__c, Id, Name, AttachTo__c  From AccountSplit__c where AttachTo__c IN: accountId];
       //system.assertEquals(AccSplitList.size(),50);  
       
    }
}