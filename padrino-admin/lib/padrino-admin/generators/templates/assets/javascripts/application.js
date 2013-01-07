(function() {
  'use strict';

  $(function() {
    // Automatically close alerts if there was any present.
    if ($('.alert').length > 0) {
      setTimeout(function() { $('.alert').alert('close'); }, 3000);
    }

    // Confirm before deleting one item 
    $('.delete-one').on('click', function(ev) {
      ev.preventDefault();
      $(this).addClass('active').siblings('.popover-delete-one').first().show().find('.cancel').on('click', function() {
        $(this).parents('.popover').hide().siblings('.delete-one').removeClass('active');
      });
    });

    // Check/uncheck all functionality
    function idCheckboxes(table) {
      return table.find('tbody tr td:first :checkbox');
    }
    function checkAll(table, checked) {
      // Toggle all checkboxes on the table's body that exist on the first column.
      idCheckboxes(table).attr('checked', checked ? 'checked' : false);

      // Toggle delete selected functionality
      // $('#delete-selected')[checked ? 'removeClass' : 'addClass']('disabled')
      //   .parent()[checked ? 'removeClass' : 'addClass']('disabled');
    }
    $('#check-all').on('click', function(ev) {
      ev.preventDefault();
      checkAll($(this).parents('table'), true);
    });
    $('#uncheck-all').on('click', function(ev) {
      ev.preventDefault();
      checkAll($(this).parents('table'), false);
    });

    // Delete selected
    $('#delete-selected').on('click', function(ev) {
      ev.preventDefault();
      if ($(this).is('.disabled')) return;

      console.log('TO DELETE', idCheckboxes($(this).parents('table')).map(function() { return $(this).val(); }).toArray());
    });

    $('#list tbody tr td:first :checkbox').on('click', function() {
      var checked = $('#list tbody tr td:first :checkbox:checked').length > 0;
      // Toggle delete selected functionality
      $('#delete-selected')[checked ? 'removeClass' : 'addClass']('disabled')
        .parent()[checked ? 'removeClass' : 'addClass']('disabled');
    });
  });

}).call(this);
