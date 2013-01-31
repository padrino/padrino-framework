!function($) {
  'use strict';

  $(function() {
    var allCheckboxSelector = 'tbody tr td.selectable :checkbox', alertTimeout = 4000;

    // Automatically close alerts if there was any present.
    if ($('.alert').length > 0) {
      setTimeout(function() { $('.alert').alert('close'); }, alertTimeout);
    }

    // Confirm before deleting one item
    $('.delete-one').on('click', function(ev) {
      ev.preventDefault();
      $(this).addClass('active').siblings('.popover-delete-one')
        .first().show().find('.cancel').on('click', function() {

          $(this).parents('.popover').hide().siblings('.delete-one').removeClass('active');
        });
    });

    function toggleAction(selector, disabled) {
      var method = disabled ? 'addClass' : 'removeClass';
      $(selector)[method]('disabled').parent()[method]('disabled');
    }

    // Select/deselect record on row's click
    $('#list tbody tr td').on('click', function(ev) {
      ev.stopPropagation();
      $(this).parent().find('.selectable :checkbox').click();
    });
    // Check/uncheck all functionality
    function checkAll(table, checked) {
      // Toggle all checkboxes on the table's body that exist on the first column.
      table.find(allCheckboxSelector).prop('checked', checked);
      toggleAction('#delete-selected', !checked);
    }
    $('#select-all').on('click', function(ev) {
      ev.preventDefault();
      // We assume we want to stay on the dropdown to delete all perhaps
      ev.stopPropagation();
      checkAll($(this).parents('table'), true);
      toggleAction('#select-all', true);
      toggleAction('#deselect-all', false);
    });
    $('#deselect-all').on('click', function(ev) {
      ev.preventDefault();
      checkAll($(this).parents('table'), false);
      toggleAction('#deselect-all', true);
      toggleAction('#select-all', false);
    });
    // Delete selected
    $('#delete-selected').on('click', function(ev) {
      ev.preventDefault();
      ev.stopPropagation();
      if ($(this).is('.disabled')) return;

      $(this).parent().addClass('active').parent('.dropdown').addClass('open');
      $(this).addClass('active').siblings('.popover-delete-selected').first().show().find('.cancel').on('click', function() {
        // Hide the popover on cancel
        $(this).parents('.popover').hide().siblings('#delete-selected').removeClass('active').parent().removeClass('active');
        // and close the dropdown
        $(this).parents('.dropdown').removeClass('open');
      });

      $(this).siblings('.popover-delete-selected').find(':hidden[data-delete-many-ids=true]').
        val($(this).parents('table').find(allCheckboxSelector + ':checked').map(function() { return $(this).val(); }).toArray().join(','));
    });

    // Catch checkboxes check/uncheck and enable/disable the delete selected functionality
    $('#list ' + allCheckboxSelector).on('click', function() {
      var all = $('#list ' + allCheckboxSelector), checked = all.filter(':checked').length;

      toggleAction('#delete-selected', checked === 0);
      toggleAction('#deselect-all', checked === 0);
      toggleAction('#select-all', checked === all.length);
    });
  });

    // Explanation section :D
    $('#explanation').hide();
    $(".the-icons a").mouseenter(function(){
        $('#explanation h3').text($(this).attr('title'));
        $('#explanation').fadeIn('fast');
    });
    $(".the-icons a").mouseleave(function(){
        $('#explanation h3').text('');
         $('#explanation').hide();
    });

}(window.jQuery);
