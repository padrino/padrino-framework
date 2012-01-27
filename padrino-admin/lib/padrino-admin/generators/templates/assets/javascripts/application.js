$(function(){

    $('#field-errors').addClass('modal fade');
    $('#field-errors h4').wrapAll("<div class='modal-header alert alert-error'></div>");
    $('#field-errors .modal-header').prepend("<a href='#' class='close' data-dismiss='modal'> &times;</a>");
    $('#field-errors p').wrap("<div class='modal-body'></div>") ;
    $('#field-errors ul').wrap("<div class='modal-body'></div>") ;
    $('#field-errors').append("<div class='modal-footer'><a href='#' class='btn primary' data-dismiss='modal'>Close</a></div>");
    $('#field-errors').modal();

    $('#flash-result').modal('show');


    $('#deleter').on('hide', function () {
        $('#deleter-title').empty();
        $('#deleter .modal-body').empty();
        $('#deleter-close').empty();
    });

    $(".btn_delete").click(function(){
        // find form
        var form ="."+ $(this).attr('data-form');
        var clone = $(form).clone();
        // remove hide class
        $(clone).removeClass('hide');
        // insert form into modal
        $('#deleter .modal-body').append($(clone));
        $('#deleter-title').append( $(form + ' input:submit').val() + ' : ' +$(form).attr('data-title') );
        $('#deleter-close').append($(this).attr('data-cancel'));
        $(clone).append($('#deleter-close').clone().removeClass('hide'));
        $(clone).prepend("<h4>"+$(clone).attr('data-title')+"</h4");
        $(clone).append("<div class='clearfix' />");
        // show modal
        $('#deleter').modal('show');

    });
});
