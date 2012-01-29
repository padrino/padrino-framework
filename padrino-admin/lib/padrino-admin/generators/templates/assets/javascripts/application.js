

$(function(){
    function openModal(source, title_tag, type,close) {
        // clearModal();
        $('#padrino-modal-title').append($(source + ' ' + title_tag).html());
        $(source + ' ' + title_tag).remove();
        $('#padrino-modal-body').append($(source).html());
        $(source).remove();
        $('#padrino-modal').addClass('flash-'+type);
        $('#padrino-modal .modal-header').addClass('alert-'+type);
        $('#padrino-modal-close').html(close);
        $('#padrino-modal').modal('show');
    };

    function clearModal(){
        $('#padrino-modal-title').empty();
        $('#padrino-modal-body').empty();
        $('#padrino-modal-close').empty();

    };
    // Form validation color
    $('.invalid').parent().each(function(){
        $(this).parent().addClass('error');
    });
    // form error
    if($('#field-errors').length){
        openModal('#field-errors','h4',"error",'Close');
    };
    // flash result
    if($('#flash-result').length){
        openModal('#flash-result','h4',$('#flash-result').attr('class'),'Close');
    };
    // clear modal
    $('#padrino-modal').on('hide',function(){
        $('#padrino-modal-title').empty();
        $('#padrino-modal-body').empty();
        $('#padrino-modal-close').empty();
    });

    // i need to fix
    $(".btn_delete").click(function(){
        // find form
        var form ="."+ $(this).attr('data-form');
        var clone = $(form).clone();
        // remove hide class
        $(clone).removeClass('hide');
        // insert form into modal
        $('#padrino-modal-body').append($(clone));
        $('#padrino-modal').addClass('flash-error');
        $('#padrino-modal .modal-header').addClass('alert-error');
        $('#padrino-modal-title').append( $(form + ' input:submit').val() + ' : ' +$(form).attr('data-title') );
        $('#padrino-modal-close').append($(this).attr('data-cancel'));
        $('#padrino-modal-close').addClass('hide');

        $(clone).append($('#padrino-modal-close').clone().removeClass('hide'));
        $(clone).prepend("<h4>"+$(clone).attr('data-title')+"</h4>");
        $(clone).append("<div class='clearfix' />");
        // show modal
        $('#padrino-modal').modal('show');
    });
});
