tmp = ($) ->
  # IGT - Interlinear Gloss Text -- this wrapped set method correctly aligns
  #  words in interlinear gloss text format into columns.  Each element of
  #  the set is expected to contain two or more elements and the text of
  #  each of these sub-elements is considered to be the line.  In the
  #  following example, 'les chiens', 'le-s chien-s' and 'DET-PL dog-PL' are
  #  the lines:
  #
  #    <div class="align-me">
  #      <div>les chiens</div>
  #      <div>le-s chien-s</div>
  #      <div>DET-PL dog-PL</div>
  #    </div>
  #
  #  Basic usage:
  #
  #    $('div.align-me').igt()
  #
  #  Usage with options:
  #
  #    $('div.align-me').igt({buffer: 20, lineGroupBuffer: 5, indent: 60,
  #                          minLineWidthAsPerc: 75})

  $.fn.igt = (options={}) ->

    # Align words in each element of the wrapped set
    $(this).each(->

      container = $ this

      # Each child is a line whose words may need alignment
      children = $(this).children()

      # spanWidths holds the width of each span in each line; it will
      #  look something like [[49, 32, 40], [66, 49, 40], [61, 99, 25]]
      spanWidths = []

      # colWidths holds the width of each column, i.e., the width of the
      #  longest <span>-wrapped word with index x, e.g., [66, 99, 40]
      colWidths = []

      # lineHeights holds height of each line
      lineHeights = []

      ##########################################################################
      # OPTIONS
      ##########################################################################

      # Number of pixels to put between each span
      buffer = options.buffer or 30

      # Number of pixels to put between groups of lines ("lineGroups")
      lineGroupBuffer = options.lineGroupBuffer or 10

      # Number of pixels to indent each subsequent line
      indent = options.indent or 40

      # Minimum width of a line as a percentage of the container's width
      minLineWidthAsPerc = options.minLineWidthAsPerc or 50

      # Line Group Class: class to give to line groups
      lineGroupClass = options.lineGroupClass or 'old-form-igt-line-group'

      ##########################################################################
      # FUNCTIONS
      ##########################################################################

      # Spanify -- input: line of text; output: line with each word enclosed in
      # a span tag.
      spanify = (elementText) ->
        words = elementText.replace(/\s\s+/g, ' ').split(' ')
        words = ("<span style=\"white-space: nowrap;\">#{word}</span>" \
          for word in words)
        words.join ''

      # Get Greatest Width -- return the greatest width among the words in the
      # same 'column'.
      getGreatestWidth = (widths, index, spanIndex) ->
        if colWidths[spanIndex]
          colWidths[spanIndex] # We know max width of this column from previous iterations
        else
          # E.g., from [[49, 32, 40], [66, 49], [61, 99, 25]],
          #  return [40, 25] (assuming spanIndex = 2)
          x = (widthSet) ->
            if widthSet.length is widths[index].length
              widthSet[spanIndex]
            else
              0
          widths = (x(w) for w in widths)
          result = Math.max.apply Math, widths # Get the widest
          colWidths[spanIndex] = result  # Remember for later
          result

      # Set Width -- set the width of the span to the width of the widest
      #  span in the same column PLUS the buffer.
      setWidth = (index, spanIndex, span) ->
        greatestWidth = getGreatestWidth spanWidths, index, spanIndex
        $(span).css
          display: 'inline-block'
          width: greatestWidth + buffer

      # Sum -- sum all integers in an array (c'mon Javascript!)
      sum = (array) ->
        result = 0
        for element in array
          result += element
        result

      # Get New Max Width: get the max width of a "line group" based on
      #  the current max width, indent and minLineWidthAsPerc
      getNewMaxWidth = (currentMaxWidth, minLineWidth) ->
        if (currentMaxWidth - indent) > minLineWidth
          currentMaxWidth - indent
        else
          currentMaxWidth

      ##########################################################################
      # ALIGN THE WORDS IN THE LINES ALREADY
      ##########################################################################

      # Enclose each word of each child in span tags, record the width
      #  of each such span tag and the height of each line
      children.each (index, child) ->
        # wrap words in spans
        $(child).html spanify($(child).text())

        # record the width of each span
        widths = []
        $('span', child).each (index, span) ->
          widths.push $(span).width()
        spanWidths.push widths

        # Record the height of each line
        lineHeights.push $($('span', child)[0]).height()

      # isColumnable returns true if the last line has more than two
      #  words and all lines from this one on down have the same word
      #  count
      isColumnable = (index, line) ->
        if spanWidths[spanWidths.length - 1].length < 2
          false
        for spanWidth in spanWidths
          if spanWidth.length isnt spanWidths[index].length
            false
        true

      # linesToColumnify is an array of indices representing the lines
      #  whose span-wrapped words need to be aligned.  Such lines have
      #  a word count that is greater than one and equal to that of all
      #  subsequent lines.
      linesToColumnify = []
      for line, index in spanWidths
        if isColumnable(index, line)
          linesToColumnify.push index

      # Set the width of each span tag to the width of the longest span
      #  tag in the same 'column' plus the buffer
      children.each (index, child) ->
        # Only alter the width of spans inside of columnable lines
        if index in linesToColumnify
          $('span', child).each (spanIndex, span) ->
            setWidth index, spanIndex, span

      # If the container's height is not equal to the sum of the line
      #  heights, we have lines wrapping and need to fix that by breaking
      #  the lines into multiple lines.
      containerHeight = $(this).height()
      if containerHeight isnt sum(lineHeights)
        containerWidth = $(this).width()
        minLineWidth = Math.round(minLineWidthAsPerc / 100 * containerWidth)

        # Create the lineGroups list of objects; this tells us the max
        #  width of each line and, indirectly via the spanWidths object,
        #  the slice of <span>-wrapped words we want in each line.
        lineGroups = [
          maxWidth: containerWidth
          indent: 0
          spanWidths: []
        ]
        for width, index in colWidths
          lineGroup = lineGroups[lineGroups.length - 1]
          if (sum(lineGroup.spanWidths) + width + buffer) < lineGroup.maxWidth
            lineGroup.spanWidths.push(width + buffer)
          else
            lineGroups.push
              maxWidth: getNewMaxWidth(lineGroup.maxWidth, minLineWidth)
              spanWidths: [width + buffer]

        # Create a new container that has the lines broken up,
        #  grouped and indented appropriately.
        newContainer = $ '<div>'
        begin = 0
        previousIndent = 0
        for lineGroup, index in lineGroups
          topMarg = if index is 0 then 'auto' else lineGroupBuffer
          if (lineGroup.maxWidth - (index * indent)) < minLineWidth
            currentIndent = previousIndent
          else
            currentIndent = (index * indent)
          previousIndent = currentIndent
          lineGroupDiv = $('<div>')
            .addClass lineGroupClass
            .css
              'margin-left': currentIndent
              'margin-top': topMarg
          end = begin + lineGroup.spanWidths.length
          container.children().clone().each(
            (index, line) ->
              lineGroupDiv.append(
                $(line)
                  .html $(line).children().slice(begin, end)
              )
          )
          newContainer.append lineGroupDiv
          begin = end

        # Replace the container's children with those of the new container
        container.html newContainer.children()
    )

tmp jQuery

