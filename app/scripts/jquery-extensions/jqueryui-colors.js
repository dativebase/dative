/* getJQueryUIColors -- jQuery extension, AMD-compatible
 *
 *  Function: returns an object detailing the jQuery UI colors used on the
 *   page.  Note: assumes a jQuery UI stylesheet is being used.
 *
 *  Usage:
 *
 *    var jQueryUIColors = $.getJQueryUIColors();
 *  
 */

(function (root, factory) {
    'use strict';
    if (typeof define === 'function' && define.amd) {
        // AMD. Register as an anonymous module depending on jQuery.
        define(['jquery', 'jqueryui'], function($){
            factory($);
        });
    } else {
        // No AMD. Register plugin with global jQuery object.
        factory(root.jQuery);
    }
}(this, function ($) {

    // Get the jQuery UI theme's colors (and east single triangle bg image)
    $.getJQueryUIColors = function () {
        $('body').append(
            $('<div>').addClass('jQueryUIColors')
                .append($('<button>').addClass('ui-state-default').text('b')
                    .button({icons: {primary: 'ui-icon-triangle-1-e'}}))
                .append($('<button>').addClass('ui-state-hover').text('b')
                    .button({icons: {primary: 'ui-icon-triangle-1-e'}}))
                .append($('<button>').addClass('ui-state-active').text('b')
                    .button({icons: {primary: 'ui-icon-triangle-1-e'}}))
                .append($('<button>').addClass('ui-state-error').text('b')
                    .button({icons: {primary: 'ui-icon-triangle-1-e'}}))
            );
        var defWS = $('div.jQueryUIColors button.ui-state-default');
        var hovWS = $('div.jQueryUIColors button.ui-state-hover');
        var actWS = $('div.jQueryUIColors button.ui-state-active');
        var errWS = $('div.jQueryUIColors button.ui-state-error');
        var colors = {
            defCo: defWS.css('color'),
            defBa: defWS.css('backgroundColor'),
            defBo: defWS.css('border-top-color'),
            defArrowEImg: defWS.find('span.ui-icon').css('background-image'),
            hovCo: hovWS.css('color'),
            hovBa: hovWS.css('backgroundColor'),
            hovBo: hovWS.css('border-top-color'),
            hovArrowEImg: hovWS.find('span.ui-icon').css('background-image'),
            actCo: actWS.css('color'),
            actBa: actWS.css('backgroundColor'),
            actBo: actWS.css('border-top-color'),
            actArrowEImg: actWS.find('span.ui-icon').css('background-image'),
            errCo: errWS.css('color'),
            errBa: errWS.css('backgroundColor'),
            errBo: errWS.css('border-top-color'),
            errArrowEImg: errWS.find('span.ui-icon').css('background-image')
        };
        colors.defBos = {'border-right-color': colors.defBo,
                         'border-left-color': colors.defBo,
                         'border-top-color': colors.defBo,
                         'border-bottom-color': colors.defBo};
        colors.hovBos = {'border-right-color': colors.hovBo,
                         'border-left-color': colors.hovBo,
                         'border-top-color': colors.hovBo,
                         'border-bottom-color': colors.hovBo};
        colors.actBos = {'border-right-color': colors.actBo,
                         'border-left-color': colors.actBo,
                         'border-top-color': colors.actBo,
                         'border-bottom-color': colors.actBo};
        colors.errBos = {'border-right-color': colors.errBo,
                         'border-left-color': colors.errBo,
                         'border-top-color': colors.errBo,
                         'border-bottom-color': colors.errBo};
        colors.def = $.extend({backgroundColor: colors.defBa,
                              color: colors.defCo}, colors.defBos);
        colors.hov = $.extend({backgroundColor: colors.hovBa,
                              color: colors.hovCo}, colors.hovBos);
        colors.act = $.extend({backgroundColor: colors.actBa,
                              color: colors.actCo}, colors.actBos);
        colors.err = $.extend({backgroundColor: colors.errBa,
                              color: colors.errCo}, colors.errBos);
        $('div.jQueryUIColors').remove();
        return colors;
    };

}));
