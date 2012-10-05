jQuery ->
  # local variables
  pModal = $ '#padrino-modal'
  pHeader = $ '#padrino-modal-header'
  pTitle = $ '#padrino-modal-title'
  pBody = $ '#padrino-modal-body'
  pClose = $ '#padrino-modal-close'
  pFooter = $ '#padrino-modal-footer'

  # openModal function
  openModal = (source, title_tag = 'h4', type = 'warning', closed = 'Close', objects_move = [], title_remove = false, hide_remove = true, html = false, center = false) ->
    pModal.addClass "flash-#{type}"
    pHeader.addClass "alert-#{type}"
    $(source).find('.hide').removeClass 'hide' if hide_remove
    pTitle.append "#{type}"
    $(source).find(title_tag).remove() if title_remove
    pModal.addClass "flash-#{type}"
    if html? then pBody.append($(source).html()) else pBody.append $(source)
    pBody.addClass 'pagination-centered' if center
    for obj in objects_move
      $('#padrino-modal-footer').append $("#padrino-modal-body #{obj}")
    pClose.html closed
    pModal.modal 'show'

  # Form validation color
  $('.invalid').parent().each -> $(this).parent().addClass 'error'

  # Form error
  openModal('#field-errors','h4',"error",'Close') if $('#field-errors').length

  # Flash result
  openModal('#flash-result','h4',$('#flash-result').attr('class'),'Close') if $('#flash-result').length

  # Clear padrino-modal
  $('#padrino-modal').on 'hide', ->
    types = ['success','notice','danger','error','info','warning']

    pModal.unwrap()
    pTitle.empty()
    pHeader.removeClass "alert"
    for type in types
      pHeader.removeClass "alert-#{type}"
      pModal.removeClass "flash-#{type}"
    pBody.empty().removeClass 'pagination-centered'
    btn = pClose.clone().removeClass 'hide'
    pFooter.empty().append btn
    pClose.empty()

  # Initialize Modal form to delete
  prepareModalForm = (data) ->
    form = $(data.form).clone()
    pModal.wrap "<form id='padrino-modal-form' />"
    pForm = $ '#padrino-modal-form'
    pForm.attr 'action', form.attr('action')
    pForm.attr 'method', form.attr('method') if form.attr 'method'
    form.prepend "<h4>#{data.title}</h4>"
    openModal form, 'h4', data.type, null, [':input:submit', 'a'] , false, false, true, true

  #  button delete
  $(".btn_delete").click -> prepareModalForm($(this).data())

  # button bulk delete
  $('#btn_multiple_delete').click ->
    $('#multiple_delete_form :checkbox').remove()
    $('#multiple_delete_form').append($('#multiple_list :checkbox:checked').clone())
    $('#multiple_delete_form :checkbox').attr 'checked','checked'
    $('#multiple_delete_form :checkbox').addClass 'hide'
    prepareModalForm($(this).data()) if $('#multiple_delete_form :checkbox:checked').length > 0


  # general submit method
  $('.to_submit').click -> $(this).parent('form:first').submit()
  $('#check_all').click -> $('#multiple_list :checkbox').attr 'checked','checked'
  $('#uncheck_all').click -> $('#multiple_list :checkbox').removeAttr 'checked'