# Dative Help

Dative is an application for linguistic fieldwork. It helps groups of
fieldworkers to build corpora of language data collaboratively.

This help document contains information to help you in using Dative. It
is fully searchable using the search field above. For additional help with
using this help document see the [Help with the Help](#help-with-the-help)
section.

**Note:** In its current state of development, Dative works with OLD web
services. It does not yet work with
{{FieldDB.FieldDBObject.application.brand}}-style web services. Therefore, this
help document currently assumes that you are using Dative to interact with an
OLD web service.


## Table of Contents<a name="toc"></a>

<!--- - [QuickStart](#quickstart) -->
- [About Dative](#about-dative)
- [Resources](#resources)
- [Application Settings](#application-settings)
- [Forms](#forms)
- [Files](#files)
- [Texts](#texts)
- [Corpora](#corpora)
- [Parsers](#parsers)
- [Other resources](#other-resources)
- [Help with the Help](#help-with-the-help)
- [Keyboard Shortcuts](#keyboard-shortcuts)
- [FAQ](#frequently-asked-questions)

<!---
## QuickStart<a data-name="quickstart"></a>

Using Dative is all about entering linguistic fieldwork data, refining it,
browsing it, searching through it, and using it to write papers, develop
learning materials, or generate documentary or archive-quality artifacts.

Dative can work with both
[{{FieldDB.FieldDBObject.application.brand}}]({{FieldDB.FieldDBObject.application.website}})
and [OLD](http://www.onlinelinguisticdatabase.org/)-type web servers. This
means that if you have an account with
{{FieldDB.FieldDBObject.application.brand}} or an OLD application, you can use
Dative to work with your existing corpora and data sets.

If you have an account with a {{FieldDB.FieldDBObject.application.brand}} or an OLD server, the first step
is to login by clicking on the lock icon <i class="fa fa-fw fa-lock"></i> in
the top right or by clicking on Account > Login. In the login dialog that
appears, select the appropriate server, enter your username and password,
and click the “Login” button. If you have a {{FieldDB.FieldDBObject.application.brand}} account, you will most
likely want to login to the server called “{{FieldDB.FieldDBObject.application.brand}}”. If you are unable to
login, you may need to manually create a new server (see the [application
settings](#application-settings) section).

If you do not have a {{FieldDB.FieldDBObject.application.brand}} account, you may create one through Dative.
First, open the registration form by clicking on Dative > Register (or
by pressing ⌃R). Choose a {{FieldDB.FieldDBObject.application.brand}}-type server to register with,
enter your desired username and password (and your email), and click the
“Register” button and an account will be generated for you.

Once you have successfully logged in, you will be brought either to the
corpora interface (if you have logged into a {{FieldDB.FieldDBObject.application.brand}} server) or to the
browse forms interface (if you have logged into an OLD server). At the
corpus interface, you must choose the {{FieldDB.FieldDBObject.application.brand}} corpus that you
wish to use; you do this by clicking on the “activate corpus” button
<i class="fa fa-fw fa-toggle-off"></i>. This will take you to the browse
forms interface where you can view the data in the corpus, make modifications,
perform searches, export, etc.

-->

## About Dative<a data-name="about-dative"></a>

Dative is an application for linguistic fieldwork. It allows you to create
web-accessible data sets in collaboration with other field workers, linguists,
language documenters, speakers, educators, etc. Dative helps you to structure
search, analyze, share, and export your data.

<img style="float: right; margin: 1em 0 1em 1em;"
  src="/images/help/dative-old-lingsync-200.jpg">

Dative is a graphical user interface that runs in modern web browsers. The data
that you enter into Dative are saved to the web service (a general-purpose
program that runs on a web server) that you are logged into at the time.  This
web service may be a
[{{FieldDB.FieldDBObject.application.brand}}]({{FieldDB.FieldDBObject.application.website}})
one or an [OLD](http://www.onlinelinguisticdatabase.org/) one. 
{{FieldDB.FieldDBObject.application.brand}} and the OLD are services that allow
linguistic data to be stored and manipulated on web servers by multiple users
at the same time.

In order to log in to an OLD or {{FieldDB.FieldDBObject.application.brand}} web
service, you must know the web service's URL and you must create a Dative
“server” object for that web service in Dative’s
[application settings](#application-settings).

Dative is written in CoffeeScript (and HTML and CSS) using the Backbone
framework. It is open source and its source code can be found on
[GitHub](https://github.com/jrwdunham/dative).

<!--- ![Dative-OLD-FieldDB architecture](/images/dative-old-lingsync-500.jpg "How Dative works with the OLD and {{FieldDB.FieldDBObject.application.brand}}") -->


## Resources<a data-name="resources"></a>

Dative is designed around the concept of “resources”. A resource is a
collection of items of the same type, which can undergo a small set of
operations via a standard interface. The four operations that all Dative
resources allow are as follows.

- view ([one](#viewing-single-resource) or [many](#browsing-resources))
- [create](#create-resource)
- [update](#update-resource)
- [destroy](#destroy-resource)

Certain resources allow additional operations, such as
[search](#search-resources) and [export](#export-resources).

The primary resources in Dative are *forms*, *files*, *texts* (a.k.a.
“collections”), and *corpora*. Additional resources include *sources*,
*speakers*, *searches*, *phonologies*, and *morphological parsers*.

Since Dative provides the same type of interface to all resources, this section
describes how to perform the above-mentioned operations on any resource.


### Browsing Resources<a data-name="browsing-resources"></a>

Dative provides a browsing interface for viewing multiple resources at the same
time. How to access the browsing interface depends on the resource. To browse
form resources, click on “Forms” in the top menu bar and then “Browse”.
Alternatively, you may use the keyboard shortcut ^B (i.e., control B). The
browse interfaces for the other resources can be accessed under the
“Resources” or “Analysis” menus.

The screenshot below shows what browsing forms in Dative looks like.

![screenshot of browsing forms](/images/help/browse-forms-500.png)

The resource browsing interface contains a header, which displays information
about the set of resources being browsed and controls for performing operations on
that set, as well as a body of resources.

The header tells you what you are browsing–e.g., all corpora, a search over
files, a corpus of forms–as well as how many items are in the set that you
are viewing, what page you are viewing, etc. The functions of the control
buttons in this header are as follows.

- <i class="fa fa-fw fa-plus"></i>: open the interface for creating a new
  resource.
- <i class="fa fa-fw fa-angle-double-down"></i>: expand all of the
  visible resources so that all of their data are visible.

- <i class="fa fa-fw fa-angle-double-up"></i>: collapse all of the
  visible resources so that only their primary fields are visible.

- <i class="fa fa-fw fa-search"></i>: open the search interface for searching
  over the set of resources.

- <i class="fa fa-fw fa-download"></i>: open the export interface so you can
  choose an export option for exporting the collection of resources and saving
  it to your computer.

- “labels” <i class="fa fa-fw fa-toggle-on"></i>: toggle the labels on the
  field displays of the visible resources.

- <i class="fa fa-fw fa-question"></i>: open this help dialog to the
  section that is relevant for understanding how to browse the resource at hand.

- <i class="fa fa-fw fa-angle-double-left"></i>: navigate to the first page.

- <i class="fa fa-fw fa-angle-left"></i>: navigate to the previous page.

- <i class="fa fa-fw fa-angle-right"></i>: navigate to the next page.

- <i class="fa fa-fw fa-angle-double-right"></i>: navigate to the last page.

The controls in the center of the bottom row allow you to jump to other nearby
pages and to choose how many resources are displayed per page.


### Viewing a Single Resource<a data-name="viewing-single-resource"></a>

A single resource may be displayed in a browsing interface (along with other
resources of the same type), or it may also be displayed in a modal dialog
window, or it may occupy the entire main page of Dative. In all cases, however,
the interface to the resource is the same.

![screenshot of viewing a file](/images/help/view-file-500.png)

The screenshot above illustrates how a file resource is displayed in Dative.
This is a video file. The controls at the top of the resource interface have
the following functions.

- <i class="fa fa-fw fa-angle-up"></i>: hide the secondary fields of the
  resource.

- <i class="fa fa-fw fa-angle-down"></i>: show the secondary fields of the
  resource.

- “labels” <i class="fa fa-fw fa-toggle-on"></i>: toggle (i.e., show/hide)
  the labels of just this resource.

- <i class="fa fa-fw fa-file-o"></i> (<i class="fa fa-fw fa-file-video-o"></i>
  <i class="fa fa-fw fa-file-audio-o"></i>, etc.): reveal (and play or display)
  the file data of the resource. (Relevant only for file resources.)

- <i class="fa fa-fw fa-pencil-square-o"></i>: edit (i.e., update) the resource.

- <i class="fa fa-fw fa-download"></i>: open the export interface so you can
  choose an export option for exporting this resource and saving it to your
  computer.

- <i class="fa fa-fw fa-trash"></i>: destroy (i.e., delete) this resource. Note
  that a confirm dialog will pop up when you click this button and it will ask
  you to confirm that you reall want to delete the resource in question.

- <i class="fa fa-fw fa-copy"></i>: duplicate this resource. Clicking this
  button will cause the “create new” interface to be opened with the
  information from the to-be-duplicated resource in its input fields.

- <i class="fa fa-fw fa-history"></i>: view the history of this resource.
  Clicking this button will cause any previous versions of this resource to be
  displayed.

Note that you can navigate directly to a particular resource if you know its
unique id value. Just change the path of the URL in the address bar of your
browser so that it consists of the number sign “#”, followed by the name of
the resource (with words separated by hyphens), followed by a forward slash,
followed by the id value and Dative will display that resource in its main
page. Some examples:

- *#form/25109* displays the form with id 25109
- *#morphological-parser/55* displays the morphological parser with id 55



### Creating a New Resource<a data-name="create-resource"></a>

Clicking on the <i class="fa fa-fw fa-plus"></i> button in a resources browse
interface will reveal the interface for creating a new resource of that type.
The screenshot below shows the interface for creating a new form resource.

![screenshot of creating a new form](/images/help/create-form-500.png)

After entering some information into the fields, clicking the “Save” button
will trigger a request to the web service that the resource be saved on the
server. If invalid information is entered into the resource creation fields,
then the system will alert you to this and will not trigger a create request to
the server.

- <i class="fa fa-fw fa-times"></i>: hide the interface for creating a new
  resource.

- <i class="fa fa-fw fa-angle-down"></i>/<i class="fa fa-fw fa-angle-up"></i>:
  show/hide the secondary input fields for creating this type of resource.

- <i class="fa fa-fw fa-eraser"></i>: clear any information that may be in the
  input fields. This button resets the resource creation form to its default
  state.

- <i class="fa fa-fw fa-question"></i>: open this help dialog to the
  section that is relevant for understanding how to create resources of the
  given type.

- “Save”: click this button to validate the data in the input fields and
  trigger a create request against the web service. Note that the keyboard
  shortcut Control + Enter does the same thing as clicking “Save”.


### Updating an Existing Resource<a data-name="update-resource"></a>

Clicking on the <i class="fa fa-pencil-square-o fa-fw"></i> button at the top
of a resource will reveal the interface for updating that resource. (Note that
for form resources you may need to click on the form first, in order to reveal
the control buttons.)

The update interface for a resource is, for the most part, identical to the
create interface, except that the existing data of the resource will be present
in the input fields in the update case. Note that as information is entered,
the display representation of the resource will be updated in real time.

The <i class="fa fa-undo fa-fw"></i> button will undo changes. That is, it will
return the information in the input fields to their initial values, i.e., to
the values that they had before you began making changes.



### Destroying a Resource<a data-name="destroy-resource"></a>

To destroy (i.e., delete) a resource, click on the
<i class="fa fa-trash fa-fw"></i> button at the top of the resource's interface.
Doing this will cause a confirm dialog to be displayed. You must click the
“Ok” button in order to issue the destroy request. You may also click
“Cancel” (or press Esc) in order to abort the destroy action.

![screenshot of deleting a form](/images/help/destroy-form-500.png)

Note that, depending on the web service that you are connecting to via Dative,
your destroyed data may be preserved in some state on the server. OLD web
services make backup copies of all forms, texts, corpora, parsers, phonologies,
morphologies, and language models whenever a successful destroy request occurs.
{{FieldDB.FieldDBObject.application.brand}} web services do not actually
destroy forms (i.e., datums), they simply tag them as deleted and behave as
though they were deleted. This means that, in general, your deleted resources
may be recoverable.



### Searching through Resources<a data-name="search-resources"></a>

Searchable resources will have a button with the icon
<i class="fa fa-fw fa-search"></i> in the top control bar of the resource
browse interface. (When using an OLD web service, the form, file, text (i.e.,
collection), language, search, and source resources are all searchable.)
Clicking this button will reveal the search interface at the top of the
resource browse page.

Dative provides two types of search interface: [advanced
search](#advanced-search) and [smart search](#smart-search). Click the
“Advanced Search” button to reveal the advanced search interface. Click the
“Smart Search” button to reveal the smart search interface.

- <i class="fa fa-fw fa-times"></i>: hide the search interface.

- “Browse All”: return to browsing *all* of the resources of the given
  type. That is, escape from browsing the results of a search that has been
  executed.

- <i class="fa fa-fw fa-refresh"></i>: refresh the search interface, i.e.,
  reset the search interfaces to their default states.

- <i class="fa fa-fw fa-question"></i>: open this help dialog to the
  section that is relevant for understanding how to search over resources of the
  given type.


#### Advanced Search<a data-name="advanced-search"></a>

The advanced search interface allows you to specify multiple conditions on the
types of resource that you want to view. The screenshot below shows an example
of an advanced search over form resources.

![screenshot of an advanced search](/images/help/advanced-search-500.png)

In the screenshot above, we see an advanced search expression which requires
that all matching forms have both of the following properties:

1. the morpheme break value contains the morpheme *áak* (a future-marking
   prefix in Blackfoot); and

2. the form does *not* contain the string *will* in any of its translations.

Searches of arbitrary structural complexity can be created by using the “and”,
“not”, “or”, or “...” buttons to create more boolean nodes or
change existing ones. By changing the select menus you can change the field
that a given search condition is targeting or you can change the type of search
from, say, a regular expression search (*regex*) to an exact match search (*=*).

- “Search”: this button will execute the search on the server and cause the
  browse interface to display the matching resources, if there are any.

- “Count”: this button will execute the search on the server but Dative
  will respond simply by telling you how many resources match your search. This
  can be useful when you just want to test whether a search returns anything.

- “Save”: this button, if present, will open up a new search resource in a
  dialog box. This new search resource will contain the current search within
  it. You can give the search resource a name and (optionally) a description,
  and click its own “Save” button to save it to the web service. At
  present, only searches over (OLD) form resources can be saved. Saved searches
  can be used later, shared with collaborators, and/or used to create
  sub-corpora.

When browsing a set of search results, Dative will highlight the portions of
the resource field values that were matched by the specified search.


#### Smart Search<a data-name="smart-search"></a>

The smart search interface has a single search input. Dative tries to guess
what you want to search for, given your input, and reports back on the type of
searches it thinks you're after and how many results they would return. The
screenshot below shows an example of a smart search for “dog” and the
suggestions that Dative has returned.

![screenshot of an advanced search](/images/help/smart-search-500.png)

In the screenshot above, the user has requested a smart search for the string
“dog”. Dative responds by reporting on the number of results that various
types of “dog”-like searches will return.

The “Example” button will reveal a resource that matches the particular
search suggested by the smart search interface. The “Browse” button will
cause the browse interface to display the resources that match the search in
question.

Note that when you click “Browse” the advanced search interface will contain the
advanced search that is being used to build the search that you have chosen via
the smart search interface. That is, all smart search suggestions are advanced
searches underlyingly and may be saved to the server, as described in the
[advanced search](#advanced-search) section above.


### Exporting Resources<a data-name="export-resources"></a>

Clicking the button with the icon <i class="fa fa-fw fa-download"></i> in the
top control bar of the resource browse interface, or in the control bar of a
particular resource display interface, will reveal an export interface that
displays the exporters available to that resource or collection thereof. If you
are browsing search results, the export interface will assume that you want to
export the resources that match the search that you are browsing.

![screenshot of an export interface](/images/help/forms-export-500.png)

The screenshot above shows the export interface for a collection of form
resources. The two exporters currently available will create exports in CSV
(i.e., comma-separated values) and JSON (i.e., JavaScript Object Notation)
formats.

You click the “Export” button to generate an export file using a given
exporter. When the export file has been generated, clicking on the revealed
link (in this case,
“<i class="fa fa-fw fa-file-o" ></i>forms-2015-09-29T17:56:26.989Z.csv”)
will cause the file to be downloaded to your computer.

CSV files can be opened in a spreadsheet program like Microsoft Excel,
OpenOffice or Google Sheets.

JSON files can be parsed by most modern programming languages.



## Application Settings<a data-name="application-settings"></a>

Dative's application settings allows you to:

1. <i class="fa fa-fw fa-server"></i>
   [Configure servers](#configuring-servers), i.e., connections to
   {{FieldDB.FieldDBObject.application.brand}} or OLD web services.

2. <i class="fa fa-fw fa-picture-o"></i>
   [Change the appearance](#changing-appearance) (i.e., theme) of
   the application.

3. <i class="fa fa-fw fa-server"></i><i class="fa fa-fw fa-gears"></i>
   [Configure server settings](#configuring-server-settings), i.e., the
   settings for a particular {{FieldDB.FieldDBObject.application.brand}} or OLD
   web service.

When you are in a Dative application settings sub-interface, click the
<i class="fa fa-fw fa-th-large"></i> button to return to the top-level
application settings interface.


### Configuring Servers<a data-name="configuring-servers"></a>

A “server” in this context is a {{FieldDB.FieldDBObject.application.brand}}
or OLD web service that receives, stores, and returns linguistic data. A server
is defined by a name, a URL, a type
(“{{FieldDB.FieldDBObject.application.brand}}” or “OLD”), and
potentially a server code.

To change the active server, simply select one of the existing servers from
the *Active Server* select menu, or click on that server's
<i class="fa fa-fw fa-toggle-off"></i> button. Note that you cannot change the
active server while you are logged in to a server.

To create a new server, click on the <i class="fa fa-fw fa-plus"></i> button to
reveal the interface for creating a new one. In the new server form, enter a
name, the server's URL, its type, and (if it’s a FieldDB-type server) its
server code. If you do not know which server code value to choose, then choose
“production.” If you do not know which values to enter to create a new
server, please contact your {{FieldDB.FieldDBObject.application.brand}} or OLD
server administrator. Note that there is no “Save” button for creating
servers: Dative saves all of your application settings changes automatically to
your browser's local storage.

To delete a server configuration, click its <i class="fa fa-fw fa-trash"></i>
button. A confirm dialog will verify that you really want to proceed with the
deletion.

Note that you cannot delete or modify a server while it is the designated
active one.


### Changing Dative's Appearance<a data-name="changing-appearance"></a>

To change how Dative looks, simply click on one of the example form resources
in the application settings appearance sub-section. The form examples
illustrate how Dative will look using each of the possible visual themes.

Note that the interface has not been fully tested with all of these themes so
some things may be difficult or impossible to view using a particular theme.
Two themes that are known to work well with Dative are “Pepper Grinder” and
“Cupertino”.


### Configuring Server Settings<a data-name="configuring-server-settings"></a>

At present, Dative only allows for the configuration of an OLD web server's
application settings. Support for viewing and altering the settings of a
{{FieldDB.FieldDBObject.application.brand}} web service will be available soon.

The interface for configuring the settings of a server (i.e., a particular
server-side web service) works very much like the standard
[resource interface described above](#viewing-single-resource). Note that you
must be an administrator in order to have permission to modify a web service's
application settings.


#### Configuring OLD Server Settings<a data-name="configuring-old-server-settings"></a>

An OLD web service's application-wide settings are used to identify the
language being documented (the “object language”), the language used to
document and analyze (the “metalanguage”), validation settings for various
form transcription fields, and the set of users designated as “unrestricted”.


##### Object Language

The object language, i.e., the language being documented via the OLD web
service being configured, is specified via the *object language name* and
*object language id* fields. The former may be anything you want. However, the
latter must be an
[ISO 639-3 three-letter language identifier code](http://www-01.sil.org/iso639-3/codes.asp).
Luckily, the OLD and Dative contain a copy of the ISO 639-3 language database so
that the application settings interface's input fields will help you to find the
appropriate code for the language that you are documenting/analyzing. If the
language categorization of ISO 639-3 standard is not suitable or appropriate for
your language of documentation, then leave the object language id field blank.

Note that the *object language name* field will also autosuggest language
“reference names” from the ISO 639-3 standard. This is merely a convenience;
the system does *not* require that you use these reference names.


##### Metalanguage

The metalanguage is the language that you are using to translate the object
language and to transcribe your metadata about the object language. Like the
object language, the metalanguage is specified via *name* and *id* fields and
the *id* field must (if it is not empty) contain an
[ISO 639-3 three-letter language identifier code](http://www-01.sil.org/iso639-3/codes.asp).

An (orthographic) inventory (i.e., an alphabet) can also be specified for the
metalanguage. At present, neither Dative nor the OLD use the metalanguage
inventory for anything. However, this information may be used down the road,
e.g., for collating a metalanguage-to-object-language dictionary interface to
your Dative/OLD data.


##### Form Field Validation

**Important Notice:** form field validation is not yet implemented in Dative.
That is, while you can specify inventories and validation settings via Dative's
interface, they will have no effect at present.

The following form fields can be configured to have validation:

- transcription
- morpheme break
- narrow phonetic transcription
- phonetic transcription



## Forms<a data-name="forms"></a>

The form is the primary resource type in Dative. It is a textual representation
of a morpheme, word, phrase, or sentence. Forms can be associated to any number
of files and they can be used to build corpora and texts (i.e., collections).


### Importing Forms<a data-name="importing-forms"></a>

You can import CSV files into Dative. CSV, i.e., comma-separated values, is a
file format that most spreadsheet applications (e.g., Excel) can export to.
Each line of a CSV file represents one “thing” and the attributes of that
thing are separated by commas. To import a CSV file into Dative, each line
should represent a form and the strings between commas on each line should be
the values of attributes for your forms. The first line may be a header row
which labels the columns, i.e., the form attributes. The very simple example
CSV file below can be imported into Dative.

```
transcription,translations
chien,dog
chat,cat
oiseau,bird
```

To open the import interface, click the import button (<i class="fa fa-fw
fa-upload"></i>) at the top of the forms browse interface. Click “Choose
file” and select a CSV file from your computer. The CSV file will be parsed
and displayed as a table. The example CSV file shown above would be displayed
as in the screenshot below.

![screenshot of importing a simple CSV file](/images/help/simple-csv-import-500.png)

To import all of the forms encoded in the CSV file, make sure that all of the
rows of the table are selected (<i class="fa fa-fw fa-check-square"></i>) and
click the “Import Selected” button. When this button is clicked, Dative
will first validate all of the selected rows and then attempt, for each row in
sequence, to create a form for that row and save it to the server. If errors or
warnings are found, or if the database already contains forms that are very
similar to a row you are attempting to import (“duplicates”), you may be
prompted for input on how to proceed.

Note that the topmost row of the CSV preview table contains select menus that
allow you to specify the form attribute that corresponds to the column in
question. In the above example, the values in the first column will be used to
create form transcriptions and those in the second column will be used for
translations.

If a column is labeled using a non-writable form attribute (e.g.,
“enterer”, which only the system can specify), then the import interface
will notify you of this and will warn you, when you validate, that the values
in these columns will not be imported.

You can alter the values in the cells of the table by double-clicking them.

Some form attributes are not simply strings but are resources in their own
right. A form's “source” value and its “tags” value are examples of
this. If Dative cannot identify an existing resource (or existing resources)
that match(es) the string value in your CSV file, it will display a warning and
will help you to create a corresponding resource (or resources), if you want
to. For example, consider the case where the tags value of one of the rows in
your CSV file contains the string “restricted, pied-piping” and the
database contains a tag named “restricted” but not one with the name
“pied-piping”. In this case, a warning will appear (see below), which both
explains that no “pied-piping” tag was found and provides a button to help
you with creating the appropriate tag.

![screenshot of creating a tag during import](/images/help/import-create-tag-500.png)

Each row in your CSV file can be independently validated, previewed and
imported, using the correspondingly named buttons within the row. The
“Validate” button will report back on whether there are any issues that may
affect import. If there are errors, then it will not be possible to import the
row. The “Preview” button will display the row as a form using the standard
form display used throughout Dative. The “Import” button will, if the row
passes validation, send a create request to the server so that a form is
created, based on the information held within the row in question.

The validate, preview, and import actions can also be performed across *all
selected rows*. A row is selected if it is displaying <i class="fa fa-fw
fa-check-square"></i>. It is not selected if it is displaying <i class="fa fa-fw
fa-square"></i>. The “Select All” causes all of the rows to be selected and
the “De-select All” button causes all of the rows to be de-selected. When
you validate or import all of the selected rows, Dative will consolidate all of
the warnings and errors found and will display them above the import preview table.

One thing to be aware of is that clicking “Preview All” on a large CSV file
(i.e., one having more than 100 rows) will cause your browser to work very
slowly. Dative will warn you about this and ask for confirmation before
proceeding with a preview selected request on large files.

Dative will check for duplicates before importing a row. If a possible
duplicate is found, the system will ask for confirmation before proceeding with
the importation of a row that is potentially a duplicate of an existing form.

You may at any time choose another CSV file to base an import on by clicking on
the “Choose file” button again. You can also click the <i class="fa fa-fw
fa-times"></i> button next to the name of the currently loaded file in order to
discard that file, i.e., have Dative close and clean up its representation of
it.



## Files<a data-name="files"></a>

In Dative, a file resource represents a digital file, i.e., an audio or video
recording, an image, or a textual file, such as a PDF.

...



## Texts (a.k.a. Collections)<a data-name="texts"></a>

A text resource reresents a text in the object language. A text may be a story
or narrative or it may be a conversation, or even a record of an elicitation
session. In Dative, a text is simply a sequence of forms and is specified as a
sequence of references to forms.

...



## Corpora<a data-name="corpora"></a>

A corpus is, like a text, also a sequence of forms. A corpus may be specified
manually, i.e., by listing form references in the same way as a text is
specified, or it may be specified by referencing a saved search.

Corpora may be used in the construction of OLD morphologies and language models.

...



## Parsers<a data-name="parsers"></a>

Dative provides an interface to the morphological parser creation tools of OLD
web services. These tools allow users to construct morphological parsers using
finite-state formalisms and N-gram language models. The resources relevant for
parser creation are:

- morphological parsers
- language models
- morphologies
- phonologies

...



## Other Resources<a data-name="other-resources"></a>

When logged in to an OLD web service, Dative provides standard resource-style
interfaces to the following additional resources:

- sources: textual sources (in BibTeX format) for creating citations.

- searches: saved searches over forms, for later re-use and for the
  construction of corpora.

- speakers: the speakers (i.e., consultants) who have produced the utterances
  or made the judgments that are being documented.

- users: modifiable by administrators only, these are the users who can access
  a given OLD web service.

- elicitation methods: resources for describing how a particular form was
  documented, or elicited.

- tags: general-purpose tags for categorizing forms and other resources.

- categories: syntactic (or morphological) categories for classifying forms.
  Categories are used by OLD web services to generate *break-gloss-category* and
  *syntactic category string* values for forms.

- languages: these are the languages of the world, as specified in the
  [ISO 639-3](http://www-01.sil.org/iso639-3/codes.asp) standard. This resource
  is read-only.

- orthographies: sequences of graphs that are used in a given orthographic
  transcription of the object language. Orthographies may be used for automatic
  orthography conversion, though this is not yet implemented.



## Help with the Help<a data-name="help-with-the-help"></a>

This section describes how to use this help document.

There are several ways to open this help document. You may click on the
question mark icon <i class="fa fa-fw fa-question"></i> in the righthand side
of the main menu bar at the top of every page. You may also click on the Help >
Help Page menu button in the lefthand region of the main menu bar.  Finally,
you can use the keyboard shortcut ⌃? (i.e., the control key plus the question
mark key).

To search this help document, enter a search pattern in the search box at
the top. This is case-insensitive substring search. (You may also use regular
expressions.)

If there are matches for your search pattern, they will become highlighted in
the document. Press the Enter/Return key (or the down arrow key) to highlight
and scroll to the next match. Press the up arrow key to highlight and scroll to
the previous match.

This help text is displayed inside of a movable and resizable dialog widget.
You can change its width and/or height by clicking and dragging on its borders
or corners. You can also maximize/minimize it by clicking on the
<i class="fa fa-fw fa-expand"></i> and <i class="fa fa-fw fa-minus"></i>
buttons, respectively.



## Keyboard Shortcuts<a data-name="keyboard-shortcuts"></a>

Dative has keyboard shortcuts for most actions. Some keyboard shortcuts are
global and work throughout the application, no matter which pages or widgets
are being displayed. Other keyboard shortcuts are only in effect when certain
pages or widgets are visible.


### Global Keyboard Shortcuts

Many of the menu buttons in the persistent menu bar at the top of the
application are associated to keyboard shortcuts. These shortcuts are indicated
at the righthand side of the menu button. For example, ⌃H at the righthand
side of the “Home” menu button indicates that the keyboard shortcut for
navigating to the home page is to hold down the control key and press “H”. Note
that the keyboard shortcuts do not require holding down the Shift button; the
capitalization is simply a widely used convention in software interfaces.

The list of global shortcuts is as follows:

- **⌃,** open the application settings page
- **⌃H** open the home page
- **⌃P** open the page that lists the user-created pages (*when logged in only*)
- **⌃C** open the corpora page (for {{FieldDB.FieldDBObject.application.brand}} corpora, *when logged in only*)
- **⌃R** open/close the register dialog
- **⌃A** open the page for adding a new form (*when logged in only*)
- **⌃S** open the page for searching through your data (*when logged in only*)
- **⌃B** open the page for browsing your data (*when logged in only*)
- **⌃?** open/close this help document dialog
- **⌃L** open/close the login dialog

In general, when you move to a new page in Dative, the first actionable
element on the page (e.g., a button or a text input) will be focused. By
pressing Tab or Shift+Tab you can move to the next or previous actionable
element, respectively.


### Interface-specific Keyboard Shortcuts

Certain interfaces (or pages) in Dative have their own keyboard shortcuts.
These shortcuts are only in effect when the relevant interface is open and
focused.

#### Resource Browsing Shortcuts

In all of the resource browse pages, the following keyboard shortcuts are in
effect:

- **↓** expand all forms (i.e., so that the buttons and metadata of each for are
  visible)
- **↑** collapse all forms
- **n** open the next page of forms
- **p** open the previous page of forms
- **l** open the last page of forms
- **f** open the first page of forms

When a particular resource is focused, the following shortcuts are activated for
that particular resource:

- **enter/return** expand the resource
- **escape** collapse the resource
- **space** focus the next resource
- **shift+space** focus the previous resource



## Frequently Asked Questions<a data-name="frequently-asked-questions"></a>

1. What is a “form”?

    - A form is a linguistic form. It is a general term meant to encompass
      all of the textual data points that you might enter into a linguistic
      fieldwork/ language documentation database. In practice, it may be a
      morpheme, word, phrase, sentence, or even a multi-sentential unit. In
      {{FieldDB.FieldDBObject.application.brand}} applications, the term
      “datum” is sometimes used. These two terms may be considered
      equivalent here.

2. How can I request new features or report bugs?

    - At present, the best way to do this is by creating an issue on
      [Dative's GitHub issues page](https://github.com/jrwdunham/dative/issues).

3. Can I import my existing data into an OLD or
   {{FieldDB.FieldDBObject.application.brand}} web service using Dative?

    - At present, no. We are working on import functionality. Stay tuned.

4. Can I make global changes (i.e., bulk edit) to a subset of forms?

    - At present, no. We are working on bulk edit functionality. Stay tuned.

5. The way I organize my data is different from the way Dative / the OLD /
   {{FieldDB.FieldDBObject.application.brand}} does. Yet I want to use Dative.
   How can I?

    - {{FieldDB.FieldDBObject.application.brand}} allows for a user-defined
      data structure. The OLD will soon also allow users to modify its data
      structure. Dative will also soon provide an interface for modifying these
      data structures. Stay tuned.

6. Are there any video tutorials on how to use Dative?

    - Not yet. They're a comin'.

