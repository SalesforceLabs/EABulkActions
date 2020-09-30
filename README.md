# EA Bulk Actions

This app provides the user the ability to leverage the custom action button on EA Lenses to launch a bulk action.

The action provided is the ability to bulk add contacts or leads to a marketing campaign based on the SOQL filter passed from the lens.

In the lens used to supply the lead or contact id, the column containing the id must be labelled LeadOrContactId. If it is not the user will
get an error indicating this column is missing.

# Developer Notes

The app contains tests for the package and the % coverage must be > 85% for any pull request to be considered. Ideally the requestor should provide as close to 100% coverage on the new code being added (within reason).

There are a number of limits that this app does have

1) 10k upper limit on the number of rows we can return.
2) ~8k upper limit on the number of new campaign members we can add. In this case we hit an execution time limit.
3) DML limit in the event that triggers on the CampaignMember object invoke other SOQL actions.

On init, the remote method processRecordsFromWave via apexAssignContactsRecords gets called to provide a list of the data passed to the bulk action via a SAQL query. The first 5 results get displayed on the page. The App tries to show the email,name and phone number for the contacts.

The app allows the user to create a new Campaign OR select an existing campaign to add leads or contacts to.

