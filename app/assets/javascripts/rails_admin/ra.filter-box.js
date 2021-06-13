(function($) {

  var filters;

  $.filters = filters = {
    append: function(field_label, field_name, field_type, field_value, field_operator, field_options, index) {
      var value_name = 'filters[' +  field_name + '][' + index + '][value]';
      var operator_name = 'filters[' +  field_name + '][' + index + '][operator]';
      switch(field_type) {
        case 'boolean':
          var control = '<select class="span3 " name="' + value_name + '">' +
            '<option value="_discard">...</option>' +
            '<option value="true"' + (field_value == "true" ? 'selected="selected"' : '') + '>True</option>' +
            '<option value="false"' + (field_value == "false" ? 'selected="selected"' : '') + '>False</option>' +
            '<option disabled="disabled">---------</option>' +
            '<option ' + (field_value == "_present" ? 'selected="selected"' : '') + ' value="_present">Is present</option>' +
            '<option ' + (field_value == "_blank"   ? 'selected="selected"' : '') + ' value="_blank"  >Is blank</option>' +
          '</select>';
          break;
        case 'date':
        case 'datetime':
        case 'timestamp':
          var control = '<select class="switch-additionnal-fieldsets span3 " name="' + operator_name + '">' +
            '<option data-additional-fieldset="false" value="_discard">...</option>' +
            '<option data-additional-fieldset="false"' + (field_operator == "today"     ? 'selected="selected"' : '') + ' value="today">Today</option>' +
            '<option data-additional-fieldset="false"' + (field_operator == "yesterday" ? 'selected="selected"' : '') + ' value="yesterday">Yesterday</option>' +
            '<option data-additional-fieldset="false"' + (field_operator == "this_week" ? 'selected="selected"' : '') + ' value="this_week">This week</option>' +
            '<option data-additional-fieldset="false"' + (field_operator == "last_week" ? 'selected="selected"' : '') + ' value="last_week">Last week</option>' +
            '<option data-additional-fieldset="true" ' + (field_operator == "less_than" ? 'selected="selected"' : '') + ' value="less_than">Less than ... days ago</option>' +
            '<option data-additional-fieldset="true" ' + (field_operator == "more_than" ? 'selected="selected"' : '') + ' value="more_than">More than ... days ago</option>' +
            '<option disabled="disabled">---------</option>' +
            '<option data-additional-fieldset="false"' + (field_operator == "_not_null"  ? 'selected="selected"' : '') + ' value="_not_null">Is present</option>' +
            '<option data-additional-fieldset="false"' + (field_operator == "_null"    ? 'selected="selected"' : '') + ' value="_null" >Is blank</option>' +
          '</select>'
          var additional_control = '<input class="additional-fieldset span2 " style="display:' + (field_operator == "less_than" || field_operator == "more_than" ? 'block' : 'none') + ';" type="text" name="' + value_name + '" value="' + field_value + '" /> ';
          break;
        case 'enum':
          field_options = $('<div/>').html(field_options).text(); // entities decode
          var control = '<select name="' + value_name + '" class="span3 ">' +
            '<option value="_discard">...</option>' +
            field_options +
            '<option disabled="disabled">---------</option>' +
            '<option ' + (field_value == "_present" ? 'selected="selected"' : '') + ' value="_present">Is present</option>' +
            '<option ' + (field_value == "_blank"   ? 'selected="selected"' : '') + ' value="_blank"  >Is blank</option>' +
          '</select>';
          break;
        case 'string':
        case 'text':
        case 'belongs_to_association':
          var control = '<select class="switch-additionnal-fieldsets span3 " value="' + field_operator + '" name="' + operator_name + '">' +
            '<option data-additional-fieldset="true"'  + (field_operator == "like"        ? 'selected="selected"' : '') + ' value="like">Contains</option>' +
            '<option data-additional-fieldset="true"'  + (field_operator == "is"          ? 'selected="selected"' : '') + ' value="is">Is exactly</option>' +
            '<option data-additional-fieldset="true"'  + (field_operator == "starts_with" ? 'selected="selected"' : '') + ' value="starts_with">Starts with</option>' +
            '<option data-additional-fieldset="true"'  + (field_operator == "ends_with"   ? 'selected="selected"' : '') + ' value="ends_with">Ends with</option>' +
            '<option disabled="disabled">---------</option>' +
            '<option data-additional-fieldset="false"' + (field_operator == "_present"    ? 'selected="selected"' : '') + ' value="_present">Is present</option>' +
            '<option data-additional-fieldset="false"' + (field_operator == "_blank"      ? 'selected="selected"' : '') + ' value="_blank">Is blank</option>' +
          '</select>'
          var additional_control = '<input class="additional-fieldset span2" style="display:' + (field_operator == "_blank" || field_operator == "_present" ? 'none' : 'block') + ';" type="text" name="' + value_name + '" value="' + field_value + '" /> ';
          break;
        default:
          var control = '<input class="span2" type="text" name="' + value_name + '" value="' + field_value + '"/> ';
          break;
      }

      $('#filters_box').append(
        '<div class="row filter clearfix">' +
          '<span class="span3">' +
            '<span data-original-title="Click to remove this filter" rel="twipsy" class="btn info delete" data-disabler-name="filters[' +  field_name + '][' + index + '][disabled]">' + field_label + '</span>' +
          '</span>' +
          '<span class="span3">'+
            control +
          '</span>'+ 
          (additional_control ? '<span class="span2">' + additional_control + '</span>' : '') +
        '</div>'
      );
    }
  }

<<<<<<< HEAD
  $("#filters a").live('click', function() {
    $.filters.append(
      $(this).data('field-label'),
      $(this).data('field-name'),
      $(this).data('field-type'),
      $(this).data('field-value'),
      $(this).data('field-operator'),
      $(this).data('field-options'),
      $.now()
    );
    $("[rel=twipsy]").twipsy();
=======
  $("#filter_select").live('change', function() {
    var option = $(this).find('option:selected')
    if ($(this).val() != '') {
      $(this).val(''); // reset select
      $.filters.append(
        option.data('field-label'),
        option.data('field-name'),
        option.data('field-type'),
        option.data('field-value'),
        option.data('field-operator'),
        option.data('field-options'),
        $.now()
      );
    }
>>>>>>> origin/master
  });

  $('#filters_box .delete').live('click', function() {
    $(this).parents('.filter').hide();
    $(this).append('<input type="hidden" name="' + $(this).data('disabler-name') + '" value="true" />')
  });

  $('#filters_box .switch-additionnal-fieldsets').live('change', function() {
    var selected_option = $(this).find('option:selected');
    if($(selected_option).data('additional-fieldset')) {
      $(this).parent().siblings().children('.additional-fieldset').val('');
      $(this).parent().siblings().children('.additional-fieldset').show();
    } else {
      $(this).parent().siblings().children('.additional-fieldset').hide();
    }
  });
})( jQuery );
