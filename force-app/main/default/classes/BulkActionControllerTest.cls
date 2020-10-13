/*
Copyright (c) 2020, salesforce.com, Inc.
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

@isTest
private class BulkActionControllerTest {
  // Class to prepare desired test inputs.
  public class variableInputs {
    public List<Map<String,String>> testInputs = new List<Map<String,String>>();
    // Convert sObject details to desired List format
    public void objectToList(List<Contact> retrievedContacts) {
      for (Contact retrievedContact : retrievedContacts) {
        Map<String,String> stringContact = new Map<String,String>();
        new Map<String,String>();
        String nameValue = retrievedContact.Name;
        stringContact.put('Name', nameValue);
        String idValue = retrievedContact.Id;
        stringContact.put('LeadOrContactId', idValue);
        String emailValue = retrievedContact.Email;
        stringContact.put('Email', emailValue);
        String phoneValue = retrievedContact.Phone;
        stringContact.put('Phone', phoneValue);
        testInputs.add(stringContact);
      }
    }

    public void objectToList(List<Lead> retrievedLeads) {
      for (Lead retrievedLead : retrievedLeads) {
        Map<String,String> stringLead = new Map<String,String>();
        String nameValue = retrievedLead.Name;
        stringLead.put('Name', nameValue);
        String idValue = retrievedLead.Id;
        stringLead.put('LeadOrContactId', idValue);
        String emailValue = retrievedLead.Email;
        stringLead.put('Email', emailValue);
        String phoneValue = retrievedLead.Phone;
        stringLead.put('Phone', phoneValue);
        testInputs.add(stringLead);
      }
    }
  }
  // Test Creating Campaigns, adding records to created Campaign.
  public static void testControllerFlow(String successTestInputs) {
    // serialised inputs are encoded according to ASCII values.
    String newTestInputs = successTestInputs.replaceAll('"', '&quot;');
    BulkActionController ba = new BulkActionController();
    // Calling Empty Campaign creates Campaign to add other details.
    Campaign newTestCampaign = ba.getCampaign();
    Campaign emptyCampaign = new Campaign();
    Campaign campaignTest1 = new Campaign(Name = 'Test1');
    System.assertEquals(emptyCampaign, newTestCampaign);
    // Adding required fields to create a new Campaign.
    newTestCampaign.Name = 'Test1';
    ba.setCampaign(newTestCampaign);
    System.assertEquals(campaignTest1,newTestCampaign);
    // Extracting data from inputs generated and adding campaign members.
    ba.setrecordsFromWave(newTestInputs);
    string queryresults = ba.getrecordsFromWave();
    System.assertEquals(newTestInputs, queryresults);
    ba.createNewCampaign();
  }

  // Test only Contacts as inputs.
  @isTest
  public static void testContactInputs() {
    variableInputs data = new variableInputs();
    // Creating test data for adding to Campaigns.
    List<Contact> inputContacts = new List<Contact> {
      new Contact(LastName = 'lastNameOneCon', FirstName = 'firstNameOneCon', Phone = '1232342345', Email = 'one.ConEmail@mail.com'),
      new Contact(LastName = 'lastNameTwoCon', FirstName = 'firstNameTwoCon', Email = 'two.ConEmail@mail.com')
    };
    insert inputContacts;
    List<Contact> retrievedContacts = [SELECT Id, Name, Phone, Email FROM Contact];
    // Converting data in sObject to List of Mapped Strings.
    data.objectToList(retrievedContacts);
    // Creating ecpected assertion as test data is created dynamically.
    String assertConstruct =('{"leadRecords":[],"idType":"LeadOrContactIds","createListView":false,"contactRecords":[{"ContactId":"' + retrievedContacts[0].Id + '","Email":"one.conemail@mail.com","Phone":"1232342345","Name":"firstNameOneCon lastNameOneCon"},{"ContactId":"' + retrievedContacts[1].Id + '","Email":"two.conemail@mail.com","Phone":"","Name":"firstNameTwoCon lastNameTwoCon"}],"addToNewCampaign":true,"addToCampaign":true,"accountRecords":[]}');
    String successTestContacts = BulkActionController.extractResultRecords(data.testInputs);
    System.assertEquals(assertConstruct, successTestContacts);
    // Test addition of retrieved data to Campaigns.
    testControllerFlow(successTestContacts);
  }

  // Test only Leads as inputs.
  @isTest
  public static void testLeadInputs() {
    variableInputs data = new variableInputs();
    // Creating test data for adding to Campaigns.
    List<Lead> inputLeads = new List<Lead> {
      new Lead(LastName = 'lastNameOneLead', FirstName = 'firstNameOneLead', Phone = '1232342345', Email = 'one.LeadEmail@mail.com', Company = 'leadCompany1'),
      new Lead(LastName = 'lastNameTwoLead', FirstName = 'firstNameTwoLead', Phone = '2343453456', Company = 'leadCompany2')
    };
    insert inputLeads;
    List<Lead> retrievedLeads = [SELECT Id, Name, Phone, Email FROM Lead];
    // Converting data in sObject to List of Mapped Strings.
    data.objectToList(retrievedLeads);
    // Creating ecpected assertion as test data is created dynamically.
    String assertConstruct =('{"leadRecords":[{"LeadId":"' + retrievedLeads[0].Id + '","Email":"one.leademail@mail.com","Phone":"1232342345","Name":"firstNameOneLead lastNameOneLead"},{"LeadId":"' + retrievedLeads[1].Id + '","Email":"","Phone":"2343453456","Name":"firstNameTwoLead lastNameTwoLead"}],"idType":"LeadOrContactIds","createListView":false,"contactRecords":[],"addToNewCampaign":true,"addToCampaign":true,"accountRecords":[]}');
    String successTestLeads = BulkActionController.extractResultRecords(data.testInputs);
    System.assertEquals(assertConstruct, successTestLeads);
    // Test addition of retrieved data to Campaigns.
    testControllerFlow(successTestLeads);
  }

  // Test both Leads and Contacts as inputs.
  @isTest
  public static void testContactLeadInputs() {
    variableInputs data = new variableInputs();
    // Creating test data for adding to Campaigns.
    List<Contact> inputContacts = new List<Contact> {
      new Contact(LastName = 'lastNameOneCon', FirstName = 'firstNameOneCon', Phone = '1232342345', Email = 'one.ConEmail@mail.com')
    };
    List<Lead> inputLeads = new List<Lead> {
      new Lead(LastName = 'lastNameOneLead', FirstName = 'firstNameOneLead', Phone = '1232342345', Email = 'one.LeadEmail@mail.com', Company = 'leadCompany1')
    };
    insert inputLeads;
    insert inputContacts;
    List<Contact> retrievedContacts = [SELECT Id, Name, Phone, Email FROM Contact];
    // Converting data in sObject to List of Mapped Strings.
    data.objectToList(retrievedContacts);
    List<Lead> retrievedLeads = [SELECT Id, Name, Phone, Email FROM Lead];
    // Converting data in sObject to List of Mapped Strings.
    data.objectToList(retrievedLeads);
    // Creating ecpected assertion as test data is created dynamically.
    String assertConstruct =('{"leadRecords":[{"LeadId":"' + retrievedLeads[0].Id + '","Email":"one.leademail@mail.com","Phone":"1232342345","Name":"firstNameOneLead lastNameOneLead"}],"idType":"LeadOrContactIds","createListView":false,"contactRecords":[{"ContactId":"' + retrievedContacts[0].Id + '","Email":"one.conemail@mail.com","Phone":"1232342345","Name":"firstNameOneCon lastNameOneCon"}],"addToNewCampaign":true,"addToCampaign":true,"accountRecords":[]}');
    String successTestInputs = BulkActionController.extractResultRecords(data.testInputs);
    System.assertEquals(assertConstruct, successTestInputs);
    // Test addition of retrieved data to Campaigns.
    testControllerFlow(successTestInputs);
  }

  // Test with LeadOrContactId null.
  @isTest
  public static void makeIdNull() {
    variableInputs data = new variableInputs();
    // Creating test data for adding to Campaigns.
    List<Contact> inputContacts = new List<Contact> {
      new Contact(LastName = 'lastNameOneCon', FirstName = 'firstNameOneCon', Phone = '1232342345', Email = 'one.ConEmail@mail.com')
    };
    List<Lead> inputLeads = new List<Lead> {
      new Lead(LastName = 'lastNameOneLead', FirstName = 'firstNameOneLead', Phone = '1232342345', Email = 'one.LeadEmail@mail.com', Company = 'leadCompany1')
    };
    insert inputLeads;
    insert inputContacts;
    List<Contact> retrievedContacts = [SELECT Id, Name, Phone, Email FROM Contact];
    // Converting data in sObject to List of Mapped Strings.
    data.objectToList(retrievedContacts);
    List<Lead> retrievedLeads = [SELECT Id, Name, Phone, Email FROM Lead];
    // Making LeadOrContactId null.
    retrievedLeads[0].id = null;
    // Converting data in sObject to List of Mapped Strings.
    data.objectToList(retrievedLeads);
    // Creating ecpected assertion as test data is created dynamically.
    String assertConstruct =('{"leadRecords":[],"idType":"LeadOrContactIds","createListView":false,"contactRecords":[{"ContactId":"' + retrievedContacts[0].Id + '","Email":"one.conemail@mail.com","Phone":"1232342345","Name":"firstNameOneCon lastNameOneCon"}],"addToNewCampaign":true,"addToCampaign":true,"accountRecords":[]}');
    String successTestInputs = BulkActionController.extractResultRecords(data.testInputs);
    System.assertEquals(assertConstruct, successTestInputs);
    // Test addition of retrieved data to Campaigns.
    testControllerFlow(successTestInputs);
  }

  // Test with no LeadOrContactId coloumn.
  @isTest
  public static void missingIdColumn() {
    variableInputs data = new variableInputs();
    // Creating test data for adding to Campaigns.
    List<Contact> inputContacts = new List<Contact> {
      new Contact(LastName = 'lastNameOneCon', FirstName = 'firstNameOneCon', Phone = '1232342345', Email = 'one.ConEmail@mail.com'),
      new Contact(LastName = 'lastNameTwoCon', FirstName = 'firstNameTwoCon', Email = 'two.ConEmail@mail.com')
    };
    insert inputContacts;
    List<Contact> retrievedContacts = [SELECT Id, Name, Phone, Email FROM Contact];
    // Converting data in sObject to List of Mapped Strings.
    data.objectToList(retrievedContacts);
    // Changing important column name.
    data.testInputs[0].remove('LeadOrContactId');
    // Creating ecpected assertion as test data is created dynamically.
    String assertConstruct =('{"leadRecords":[],"idType":"LeadOrContactIds","createListView":false,"contactRecords":[{"ContactId":"' + retrievedContacts[0].Id + '","Email":"one.conemail@mail.com","Phone":"1232342345","Name":"firstNameOneCon lastNameOneCon"},{"ContactId":"' + retrievedContacts[1].Id + '","Email":"two.conemail@mail.com","Phone":"","Name":"firstNameTwoCon lastNameTwoCon"}],"addToNewCampaign":true,"addToCampaign":true,"accountRecords":[]}');
    try {
      String successTestContacts = BulkActionController.extractResultRecords(data.testInputs);
    } catch (Exception e) {
      System.assert (e.getMessage().contains('Einstein Analytics ~ Salesforce - Bulkactions: Invalid Query no valid Ids are given'));
    }
  }

  // Test with Contact and Lead records null.
  @isTest
  public static void makeRecordsNull() {
    variableInputs data = new variableInputs();
    // Creating test data for adding to Campaigns.
    List<Contact> inputContacts = new List<Contact> {
      new Contact(LastName = 'lastNameOneCon', FirstName = 'firstNameOneCon', Phone = '1232342345', Email = 'one.ConEmail@mail.com')
    };
    List<Lead> inputLeads = new List<Lead> {
      new Lead(LastName = 'lastNameOneLead', FirstName = 'firstNameOneLead', Phone = '1232342345', Email = 'one.LeadEmail@mail.com', Company = 'leadCompany1')
    };
    insert inputLeads;
    insert inputContacts;
    List<Contact> retrievedContacts = [SELECT Id, Name, Phone, Email FROM Contact];
    // Making Contact records null.
    retrievedContacts[0].id = null;
    // Converting data in sObject to List of Mapped Strings.
    data.objectToList(retrievedContacts);
    List<Lead> retrievedLeads = [SELECT Id, Name, Phone, Email FROM Lead];
    // Making Lead records null.
    retrievedLeads[0].id = null;
    // Converting data in sObject to List of Mapped Strings.
    data.objectToList(retrievedLeads);
    // Creating ecpected assertion as test data is created dynamically.
    String assertConstruct =('{"leadRecords":[],"idType":"LeadOrContactIds","createListView":false,"contactRecords":[],"addToNewCampaign":true,"addToCampaign":true,"accountRecords":[]}');
    String successTestInputs = BulkActionController.extractResultRecords(data.testInputs);
    System.assertEquals(assertConstruct, successTestInputs);
    // Test addition of retrieved data to Campaigns.
    try {
      testControllerFlow(successTestInputs);
    } catch (Exception e) {
      System.assert (e.getMessage().contains('Einstein Analytics ~ Salesforce - Bulkactions: No contacts or leads are found'));
    }
  }

  // Testing Individual properties.
  @isTest
  static void testProperties() {
    BulkActionController ba = new BulkActionController();
    // Test Refresh method.
    ba.Refresh();
    // Test init method.
    ba.init();
    // Dummy Test to get list of campaigns as no query.
    List<Campaign> campaignList = ba.getCampaigns();
    // Test pagination size changes. Dummy test.
    ba.refreshPageSize();
  }
}