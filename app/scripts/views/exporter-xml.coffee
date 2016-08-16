define [
  './exporter'
], (ExporterView) ->

  # Exporter that exports individual forms or collections of forms in XML.
  # TODO: there should probable by an XML export features built right into the
  # OLD itself.
  # the

  class ExporterXMLView extends ExporterView

    title: -> 'XML'

    description: ->
      if @model
        "XML export of #{@model.resourceName}
          #{@model.id}"
      else if @collection
        if @collection.corpus
          "XML export of the forms in
            #{@collection.corpus.get 'name'}."
        else if @collection.search
          if @collection.search.name
            "XML export of the
              #{@collection.resourceNamePlural} in search
              #{@collection.search.name}."
          else
            "XML export of the
              #{@collection.resourceNamePlural} that match the search currently
              being browsed."
        else
          "XML export of all
            #{@collection.resourceNamePlural} in the database."
      else
        'XML export of a collection of resources'

    # We export all types of forms: individuals, form search results, the
    # contents of collections, etc.
    exportTypes: -> ['*']

    # We export everything in XML format.
    exportResources: -> ['*']

    updateControls: ->
      @clearControls()
      if @model then @selectAllButton()

    dativeXMLVersion: '0.1.0'

    openTag: ->
      "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n
        <dative xmlns=\"http://www.dative.ca/\" xmlns:dt=\"http://www.dative.ca/\"
         dt:version=\"#{@dativeXMLVersion}\">"

    closeTag: -> '</dative>'

    resourceName2XMLName: (resourceName, pluralize=false) ->
      result = @utils.camel2snake resourceName
      if result is 'subcorpus' then result = 'corpus'
      if pluralize then result = @utils.pluralize result
      result

    export: ->
      @$(@contentContainerSelector()).slideDown()
      $contentContainer = @$ @contentSelector()
      if @model
        snake = @resourceName2XMLName @model.resourceName
        tmp2 = {}
        tmp2[snake] = @model
        tmp = {}
        tmp[@utils.pluralize snake] = tmp2
        xmlString = [@openTag()
                     @getAsXML tmp
                     @closeTag()].join '\n'
        @displayAsLink xmlString, $contentContainer
      else
        if @collection
          if @collection.corpus
            msg = "fetching a corpus of #{@collection.resourceNamePlural} ..."
          else if @collection.search
            msg = "fetching a search over #{@collection.resourceNamePlural} ..."
          else
            msg = "fetching all #{@collection.resourceNamePlural} ..."
          @fetchResourceCollection true
          content = "<i class='fa fa-fw fa-circle-o-notch fa-spin'></i>#{msg}"
        else
          content = 'Sorry, unable to generate an export.'
        $contentContainer.html content

    # We have retrieved an array of form objects in (`collectionArray`). If it
    # contains more than 100 results we create a link to a file containing the
    # export. Otherwise, we put the export content in the exporter interface
    # along with a "Select All" button.
    fetchResourceCollectionSuccess: (collectionArray) ->
      super
      $contentContainer = @$ @contentSelector()
      if collectionArray.length is 0
        msg = "Sorry, there are no #{@collection.resourceNamePlural} to export"
        $contentContainer.html msg
        return
      xmlString = @getCollectionAsXMLString(
        collectionArray, @collection.resourceName)
      @displayAsLink xmlString, $contentContainer

    displayAsLink: (xmlString, $contentContainer) ->
      mimeType = 'text/xml; charset=utf-8;'
      blob = new Blob [xmlString], {type : mimeType}
      url = URL.createObjectURL blob
      if @model
        name = "#{@resourceName2XMLName @model.resourceName}-\
          #{(new Date()).toISOString()}.xml"
      else
        nameSing = @resourceName2XMLName @collection.resourceName
        namePlrl = @resourceName2XMLName @collection.resourceName, true
        if @collection.corpus
          name = "corpus-of-#{namePlrl}-\
            #{(new Date()).toISOString()}.xml"
        else if @collection.search
          name = "search-over-#{namePlrl}-\
            #{(new Date()).toISOString()}.xml"
        else
          name = "#{namePlrl}-#{(new Date()).toISOString()}.xml"
      anchor = "<a href='#{url}'
        class='export-link dative-tooltip'
        type='#{mimeType}'
        title='Click to download your export file'
        download='#{name}'
        target='_blank'
        ><i class='fa fa-fw fa-file-o'></i>#{name}</a>"
      $contentContainer.html anchor
      @$('.export-link.dative-tooltip').tooltip()

    # Return a string representing the export of the `collectionArray` in XML
    # format.
    # TODO: escape XML special characters. See http://www.w3schools.com/xml/xml_syntax.asp
    getCollectionAsXMLString: (collectionArray, resourceName) ->
      @errors = false
      [xml, xmlSuf, indlvl, subindlvl] = @getCollectionXMLAffixes()
      for modelObject in collectionArray
        name = @resourceName2XMLName resourceName
        xml = xml.concat(["#{@getSpacer subindlvl}<#{name}>"
                          @getAsXML(modelObject, subindlvl + 1)
                          "#{@getSpacer subindlvl}</#{name}>"])
      xml = xml.concat xmlSuf
      if @errors then Backbone.trigger 'xmlExportError'
      xml.join '\n'

    # Return the JSON search of the OLD search as an array representing an XML
    # element.
    getSearchEl: (search, indlvl) ->
      ["#{@getSpacer indlvl + 1}<search>"
       "#{@getSpacer indlvl + 2}<filter>\
         #{_.escape JSON.stringify(search.filter)}</filter>"
       "#{@getSpacer indlvl + 2}<order_by>\
         #{_.escape JSON.stringify(search.order_by)}</order_by>"
       "#{@getSpacer indlvl + 1}</search>"]

    # Return the arrays representing the XML that goes at the beginning and end
    # of the collection.
    getCollectionXMLAffixes: ->
      indlvl = 1
      subindlvl = 2
      name = @resourceName2XMLName @collection.resourceName, true
      if @collection.corpus or @collection.search
        subindlvl = 3
        if @collection.corpus
          root = 'corpus_with_forms'
          metaEl = [@getAsXML({corpus: @collection.corpus}, indlvl + 1)]
        else
          root = 'search_with_forms'
          metaEl = @getSearchEl @collection.search, indlvl
        xml = [@openTag(), "#{@getSpacer indlvl}<#{root}>"].concat(
                metaEl,
                ["#{@getSpacer indlvl + 1}<#{name}>"])
        xmlSuf = [
          "#{@getSpacer indlvl + 1}</#{name}>"
          "#{@getSpacer indlvl}</#{root}>"
          @closeTag()]
      else
        xml = [@openTag(), "#{@getSpacer indlvl}<#{name}>"]
        xmlSuf = ["#{@getSpacer indlvl}</#{name}>", @closeTag()]
      [xml, xmlSuf, indlvl, subindlvl]

    # How many spaces of indentation on each successive line.
    ind: 2

    getSpacer: (indlvl) ->
      (' ' for x in [0...(indlvl * @ind)]).join ''

    initialize: (options) ->
      super options
      # @xmlParent = null

    # Return ``thing`` as XML.
    getAsXML: (thing, indlvl=1) ->
      xml = []
      spacer = @getSpacer indlvl
      if thing instanceof Backbone.Model then thing = thing.attributes
      for attr, val of thing
        if attr is 'search' and 'filter' of val
          xml = xml.concat(@getSearchEl(val, indlvl - 1))
          continue
        # @xmlParent = attr
        if attr in ['morpheme_break_ids', 'morpheme_gloss_ids']
          if val and val.length > 0
            xml.push("#{spacer}<#{attr}>\
              #{_.escape JSON.stringify(val)}</#{attr}>")
          else
            xml.push "#{spacer}<#{attr}></#{attr}>"
        else if @utils.type(val) is 'array'
          if val.length is 0
            xml.push "#{spacer}<#{attr}></#{attr}>"
          else
            attrSing = @utils.singularize attr
            nextSpacer = @getSpacer indlvl + 1
            xml.push "#{spacer}<#{attr}>"
            for subthing in val
              xml = xml.concat([
                "#{nextSpacer}<#{attrSing}>"
                @getAsXML(subthing, indlvl + 2),
                "#{nextSpacer}</#{attrSing}>"])
            xml.push "#{spacer}</#{attr}>"
        else if @utils.type(val) is 'object'
          xml = xml.concat([
            "#{spacer}<#{attr}>",
            @getAsXML(val, indlvl + 1),
            "#{spacer}</#{attr}>"])
        else
          if val is null
            val = ''
          xml.push "#{spacer}<#{attr}>#{_.escape val}</#{attr}>"
      xml.join '\n'
