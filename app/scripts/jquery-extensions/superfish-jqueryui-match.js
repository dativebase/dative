'use strict';
/* superfishJQueryUIMatch -- jQuery extension, AMD-compatible
 *
 *  Function: makes the superfish menu match the JQuery UI colors of the page.
 *
 *  Usage: after superfish-ifying a <ul>, call superfishJQueryUIMatch, e.g.,
 *
 *    $('ul.sf-menu')
 *        .superfish()
 *        .superfishJQueryUIMatch();
 *
 *  Depends on another jQuery extension, viz. getJQueryUIColors
 *
 */

define(['jquery', 'jqueryui', 'superfish', 'jqueryuicolors'], function($) {

    // superfishJQueryUIMatch alters the superfish menu to match the jQuery UI
    //  theme currently in use
    $.fn.superfishJQueryUIMatch = function (colorsProvided) {
        // Get the jQuery UI theme's colors
        var colors = (typeof colorsProvided === 'undefined') ?
            $.getJQueryUIColors() : colorsProvided;

        // Alter the superfish styles to match the jQuery UI theme, etc.
        $(this)
            .find('li')
                .css(colors.def).find('a').css('color', colors.defCo).end()
                .bind(
                    {
            'mousedown': function (e) {
                            $(this).css(colors.act)
                                .children('a').css('color', colors.actCo)
                                .children('span.sf-icon-triangle-1-e')
                                    .css('background-image', colors.actArrowEImg);
                            e.stopPropagation();
                        },
            'mouseup': function () {
                            $(this).css(colors.hov)
                                .children('a').css('color', colors.hovCo)
                                .children('span.sf-icon-triangle-1-e')
                                    .css('background-image', colors.hovArrowEImg);
                        },
            'mouseleave': function () {
                            $(this).css(colors.def)
                                .children('a').css('color', colors.defCo)
                                .children('span.sf-icon-triangle-1-e')
                                    .css('background-image', colors.defArrowEImg);
                        },
            'click': function () {$(this).hideSuperfishUl();}
        }
                )
                .hover(function () {
                        $(this).css(colors.hov);
                        $(this).find('a').css('color', colors.hovCo);
                    }, function () {
                        $(this).css(colors.def);
                        $(this).find('a').css('color', colors.defCo);
                    }).end()
            .find('li.sfHover')
                .find('a').css('color', colors.hovCo).end().css(colors.hov).end()
            .find('li li:last-child')
                .addClass('ui-corner-bottom sf-option-bottom').end()
            .find('li li li:first-child')
                .addClass('ui-corner-tr sf-option-top').end()
            .find('li li:has(ul) > a')
                .append($('<span>').addClass('sf-icon-triangle-1-e')
                        .css('background-image', colors.defArrowEImg)) ;
    };
});
