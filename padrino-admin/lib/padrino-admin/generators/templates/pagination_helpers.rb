Admin.helpers do

  # sort and paginate with the help of some instance varaiables
  def sort_page(model, model_plural, model_singular, orm, params)
    @sort_model = model
    @sort_column = sort_column(params)
    @sort_direction = sort_direction(params)
    @sort_page_no = sort_page_no(params)
    @sort_page_size = sort_page_size(params, model)
    @sort_route = model_plural
    @sort_orm = orm
    sort_it(orm)
  end
  
  # restrict the possible direction values, set :asc as default
  def sort_direction(params)
    direction = params[:direction]
    direction = direction.to_sym unless direction.nil?
    [:asc, :desc].include?(direction) ? direction : :asc
  end
  
  # restrict the possible column values, set :id as default
  def sort_column(params, model=@sort_model)
    column = params[:sort]
    column = column.to_sym unless column.nil?
    model.columns.include?(column) ? column : :id
  end
  
  # restrict the possible page number to > zero, set 1 as default
  def sort_page_no(params)
    page_no = params[:page]
    page_no ||= 1
    page_no = page_no.to_i.abs
    page_no.zero? ? 1 : page_no
  end
  
  # restrict page_size to > 0, set to model or global definition as default 
  def sort_page_size(params, model)
    page_size = params[:page_size]
    if model.instance_variable_defined?(:@sort_page_size)
      page_size ||= model.sort_page_size 
    end
    page_size ||= Padrino::Admin::SORT_PAGE_SIZE
    page_size = page_size.to_i.abs
    page_size.zero? ? 1 : page_size
  end

  # decide if we have already implemented the changes for this orm  
  def sort_orm_supported?(orm)
    case orm
    when :sequel
      true
    else
      false
  end
  
  # generate a link for the table header
  def sort_link(column)
    direction = (column == @sort_column && 
                 @sort_direction == :asc) ? :desc : :asc
    if sort_orm_supported?(@sort_orm)
      link_to sort_title(column), url(@sort_route, :index, 
        :sort => column, :direction => direction, :page_size => @sort_page_size)
    else
      column.to_s.camelize
    end
  end 
  
  # generate a title for the table header
  def sort_title(column)
    # the next line may be replaced by the appropriate I18n calls
    result = column.to_s.camelize
    if column == @sort_column
      if @sort_direction == :asc
        # add the utf-8 character for a up_triangle
        result = result + ' ' + "\u25B2"
      else
        # add the utf-8 character for a down_triangle
        result = result + ' ' + "\u25BC"
      end
    end
    result
  end
  
  # sort the model as requested
  def sort_it(orm)
    case orm
    when :sequel
      sorted = @sort_model.order(@sort_column)
      sorted = sorted.reverse if @sort_direction == :desc
      sorted.paginate(@sort_page_no, @sort_page_size)
    # insert here the code for other adapters
    else
      # unsorted/unpaginated for the rest
      @sort_model.all
    end 
  end
end