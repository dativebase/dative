'use strict';
/* IGT - Interlinear Gloss Text -- jQuery extension, AMD-compatible
 *
 *  Align words in interlinear gloss text format into columns.  Each element of
 *  the jQuery wrapped set is expected to contain two or more elements and the
 *  text of each of these sub-elements is considered to be the line.  In the
 *  following example, 'les chiens', 'le-s chien-s' and 'DET-PL dog-PL' are
 *  the lines:
 *
 *    <div class="align-me">
 *      <div>les chiens</div>
 *      <div>le-s chien-s</div>
 *      <div>DET-PL dog-PL</div>
 *    </div>
 *
 *  Basic usage:
 *
 *    $('div.align-me').igt();
 *
 *  Usage with options:
 *
 *    $('div.align-me').igt({buffer: 20, lineGroupBuffer: 5, indent: 60,
 *                          minLineWidthAsPerc: 75});
 */

define(['jquery'], function($) {

    $.fn.igt = function (options) {

        // Align words in each element of the wrapped set
        $(this).each(function () {

            var container = $(this);

            // Each child is a line whose words may need alignment
            var children = $(this).children();

            // spanWidths holds the width of each span in each line; it will
            //  look something like [[49, 32, 40], [66, 49, 40], [61, 99, 25]]
            var spanWidths = [];

            // colWidths holds the width of each column, i.e., the width of the
            //  longest <span>-wrapped word with index x, e.g., [66, 99, 40]
            var colWidths = [];

            // lineHeights holds height of each line
            var lineHeights = [];


            ////////////////////////////////////////////////////////////////////
            // OPTIONS //
            ////////////////////////////////////////////////////////////////////

            if (options === undefined) {
                options = {};
            }

            // Number of pixels to put between each span
            var buffer = (options.buffer === undefined) ? 30: options.buffer;

            // Number of pixels to put between groups of lines ("lineGroups")
            var lineGroupBuffer = (options.lineGroupBuffer === undefined) ?
                                    10 : options.lineGroupBuffer;

            // Number of pixels to indent each subsequent line
            var indent = (options.indent === undefined) ? 40 : options.indent;

            // Minimum width of a line as a percentage of the container's width
            var minLineWidthAsPerc = (options.minLineWidthAsPerc === undefined) ?
                                    50 : options.minLineWidthAsPerc;

            // Line Group Class: class to give to line groups
            var lineGroupClass = (options.lineGroupClass === undefined) ?
                            'dative-form-igt-line-group': options.lineGroupClass;

            ////////////////////////////////////////////////////////////////////
            // FUNCTIONS //
            ////////////////////////////////////////////////////////////////////

            // Spanify -- input: line of text; output: line with each word
            //  enclosed in a span tag
            function spanify(elementText) {
                return $.map(elementText.replace(/\s\s+/g, ' ').split(' '),
                    function (word) {
                        return '<span style="white-space: nowrap;">' + word +
                        '</span>';
                    }
                ).join(' ');
            }

            // Get Greatest Width -- return the greatest width among the words
            //  in the same 'column'.
            function getGreatestWidth(widths, index, spanIndex) {
                var result;
                if (colWidths[spanIndex] === undefined) {

                    // E.g., from [[49, 32, 40], [66, 49], [61, 99, 25]],
                    //  return [40, 25] (assuming spanIndex = 2)
                    widths = $.map(widths, function (widthSet) {
                        if (widthSet.length === widths[index].length) {
                            return widthSet[spanIndex];
                        } else {
                            return 0;
                        }
                    });

                    result = Math.max.apply(Math, widths); // Get the widest
                    colWidths[spanIndex] = result;  // Remember for later
                    return result;

                } else {
                    // We know max width of this column from previous iterations
                    return colWidths[spanIndex];
                }
            }

            // Set Width -- set the width of the span to the width of the widest
            //  span in the same column PLUS the buffer.
            function setWidth(index, spanIndex, span) {
                var greatestWidth = getGreatestWidth(spanWidths, index, spanIndex);
                $(span).css({display: 'inline-block',
                            width: greatestWidth + buffer});
            }

            // Sum -- sum all integers in an array (c'mon Javascript!)
            function sum(array) {
                var result = 0;
                for (var i = 0;i < array.length;i += 1) {
                    result += array[i];
                }
                return result;
            }

            // Get New Max Width: get the max width of a "line group" based on
            //  the current max width, indent and minLineWidthAsPerc
            function getNewMaxWidth(currentMaxWidth, minLineWidth) {
                if ((currentMaxWidth - indent) > minLineWidth) {
                    return currentMaxWidth - indent;
                } else {
                    // Sorry, we can't reduce the width any further
                    return currentMaxWidth;
                }
            }


            ////////////////////////////////////////////////////////////////////
            // ALIGN THE WORDS IN THE LINES ALREADY //
            ////////////////////////////////////////////////////////////////////

            // Clone the children and enclose each word of each child clone in
            //  span tags, record the width of each such span tag and the height
            //  of each line.
            children.each(function (index, child) {
                // wrap words in spans
                $(child).html(spanify($(child).text()));

                // record the width of each span
                var widths = [];
                $('span', child).each(function (index, span) {
                    widths.push($(span).width());
                });
                spanWidths.push(widths);

                // Record the height of each line
                lineHeights.push($($('span', child)[0]).height());

            });

            // linesToColumnify is an array of indices representing the lines
            //  whose span-wrapped words need to be aligned.  Such lines have
            //  a word count that is greater than one and equal to that of all
            //  subsequent lines.
            var linesToColumnify = [];
            $.each(spanWidths, function (index) {
                // isColumnable returns true if the last line has more than two
                //  words and all lines from this one on down have the same word
                //  count
                function isColumnable(index) {
                    if (spanWidths[spanWidths.length - 1].length < 2) {
                        return false;
                    }
                    for (var i = index + 1; i < spanWidths.length; i++) {
                        if (spanWidths[i].length !== spanWidths[index].length) {
                            return false;
                        }
                    }
                    return true;
                }
                if (isColumnable(index)) {
                    linesToColumnify.push(index);
                }
            });
            if (linesToColumnify.length < 2) {
                linesToColumnify = [];
            }

            // Set the width of each span tag to the width of the longest span
            //  tag in the same 'column' plus the buffer
            children.each(function (index, child) {
                // Only alter the width of spans inside of columnable lines
                if (linesToColumnify.indexOf(index) !== -1) {
                    //$(child).text($(child).text().replace(/ /g, ''));
                    $('span', child).each(function (spanIndex, span) {
                        setWidth(index, spanIndex, span);
                    });
                }
            });

            // If the container's height is not equal to the sum of the line
            //  heights, we have lines wrapping and need to fix that by breaking
            //  the lines into multiple lines.
            var containerHeight = $(this).height();
            if (containerHeight !== sum(lineHeights)) {
                var containerWidth = $(this).width();
                var minLineWidth = Math.round(minLineWidthAsPerc / 100 *
                                                containerWidth);

                // Create the lineGroups list of objects; this tells us the max
                //  width of each line and, indirectly via the spanWidths object,
                //  the slice of <span>-wrapped words we want in each line.
                var lineGroups = [{maxWidth: containerWidth, indent: 0,
                                 spanWidths: []}];
                $.each(colWidths, function (index, width) {
                    var lineGroup = lineGroups[lineGroups.length - 1];
                    if ((sum(lineGroup.spanWidths) + width + buffer) < lineGroup.maxWidth) {
                        lineGroup.spanWidths.push(width + buffer);
                    } else {
                        lineGroups.push({maxWidth:
                            getNewMaxWidth(lineGroup.maxWidth, minLineWidth),
                            spanWidths: [width + buffer]});
                    }
                });

                // Create a new container that has the lines broken up,
                //  grouped and indented appropriately.
                var newContainer = $('<div>');
                var begin = 0;
                var previousIndent = 0;
                $.each(lineGroups, function (index, lineGroup) {
                    var topMarg = (index !== 0) ? lineGroupBuffer : 'auto';
                    var currentIndent = ((lineGroup.maxWidth -
                        (index * indent)) < minLineWidth) ? previousIndent :
                        (index * indent);
                    previousIndent = currentIndent;

                    var lineGroupDiv = $('<div>')
                                            .addClass(lineGroupClass)
                                            .css({'margin-left': currentIndent,
                                                'margin-top': topMarg});
                    var end = begin + lineGroup.spanWidths.length;
                    container.children().clone(true).each(
                        function (index, line) {
                            lineGroupDiv.append(
                                $(line)
                                    .html($(line).children().slice(begin, end)));
                        }
                    );
                    newContainer.append(lineGroupDiv);
                    begin = end;
                });

                // Replace the container's children with those of the new container
                container.html(newContainer.children());
            }
        });
    };
});
