$(function(){
  $('table').dataTable({
    StateSave: true,
    aLengthMenu: [[50, 100, 150, -1], [50, 100, 150, 'All']],
  });

  $('.alert-message.modal').modal({
    show: true,
    keyboard: true,
    backdrop: true
  });
});
