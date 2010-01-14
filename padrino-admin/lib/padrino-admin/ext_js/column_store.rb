module Padrino
  module ExtJs
    # Return column config, and store config/data for ExtJS ColumnModel and Store
    class ColumnStore
      attr_reader :data

      def initialize(klass_model, config) #:nodoc
        @model = klass_model
        table_name = @model.table_name || @model.class.to_s.downcase.pluralize
        @data = config["columns"].map do |column|

          # Reformat our config
          column["header"]     ||= column["method"].to_s
          column["dataIndex"]  ||= column["method"]
          column["sortable"]   ||= column["sortable"].nil? ? true : column["sortable"]
          column["header"]       = @model.human_attribute_name(column["header"]) # try to translate with I18n the column name

          # Try to reformat the dataIndex
          data_indexes = Array(column["dataIndex"]).collect do |data_index|
            if data_index =~ /\./ # if we have some like categories.names we use this
              cols = data_index.split(".")
              column["name"] ||= cols[0] + "[" + cols[1..-1].join("][") + "]" # accounts.name will be => accounts[name]
            else
              column["name"] ||= "#{table_name.singularize}[#{data_index}]"
              data_index = "#{table_name}.#{data_index}"
            end
            data_index
          end

          # Now we join our data indexes
          column["dataIndex"] = data_indexes.compact.uniq.join(",")

          # Reformat mapping like a div id
          column["mapping"] ||= column["name"].sub(/\[/,"_").sub(/\]$/, "").sub(/\]\[/,"_")

          # Now is necessary for our columns an ID
          # TODO: check duplicates here
          column["id"] = column["mapping"]

          # Finally we can return our column
          column
        end
      end

      # Return an array config for build an Ext.grid.ColumnModel() config
      def column_fields
        data = @data.map do |data|
          data     = data.dup
          editor   = parse_column_editor(data.delete("editor"))
          renderer = parse_column_renderer(data.delete("renderer"))
          data.merge!(editor)   if editor
          data.merge!(renderer) if renderer
          data.delete("method")
          data.delete("mapping")
          data
        end
        JSON.pretty_generate(data)
      end

      # Return an array config for build an Ext.data.GroupingStore()
      def store_fields
        data = @data.map do |data|
          type = parse_store_renderer(data["renderer"])
          hash = { :name => data["dataIndex"] , :mapping => data["mapping"] }
          hash.merge!(type) if type
          hash
        end
        JSON.pretty_generate(data)
      end

      # Return data for a custom collection for the ExtJS Ext.data.GroupingStore() json
      def store_data_from(collection)
        collection.map do |c|
          @data.dup.inject({ "id" => c.id }) do |options, data|
            options[data["mapping"]] = (c.instance_eval(data["method"]) rescue I18n.t("admin.labels.not_found"))
            options
          end
        end
      end

      # Return a searched and paginated data collection for the ExtJS Ext.data.GroupingStore() json
      # You can pass options like:
      # 
      #   Examples
      #   
      #     store_data(params, :conditions => "found = 1")
      #     store_data(params, :include => :posts)
      # 
      def store_data(params={}, options={})
        # Some can tell me that this method made two identical queries one for count one for paginate.
        # We don't use the select count because in some circumstances require much time than select *.
        params[:limit]     ||= 50
        collection           = @model.ext_search(params, options)
        { :results => store_data_from(collection.records), :count => collection.count }.to_json
      end

      private
        def parse_store_renderer(renderer)
          case renderer
            when "date"          then { :type => "date", :dateFormat => "Y-m-d" }
            when "datetime"      then { :type => "date", :dateFormat => "c" }
            when "time_to_date"  then { :type => "date", :dateFormat => "c" }
          end
        end

        def parse_column_editor(editor)
          case editor
            when "checkbox"      then { :checkbox => true }
            when "combo"         then { :editor => "new Ext.form.ComboBox()".to_l }
            when "datefield"     then { :editor => "new Ext.form.DateField()".to_l }
            when "numberfield"   then { :editor => "new Ext.form.NumberField()".to_l }
            when "radio"         then { :editor => "new Ext.form.Radio()".to_l }
            when "textarea"      then { :editor => "new Ext.form.TextArea()".to_l }
            when "textfield"     then { :editor => "new Ext.form.TextField()".to_l }
            when "timefield"     then { :editor => "new Ext.form.TimeField()".to_l }
            when "datetimefield" then { :editor => "new Ext.form.DateTimeField()".to_l }
          end
        end

        def parse_column_renderer(renderer)
          case renderer
            when "time_to_date" then { :renderer => "Ext.util.Format.dateRenderer()".to_l }
            when "date"         then { :renderer => "Ext.util.Format.dateRenderer()".to_l }
            when "datetime"     then { :renderer => "Ext.util.Format.dateTimeRenderer()".to_l }
            when "percentage"   then { :renderer => "Ext.util.Format.percentage".to_l }
            when "eur_money"    then { :renderer => "Ext.util.Format.eurMoney".to_l }
            when "us_money"     then { :renderer => "Ext.util.Format.usMoney".to_l }
            when "boolean"      then { :renderer => "Ext.util.Format.boolRenderer".to_l }
            when "capitalize"   then { :renderer => "Ext.util.Format.capitalize".to_l }
            when "file_size"    then { :renderer => "Ext.util.Format.fileSize".to_l }
            when "downcase"     then { :renderer => "Ext.util.Format.lowercase".to_l }
            when "trim"         then { :renderer => "Ext.util.Format.trim".to_l }
            when "undef"        then { :renderer => "Ext.util.Format.undef".to_l }
            when "upcase"       then { :renderer => "Ext.util.Format.uppercase".to_l }
          end
        end

    end
  end
end