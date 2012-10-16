Admin.helpers do

  # sort and paginate with the help of some instance varaiables
  def sort_page(model, model_plural, model_singular, orm, params)
    @sort_orm = orm
    @sort_model = model
    if sort_valid_orm?
      @sort_columns = sort_columns
      @sort_column = sort_column(params)
      @sort_direction = sort_direction(params)
      @sort_page_no = sort_page_no(params)
      @sort_per_page = sort_per_page(params)
      @sort_route = model_plural
      sort_it
    else
      # unsorted/unpaginated for unsupported orms
      @sort_model.all   
    end
  end
  
  # generate a link for the table header
  def sort_link(column)
    direction = (column == @sort_column && 
                 @sort_direction == :asc) ? :desc : :asc
    if sort_valid_orm?
      # generate a link
      link_to sort_title(column), url(@sort_route, :index, 
        :sort => column, :direction => direction, :page_size => @sort_per_page)
    else
      # generate plain text
      sort_header(column)
    end
  end 
 
  # support methods for sort_page and sort_link 
  
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
    @sort_columns.include?(column) ? column : :id
  end
  
  # restrict the possible page number to > zero, set 1 as default
  def sort_page_no(params)
    page_no = params[:page]
    page_no ||= 1
    page_no = page_no.to_i.abs
    page_no.zero? ? 1 : page_no
  end
  
  # restrict per_page to > 0, set to model or global definition as default 
  def sort_per_page(params)
    per_page = params[:page_size]
    if @sort_model.respond_to?(:per_page)
      per_page ||= @sort_model.per_page 
    end
    per_page ||= Padrino::Admin::SORT_PER_PAGE
    per_page = per_page.to_i.abs
    # save change for this session
    if @sort_model.respond_to?(:per_page) 
      if per_page != @sort_model.per_page 
        @sort_model.per_page = per_page
      end
    end
    per_page.zero? ? 1 : per_page
  end

  # decide if we are ready for this orm  
  def sort_valid_orm?
    defined?(WillPaginate) and 
      Padrino::Admin::SORT_VALID_ORMS.include? @sort_orm
  end
  
  # generate translation of column name
  def sort_header(column)
    mat(@sort_model_name, column)
  end
  
  # generate a title for the sorted table header
  def sort_title(column)
    result = sort_header(column)
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
  
  # generate a symbol array of the column names
  def sort_columns
    case @sort_orm
    when :sequel
      columns = @sort_model.columns
    when :datamapper
      columns = @sort_model.properties.collect { |x| x.name}
    when :activerecord
      columns = @sort_model.column_names
      columns = columns.map {|x| x.to_sym}
    end
  end
  
  # sort the model as requested
  def sort_it
    case @sort_orm
    when :sequel
      sorted = @sort_model.order(@sort_column)
      sorted = sorted.reverse if @sort_direction == :desc
      sorted.paginate(@sort_page_no, @sort_per_page)
    when :datamapper
      sorted = @sort_model.all(:order => [@sort_column.asc])
      sorted = sorted.reverse if @sort_direction == :desc
      sorted.paginate(:page => @sort_page_no, :per_page => @sort_per_page)
    when :activerecord
      order = @sort_column.to_s + ' ' + @sort_direction.to_s.upcase
      @sort_model.per_page = @sort_per_page
      @sort_model.page(@sort_page_no).order(order)
    end 
  end
end