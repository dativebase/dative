# Dative Help

Dative is an application for linguistic fieldwork. It helps groups of
fieldworkers to collaboratively build corpora of language data.

This document contains information to help you in using Dative. This
help document is fully searchable using the search field above. For
additional help with using this help document see the [Help with the
Help](#help-with-the-help) section.


## Table of Contents<a name="toc"></a>

- [QuickStart](#quickstart)
- [FAQ](#frequently-asked-questions)
- [About Dative](#about-dative)
- [Help with the Help](#help-with-the-help)
- [Application Settings](#application-settings)
- [Browsing Forms](#browsing-forms)
- [Adding a Form](#adding-a-form)
- [Keyboard Shortcuts](#keyboard-shortcuts)


## QuickStart<a data-name="quickstart"></a>

Using Dative is all about entering linguistic fieldwork data, refining it,
browsing it, searching through it, and using it to write papers, develop
learning materials, or generate documentary or archive-quality artifacts.

Dative can work with both [{{FieldDB.FieldDBObject.application.brand}}]({{FieldDB.FieldDBObject.application.website}}) and
[OLD](http://www.onlinelinguisticdatabase.org/)-type web servers. This means
that if you have an account with {{FieldDB.FieldDBObject.application.brand}} or an OLD application, you can use
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
“Register” button and an account should be generated for you.

Once you have successfully logged in, you will be brought either to the
corpora interface (if you have logged into a {{FieldDB.FieldDBObject.application.brand}} server) or to the
browse forms interface (if you have logged into an OLD server). At the
corpus interface, you must choose the {{FieldDB.FieldDBObject.application.brand}} corpus that you
wish to use; you do this by clicking on the “activate corpus” button
<i class="fa fa-fw fa-toggle-off"></i>. This will take you to the browse
forms interface where you can view the data in the corpus, modify it,
and add to it.

WARNING: THE DATA MODIFICATION/ADDITION FEATURE IS CURRENTLY NOT YET
IMPLEMENTED IN DATIVE.


## Frequently Asked Questions<a data-name="frequently-asked-questions"></a>

1. What is a “form”?
    - A form is a linguistic form. It is a general term meant to encompass
      all of the data points that you might enter into a linguistic fieldwork/
      language documentation database. In practice, may be a morpheme, word,
      phrase, sentence, or even a multi-sentential unit. In {{FieldDB.FieldDBObject.application.brand}}
      applications, the term “datum” is sometimes used. These two terms may
      be considered equivalent here.

## About Dative<a data-name="about-dative"></a>

Dative is an application for linguistic fieldwork. It is a graphical user
interface that runs in modern web browsers. The data that you enter into
Dative are saved to the web server that you are logged into at the time.
This may be a [{{FieldDB.FieldDBObject.application.brand}}]({{FieldDB.FieldDBObject.application.website}}) server or an
[OLD](http://www.onlinelinguisticdatabase.org/) one. {{FieldDB.FieldDBObject.application.brand}} and the OLD
are web services that allow linguistic data to be stored and manipulated
on web servers by multiple users at the same time.

Dative is written in CoffeeScript (and HTML and CSS) using the Backbone
framework. It is open source and its source code can be found on
[GitHub](https://github.com/jrwdunham/dative).


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
or corners. You can also expand/compress it to its default large and small
sizes by clicking on the expand/compress button <i class="fa fa-fw
fa-expand"></i><i class="fa fa-fw fa-compress"></i> at the bottom.


## Application Settings<a data-name="application-settings"></a>

At this stage of development, Dative’s application settings allow you to
do two things:

1. Configure servers (e.g., {{FieldDB.FieldDBObject.application.brand}} or OLD servers)
2. Change the appearance (i.e., theme) of the application

A “server” in this context is a {{FieldDB.FieldDBObject.application.brand}} or OLD web service that receives,
stores, and returns linguistic data. A server is defined by a name, a URL,
a type (“{{FieldDB.FieldDBObject.application.brand}}” or “OLD”), and potentially a server code.

To change the active server, simply select one of the existing servers from
the *Active Server* select menu.

To create a new server, click on the “show servers” button (with the
right-facing caret symbol: <i class="fa fa-fw fa-caret-right"></i>) to reveal
the existing servers. Then click on the “create a new server” plus-sign (<i
class="fa fa-fw fa-plus"></i>) button to reveal the interface for creating a
new server.

In the new server form, first enter a name for your server. This can be whatever
you like, whatever will be memorable to you. Then enter the server's URL, its
type, and (if it’s a FieldDB-type server) its server code. The appropriate
server code value that you will want to choose is probably “production.” If you
do not know which values to enter to create a new server, please contact your
{{FieldDB.FieldDBObject.application.brand}} or OLD server administrator.

Note that you do not need to click “Save” here. Dative saves all of your
application settings changes automatically to your browser's local storage.



## Browsing Forms<a data-name="browsing-forms"></a>

When you click on the Forms > Browse menu button, enter the keyboard shortcut
⌃B, or click on a {{FieldDB.FieldDBObject.application.brand}} “activate corpus” button (<i class="fa fa-fw
fa-toggle-off"></i>), you will be brought to the forms browsing interface.
This interface displays all of your forms (i.e., data points) in a paginated
display; that is the forms are split across a number of pages. You may change
the number of forms displayed per page and can navigate to particular pages
using the controls provided.

Each form may be expanded to reveal controls related to it as well as more
information about it. Click on a form to expand it. You can expand all forms
on the page by clicking the “expand all” <i class="fa fa-fw
fa-angle-double-down"></i> button or collapse all forms by clicking on the
“collapse all” <i class="fa fa-fw fa-angle-double-up"></i> button.



## Adding a Form<a data-name="adding-a-form"></a>

To create a new form, click on the “create a new form” button <i class="fa
fa-fw fa-plus"></i> from within the “browse forms” interface (or enter the
keyboard shortcut ⌃A). This will cause the “Add a Form” widget to be displayed
at the top of the browse forms page. Enter the data for the form (usually
at minimum a transcription and a translation) and click on the “Add a Form”
button at the bottom.

Dative divides the “Add a Form” form into two parts: the primary fields and
the secondary ones. By default only the primary fields are displayed. You
may reveal the secondary fields by clicking on the “show secondary fields”
button <i class="fa fa-fw fa-angle-down"></i> near the top right of the “Add
a Form” widget.


### Modifying the Form Fields

WARN: THIS IS NOT IMPLEMENTED YET.

Dative allows users to control which fields are present on a form. When using
a {{FieldDB.FieldDBObject.application.brand}} server, the user may define any number of text-based fields,
i.e., fields whose values are strings of characters.



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
navigating to the home page is to hold down the control key and press “H”.

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


### Page-specific Keyboard Shortcuts

Certain interfaces (or pages) in Dative have their own keyboard shortcuts.
These shortcuts are only in effect when the relevant page is open.

#### Forms Browsing Shortcuts

In the forms browse page, the following keyboard shortcuts are in effect:

- **↓** expand all forms (i.e., so that the buttons and metadata of each for are
  visible)
- **↑** collapse all forms
- **n** open the next page of forms
- **p** open the previous page of forms
- **l** open the last page of forms
- **f** open the first page of forms

When a particular form is focused, the following shortcuts are activated for
that particular form:

- **enter/return** expand the form
- **escape** collapse the form
- **tab** focus the next form
- **shift+tab** focus the previous form

