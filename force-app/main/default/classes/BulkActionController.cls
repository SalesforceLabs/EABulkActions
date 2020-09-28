public with sharing class BulkActionController {
  // Constants used
  // Constant for maximum volume value
  static final String ACCOUNT_IDS = 'AccountIds';
  static final String LEAD_CONTACT_IDS = 'LeadOrContactIds';
  static final String ACCOUNT_ID_COLUMN = 'AccountId';
  static final String LEAD_CONTACT_ID_COLUMN = 'LeadOrContactId';
  static final String CONTACT_ID_FIELD = 'ContactId';
  static final String LEAD_ID_FIELD = 'LeadId';
  static final String LEAD_ID_PREFIX = '00Q';
  static final String CONTACT_ID_PREFIX = '003';
  static final String BULKACTION_COLUMN = 'CustomBulkActions';
  static final String BULKACTION_ADD2CAMPAIGN = 'add to existing campaign';
  static final String BULKACTION_ADD2NEWCAMPAIGN = 'add to new campaign';
  static final String BULKACTION_ADD2LISTVIEW = 'create list view';
  static final String BULKACTION_ERRSTRING_PREFIX = 'Einstein Analytics ~ Salesforce - Bulkactions: ';
  static final String CAMPAIGN_QUERY = 'SELECT Id, Name, OwnerId, StartDate, EndDate, Type, Status, IsActive, NumberOfContacts, NumberOfLeads FROM Campaign WHERE IsActive = true ORDER BY CreatedDate Desc';

  // internal data to store wave records
  public class BulkactionQueryData {
    public String idType;
    public boolean addToCampaign;
    public boolean addToNewCampaign;
    public boolean createListView;
    List<Map<String, String>> accountRecords;
    List<Map<String, String>> contactRecords;
    List<Map<String, String>> leadRecords;
  }

  // validated records given by wave in JSON format
  String recordsFromWave;
  // New Campaign to be added(saved)
  Campaign newCampaign;

  // processed records
  List<Map<String, String>> accountsList;
  List<Map<String, String>> contactsList;
  List<Map<String, String>> leadsList;

  // constructor
  public BulkActionController() {
    System.debug('BulkActionController::BulkActionController');
    size=10;
    paginationSizeOptions = new List<SelectOption>();
    paginationSizeOptions.add(new SelectOption('5','5'));
    paginationSizeOptions.add(new SelectOption('10','10'));
    paginationSizeOptions.add(new SelectOption('20','20'));
    paginationSizeOptions.add(new SelectOption('50','50'));
    paginationSizeOptions.add(new SelectOption('100','100'));
    recordsAvailable = false;
    addToListViewAction = false;
    addToExistingCampaignAction = false;
    addToNewCampaignAction = false;
    recordsFromWave = '';
  }

  // Enabled Actions Properties
  public boolean addToListViewAction { get;
                                      set;
  }
  public boolean addToExistingCampaignAction { get;
                                              set;
  }
  public boolean addToNewCampaignAction { get;
                                          set;
  }

  // Get and Set methods for Query sent by Wave
  public String savedquery { get;
                            set;
  }
  public String createdCampaign { get;
                                  set;
  }

  // Property that tells whether records are available or not
  public boolean recordsAvailable { get;
                                    set;
  }

  // User selected CampaignId to which contacts need to be added
  public String selectedCampaignId { get;
                                    set;
  }

  // pagination variables
  Public Integer size { get;
                        set;
  }
  Public Integer noOfRecords { get;
                              set;
  }
  public List<SelectOption> paginationSizeOptions { get;
                                                    set;
  }

  // Get and Set methods
  public String getrecordsFromWave() {
    return recordsFromWave;
  }

  public void setrecordsFromWave(String s) {
    System.debug('BulkActionController::setrecordsFromWave:' + s);
    recordsFromWave = s;
    processRecordsFromWave();
    if (recordsFromWave.length() > 0) {
      recordsAvailable = true;
    }
  }

  // To determine the records to perform the bulk action on, extract the SAQL query given by Wave
  public PageReference init() {
    savedquery = ApexPages.currentPage().getParameters().get('query');
      if(savedquery == null || savedquery == '') {
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Preview not available for this page. Use bulk actions from a details table in an Analytics dashboard with leads and contacts to assign them to campaigns.'));
        return null;
           }
    System.debug('BulkActionController::init savedquery=' + savedquery);
    return null;
  }

  // Return a list of available campaigns
  public List<Campaign> getCampaigns() {
    System.debug('BulkActionController::getCampaigns');
    return (List<Campaign>) getsetCon().getRecords();
  }

  ApexPages.StandardSetController setCon;

  public ApexPages.StandardSetController getsetCon() {
    System.debug('BulkActionController::getsetCon');
    if (setCon == null) {
      setCon = new ApexPages.StandardSetController(Database.getQueryLocator(CAMPAIGN_QUERY));
    }
    setCon.setPageSize(size);
    noOfRecords = setCon.getResultSize();
    return setCon;
  }

  // Changes the size of pagination
  public void refreshPageSize() {
    System.debug('BulkActionController::refreshPageSize');
    setCon.setPageSize(size);
  }

  public void save() {
    System.debug('BulkActionController::save');
    setCon.save();
  }

  public Campaign getCampaign() {
    System.debug('BulkActionController::getCampaign');
    if (newCampaign == null) {
      newCampaign = new Campaign();
    }
    return newCampaign;
  }

  public void setCampaign(Campaign c) {
    System.debug('BulkActionController::setCampaign');
    newCampaign = c;
  }

  // internal util function to process records from Wave
  private void processRecordsFromWave() {
    if (recordsFromWave.length() != 0) {
      String serializedRecords = recordsFromWave.replaceAll('&quot;','"');

      System.debug('BulkActionController::processRecordsFromWave ' + serializedRecords);

      BulkactionQueryData data = (BulkactionQueryData) JSON.deserialize(serializedRecords, BulkactionQueryData.class);

      System.debug('BulkActionController::processRecordsFromWave data idType=' + data.idType + ' Add2C=' + data.addToCampaign + ' Add2NC=' + data.addToNewCampaign + ' CLV=' + data.createListView);

      addToListViewAction = data.createListView;
      addToExistingCampaignAction = data.addToCampaign;
      addToNewCampaignAction = data.addToNewCampaign;

      for (Map<String, String> record: data.contactRecords) {
        if (contactsList == null) {
          contactsList = new List<Map<String, String>>();
        }

        contactsList.add(new Map<String, String>(record));
      }

      for (Map<String, String> record: data.leadRecords) {
        if (leadsList == null) {
          leadsList = new List<Map<String, String>>();
        }

        leadsList.add(new Map<String, String>(record));
      }
    }
  }

  // newly added campaign is saved to DB
  public void createNewCampaign() {
    System.debug('BulkActionController::createNewCampaign');
      // Check if the user has create access on the Campaign.IsActive field
      if (!Schema.sObjectType.Campaign.fields.IsActive.isCreateable()) {
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Insufficient Campaign Create Field access'));
      }
    List<Campaign> campaigns = new List<Campaign>();
    
    newCampaign.IsActive = true;
    campaigns.add(newCampaign);
    insert campaigns;
    System.debug('BulkActionController::createNewCampaign adding contacts to ' + newCampaign.Id);
    selectedCampaignId = newCampaign.Id;
    createdCampaign = newCampaign.Id;
    setCon = null;
    getSetCon();
    AddToCampaign();
    save();
    newCampaign = null;
  }

  Set<String> getCampaignMemberIds(String selectedCampaignId) {
    List<CampaignMember> campaignMembers = new List<CampaignMember>();
    if (!Schema.sObjectType.CampaignMember.fields.CampaignId.isAccessible() ||
       Schema.sObjectType.CampaignMember.fields.LeadId.isAccessible() ||
       Schema.sObjectType.CampaignMember.fields.ContactId.isAccessible() ||
       Schema.sObjectType.CampaignMember.fields.LeadOrContactId.isAccessible()) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Insufficient CampaignMember Read Field access'));
    }
    campaignMembers = [SELECT Id, CampaignId, LeadId, ContactId, LeadOrContactId FROM CampaignMember WHERE CampaignId = :selectedCampaignId];

    Set<String> memberIds = new Set<String>();

    for (CampaignMember member :campaignMembers) {
      memberIds.add(member.LeadOrContactId);
    }

    return memberIds;
  }

  // Processed contact records are added to selected campaign
  public void AddToCampaign() {
    System.debug('BulkActionController::AddTo CampaignID= ' + selectedCampaignId);
    String errMsg = '';
    boolean anyContactsOrLeadsGiven = false;

    List<CampaignMember> campaignMembers2Add = new List<CampaignMember>();
    Set<String> currentCampaignMemberIds = getCampaignMemberIds(selectedCampaignId);
    if (contactsList != null) {
      anyContactsOrLeadsGiven = true;
      for (Map<String, String> contact2Add :contactsList) {
        String contactId = contact2Add.get(CONTACT_ID_FIELD);
        if (!currentCampaignMemberIds.contains(contactId)) {
          CampaignMember cm = new CampaignMember(CampaignId = selectedCampaignId,
            ContactId = contactId, Status = 'Sent');
          System.debug('BulkActionController::AddTo Adding Contact Id ' + contactId);
            if (!campaignMembers2Add.contains(cm)) {
                campaignMembers2Add.add(cm);
            }
            else {
                System.debug('Contact ' + cm + ' is a duplicate and will not be added again.');
            }
        } else {
          System.debug('BulkActionController::AddTo Contact is already present');
        }
      }
    }

    if (leadsList != null) {
      anyContactsOrLeadsGiven = true;
      for (Map<String, String> lead2Add :leadsList) {
        String leadId = lead2Add.get(LEAD_ID_FIELD);
        if (!currentCampaignMemberIds.contains(leadId)) {
          CampaignMember cm = new CampaignMember(CampaignId = selectedCampaignId,
            LeadId = leadId, Status = 'Sent');
          System.debug('BulkActionController::AddTo Adding Lead Id ' + leadId);
          if (!campaignMembers2Add.contains(cm)) {
                campaignMembers2Add.add(cm);
            }
            else {
                System.debug('Lead ' + cm + ' is a duplicate and will not be added again.');
            }
        } else {
          System.debug('BulkActionController::AddTo Lead is already present');
        }
      }
    }

    if (!campaignMembers2Add.isEmpty()) {
      try {
        if (!Schema.sObjectType.CampaignMember.fields.CampaignId.isCreateable() ||
           !Schema.sObjectType.CampaignMember.fields.LeadId.isCreateable() ||
           !Schema.sObjectType.CampaignMember.fields.Status.isCreateable() ||
           !Schema.sObjectType.CampaignMember.fields.ContactId.isCreateable()) {
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Insufficient CampaignMember Create Field access'));    
        }
        upsert campaignMembers2Add;
        setCon = null;
        getSetCon();
      } catch (DmlException e) {
        errMsg = BULKACTION_ERRSTRING_PREFIX + 'Error inserting campaign members' +  +e.getMessage();
        System.debug('BulkActionController::AddTo ' + errMsg);
        throw new UpdateCampaignException(errMsg);
        // ApexPages.addMessages(e);
      }
    } else if (!anyContactsOrLeadsGiven) {
      errMsg = BULKACTION_ERRSTRING_PREFIX + 'No contacts or leads are found';
      System.debug('BulkActionController::AddTo ' + errMsg);
      throw new UpdateCampaignException(errMsg);
    }
  }

  /* Takes the account records from the SAQL query, creates an opportunity for each account, and then returns a map between account ID and new opportunity name. Note: Account.Name and AccountId referenced below refer to the dataset field names. Update them to match your dataset fields. */
  @RemoteAction
  public static String extractResultRecords(List<Map<String, String>> queryResultRecords) {
    System.debug('BulkActionController::extractResultRecords ' + queryResultRecords);

    BulkactionQueryData data = new BulkactionQueryData();
    data.addToCampaign = true;
    data.addToNewCampaign = true;
    data.createListView = false;
    boolean validDataFound = false;
    data.idType = '';
    String errMsg = '';

    for (Map<String, String> queryResultRecord : queryResultRecords) {
      if (!validDataFound) {
        if (!queryResultRecord.containsKey(LEAD_CONTACT_ID_COLUMN)) {
          errMsg = BULKACTION_ERRSTRING_PREFIX + 'Invalid Query no valid Ids are given';
          System.debug('BulkActionController::extractResultRecords ' + errMsg);
          throw new InvalidWaveQueryException(errMsg);
        }

        data.idType = LEAD_CONTACT_IDS;
        System.debug('BulkActionController::extractResultRecords idType=' + data.idType);

        validDataFound = true;
        // Create a list to hold records
        data.accountRecords = new List<Map<String, String>>();
        data.contactRecords = new List<Map<String, String>>();
        data.leadRecords = new List<Map<String, String>>();
      }

      // valid data is found.
      // copy the record
      if (validDataFound) {
        Map<String, String> fields = new Map<String, String>();

        String nameValue = ((queryResultRecord.get('Name') == null) ? 'Not Found' : queryResultRecord.get('Name'));
        fields.put('Name', nameValue);

        String phoneValue = ((queryResultRecord.get('Phone') == null) ? '' : queryResultRecord.get('Phone'));
        fields.put('Phone', phoneValue);

        String emailValue = ((queryResultRecord.get('Email') == null) ? '' : queryResultRecord.get('Email'));
        fields.put('Email', emailValue);

        String leadOrContactId = queryResultRecord.get(LEAD_CONTACT_ID_COLUMN);
        if (leadOrContactId != null && leadOrContactId.startsWithIgnoreCase(LEAD_ID_PREFIX)) {
          fields.put(LEAD_ID_FIELD, leadOrContactId);
          data.leadRecords.add(fields);
        } else if (leadOrContactId != null && LeadOrContactId.startsWithIgnoreCase(CONTACT_ID_PREFIX)) {
          fields.put(CONTACT_ID_FIELD, leadOrContactId);
          data.contactRecords.add(fields);
        } else {
          System.debug('BulkActionController::extractResultRecords LeadOrContactId is null');
          continue;
        }
      }
    }

    String jsonString;

    if (validDataFound) {
      jsonString = JSON.serialize(data);
      System.debug('BulkActionController::extractResultRecords ' + jsonString);
    }

    return jsonString;
  }

  // empty function used to rerender visualforce page components.
  public void Refresh() {
    return;
  }

  public class InvalidWaveQueryException extends Exception {
  }
  public class UpdateCampaignException extends Exception {
  }
  public class CreateListviewException extends Exception {
  }
}