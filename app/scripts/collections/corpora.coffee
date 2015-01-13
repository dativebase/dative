define [
    'backbone',
    './../models/corpus'
  ], (Backbone, CorpusModel) ->

  # Corpora Collection
  # ------------------
  #
  # Holds models for FieldDB corpora.

  class CorporaCollection extends Backbone.Collection

    model: CorpusModel

    # Create a new corpus.
    # POST `<AuthServiceURL>/newcorpus`
    newCorpus: (newCorpusName) ->
      Backbone.trigger 'newCorpusStart', newCorpusName
      payload =
        authUrl: @applicationSettings.get?('activeServer')?.get?('url')
        username: @applicationSettings.get?('username')
        password: @applicationSettings.get?('password')
        serverCode: @applicationSettings.get?('activeServer')?.get?('serverCode')
        newCorpusName: newCorpusName
      CorpusModel.cors.request(
        method: 'POST'
        timeout: 10000
        url: "#{payload.authUrl}/newcorpus"
        payload: payload
        onload: (responseJSON) =>
          Backbone.trigger 'newCorpusEnd'
          if responseJSON.corpusadded
            if responseJSON.corpus
              corpusObject = responseJSON.corpus
              corpusObject.applicationSettings = @applicationSettings
              @unshift corpusObject
              Backbone.trigger 'newCorpusSuccess', newCorpusName
            else
              Backbone.trigger 'newCorpusFail',
                ["There was an error creating corpus “#{newCorpusName}”.",
                 "This name is probably already taken.",
                 "Try a different one."].join ' '
              console.log responseJSON.userFriendlyErrors[0]
          else
            Backbone.trigger 'newCorpusFail', "Request to create corpus failed: `corpusadded` not truthy."
            console.log 'Failed request to /newcorpus: `corpusadded` not truthy.'
        onerror: (responseJSON) =>
          Backbone.trigger 'newCorpusEnd'
          Backbone.trigger 'newCorpusFail', "Request to create corpus failed with an error."
          console.log 'Failed request to /newcorpus: error.'
        ontimeout: =>
          Backbone.trigger 'newCorpusEnd'
          Backbone.trigger 'newCorpusFail', "Request to create corpus failed: request timed out."
          console.log 'Failed request to /newcorpus: timed out.'
      )

###
#
POST https://auth.lingsync.org/newcorpus

authUrl: "https://auth.lingsync.org"
newCorpusName: "Okanagan"
password: "..."
serverCode: "production"
username: "jrwdunham"

{
  "corpusadded": true,
  "info": [
    "Corpus Okanagan created successfully."
  ],
  "corpus": {
    "title": "Okanagan",
    "titleAsUrl": "okanagan",
    "description": "This is probably your first Corpus, you can use it to play with the app... When you want to make a real corpus, click New : Corpus",
    "team": {
      "gravatar": "",
      "username": "",
      "subtitle": "",
      "description": ""
    },
    "couchConnection": {
      "protocol": "https://",
      "domain": "corpus.lingsync.org",
      "port": "443",
      "pouchname": "jrwdunham-okanagan",
      "path": "",
      "authUrl": "https://auth.lingsync.org",
      "userFriendlyServerName": "LingSync.org"
    },
    "replicatedCouchConnections": [],
    "OLAC_export_connections": [],
    "termsOfUse": {
      "humanReadable": "Sample: The materials included in this corpus are available for research and educational use. If you want to use the materials for commercial purposes, please notify the author(s) of the corpus (myemail@myemail.org) prior to the use of the materials. Users of this corpus can copy and redistribute the materials included in this corpus, under the condition that the materials copied/redistributed are properly attributed.  Modification of the data in any copied/redistributed work is not allowed unless the data source is properly cited and the details of the modification is clearly mentioned in the work. Some of the items included in this corpus may be subject to further access conditions specified by the owners of the data and/or the authors of the corpus."
    },
    "license": {
      "title": "Default: Creative Commons Attribution-ShareAlike (CC BY-SA).",
      "humanReadable": "This license lets others remix, tweak, and build upon your work even for commercial purposes, as long as they credit you and license their new creations under the identical terms. This license is often compared to “copyleft” free and open source software licenses. All new works based on yours will carry the same license, so any derivatives will also allow commercial use. This is the license used by Wikipedia, and is recommended for materials that would benefit from incorporating content from Wikipedia and similarly licensed projects.",
      "link": "http://creativecommons.org/licenses/by-sa/3.0/"
    },
    "copyright": "Default: Add names of the copyright holders of the corpus.",
    "pouchname": "jrwdunham-okanagan",
    "dateOfLastDatumModifiedToCheckForOldSession": "2015-01-06T01:05:31.163Z",
    "confidential": {
      "secretkey": "21edc186-e0ed-4e30-b458-96ea47889117"
    },
    "publicCorpus": "Private",
    "collection": "private_corpuses",
    "comments": [],
    "datumFields": [
      {
        "label": "judgement",
        "value": "",
        "mask": "",
        "encrypted": "",
        "shouldBeEncrypted": "",
        "help": "Grammaticality/acceptability judgement (*,#,?, etc). Leaving it blank can mean grammatical/acceptable, or you can choose a new symbol for this meaning.",
        "size": "3",
        "showToUserTypes": "linguist",
        "userchooseable": "disabled"
      },
      {
        "label": "utterance",
        "value": "",
        "mask": "",
        "encrypted": "",
        "shouldBeEncrypted": "checked",
        "help": "Unparsed utterance in the language, in orthography or transcription. Line 1 in your LaTeXed examples for handouts. Sample entry: amigas",
        "showToUserTypes": "all",
        "userchooseable": "disabled"
      },
      {
        "label": "morphemes",
        "value": "",
        "mask": "",
        "encrypted": "",
        "shouldBeEncrypted": "checked",
        "help": "Morpheme-segmented utterance in the language. Used by the system to help generate glosses (below). Can optionally appear below (or instead of) the first line in your LaTeXed examples. Sample entry: amig-a-s",
        "showToUserTypes": "linguist",
        "userchooseable": "disabled"
      },
      {
        "label": "gloss",
        "value": "",
        "mask": "",
        "encrypted": "",
        "shouldBeEncrypted": "checked",
        "help": "Metalanguage glosses of each individual morpheme (above). Used by the system to help gloss, in combination with morphemes (above). It is Line 2 in your LaTeXed examples. We recommend Leipzig conventions (. for fusional morphemes, - for morpheme boundaries etc)  Sample entry: friend-fem-pl",
        "showToUserTypes": "linguist",
        "userchooseable": "disabled"
      },
      {
        "label": "syntacticCategory",
        "value": "",
        "mask": "",
        "encrypted": "",
        "shouldBeEncrypted": "checked",
        "help": "This optional field is used by the machine to help with search and data cleaning, in combination with morphemes and gloss (above). If you want to use it, you can choose to use any sort of syntactic category tagging you wish. It could be very theoretical like Distributed Morphology (Sample entry: √-GEN-NUM), or very a-theroretical like the Penn Tree Bank Tag Set. (Sample entry: NNS) http://www.ims.uni-stuttgart.de/projekte/CorpusWorkbench/CQP-HTMLDemo/PennTreebankTS.html",
        "showToUserTypes": "linguist",
        "userchooseable": "disabled"
      },
      {
        "label": "syntacticTreeLatex",
        "value": "",
        "mask": "",
        "encrypted": "",
        "shouldBeEncrypted": "checked",
        "help": "This optional field is used by the machine to make LaTeX trees and help with search and data cleaning, in combination with morphemes and gloss (above). If you want to use it, you can choose to use any sort of LaTeX Tree package (we use QTree by default) Sample entry: Tree [.S NP VP ]",
        "showToUserTypes": "linguist",
        "userchooseable": "disabled"
      },
      {
        "label": "translation",
        "value": "",
        "mask": "",
        "encrypted": "",
        "shouldBeEncrypted": "checked",
        "help": "Free translation into whichever language your team is comfortable with (e.g. English, Spanish, etc). You can also add additional custom fields for one or more additional translation languages and choose which of those you want to export with the data each time. Line 3 in your LaTeXed examples. Sample entry: (female) friends",
        "showToUserTypes": "all",
        "userchooseable": "disabled"
      },
      {
        "label": "tags",
        "value": "",
        "mask": "",
        "encrypted": "",
        "shouldBeEncrypted": "",
        "help": "Tags for constructions or other info that you might want to use to categorize your data.",
        "showToUserTypes": "all",
        "userchooseable": "disabled"
      },
      {
        "label": "validationStatus",
        "value": "",
        "mask": "",
        "encrypted": "",
        "shouldBeEncrypted": "",
        "help": "Any number of tags of data validity (replaces DatumStates). For example: ToBeCheckedWithSeberina, CheckedWithRicardo, Deleted etc...",
        "showToUserTypes": "all",
        "userchooseable": "disabled"
      },
      {
        "label": "enteredByUser",
        "value": "",
        "mask": "",
        "encrypted": "",
        "shouldBeEncrypted": "",
        "help": "The user who originally entered the datum",
        "readonly": true,
        "showToUserTypes": "readonly",
        "userchooseable": "disabled"
      },
      {
        "label": "modifiedByUser",
        "value": "",
        "mask": "",
        "encrypted": "",
        "shouldBeEncrypted": "",
        "help": "An array of users who modified the datum",
        "readonly": true,
        "users": [],
        "showToUserTypes": "readonly",
        "userchooseable": "disabled"
      }
    ],
    "conversationFields": [
      {
        "label": "participants",
        "value": "",
        "mask": "",
        "encrypted": "",
        "shouldBeEncrypted": "checked",
        "help": "Use this field to keep track of who your speaker/participants are. You can use names, initials, or whatever your consultants prefer.",
        "userchooseable": "disabled"
      },
      {
        "label": "modality",
        "value": "",
        "mask": "",
        "encrypted": "",
        "shouldBeEncrypted": "",
        "help": "Use this field to indicate if this is a voice or gesture tier, or a tier for another modality.",
        "userchooseable": "disabled"
      }
    ],
    "sessionFields": [
      {
        "label": "goal",
        "value": "",
        "mask": "",
        "encrypted": "",
        "shouldBeEncrypted": "",
        "help": "The goals of the elicitation session, it could be why you set up the meeting, or some of the core contexts you were trying to elicit. Sample: collect some anti-passives",
        "userchooseable": "disabled"
      },
      {
        "label": "consultants",
        "value": "",
        "mask": "",
        "encrypted": "",
        "userMasks": [],
        "shouldBeEncrypted": "",
        "help": "This is a comma seperated field of all the consultants who were present for this elicitation session. This field also contains a (hidden) array of consultant masks with more details about the consultants if they are not anonymous or are actual users of the system. ",
        "userchooseable": "disabled"
      },
      {
        "label": "dialect",
        "value": "",
        "mask": "",
        "encrypted": "",
        "shouldBeEncrypted": "",
        "help": "The dialect of this session (as precise as you'd like).",
        "userchooseable": "disabled"
      },
      {
        "label": "language",
        "value": "",
        "mask": "",
        "encrypted": "",
        "shouldBeEncrypted": "",
        "help": "The language (or language family), if desired.",
        "userchooseable": "disabled"
      },
      {
        "label": "dateElicited",
        "value": "",
        "mask": "",
        "encrypted": "",
        "shouldBeEncrypted": "",
        "help": "The date when the session took place.",
        "userchooseable": "disabled"
      },
      {
        "label": "user",
        "value": "",
        "mask": "",
        "encrypted": "",
        "shouldBeEncrypted": "",
        "help": "This is the username of who created this elicitation session. There are other fields contains an array of participants and consultants. ",
        "userchooseable": "disabled"
      },
      {
        "label": "participants",
        "value": "",
        "mask": "",
        "encrypted": "",
        "userMasks": [],
        "shouldBeEncrypted": "",
        "help": "This is a comma seperated field of all the people who were present for this elicitation session. This field also contains a (hidden) array of user masks with more details about the people present, if they are not anonymous or are actual users of the system. ",
        "userchooseable": "disabled"
      },
      {
        "label": "dateSEntered",
        "value": "",
        "mask": "",
        "encrypted": "",
        "shouldBeEncrypted": "",
        "help": "This field is deprecated, it was replaced by DateSessionEntered",
        "userchooseable": "disabled"
      },
      {
        "label": "DateSessionEntered",
        "value": "",
        "mask": "",
        "encrypted": "",
        "shouldBeEncrypted": "",
        "help": "This is the date in which the session was entered.",
        "userchooseable": "disabled"
      }
    ],
    "timestamp": 1420506331164
  }
}

###
#
