module Listalicious
  class TableBuilder < GenericBuilder

    attr_accessor :template, :collection

    def render(options, &proc)
      buffer = template.capture(self, &proc)
      template.concat(template.content_tag(:table, buffer, options))
    end

    def head(options = {}, &proc)
      column_group(:head, options, &proc)
    end

    def body(options = {}, &proc)
      column_group(:body, options, &proc)
    end

    def foot(options = {}, &proc)
      column_group(:foot, options, &proc)
    end

    def columns(scope = :body, options = {}, &proc)
      raise ArgumentError, "Missing block" unless block_given?

      if scope.kind_of? Array
        scope.collect { |scope| column_group(scope, options, &proc) }
      else
        column_group(scope, options, &proc)
      end
    end

    def column_group(scope, options = {}, &proc)
      @current_scope = scope
      options[:html] ||= {}
      self.send("column_group_#{scope}", options, &proc)
    end

    def column_group_head(options = {}, &proc)
      @column_count = 0      
      @head_wrapper = template.content_tag(:tr, template.capture(collection.first, 0, &proc),
                         options[:html].merge({:class => template.add_class(options[:html][:class], 'header')}))
      template.content_tag(:thead, @head_wrapper, options.delete(:wrapper_html))
    end

    def column_group_body(options = {}, &proc)
      return unless collection.first.present?

      buffer = ''
      collection.each_with_index do |record, index|
        @column_count = 0
        
        if @options[:grouped_by]
          buffer << @head_wrapper if record[@options[:grouped_by]] != @last_row_grouping
          @last_row_grouping = record[@options[:grouped_by]]
        end

        cycle = template.cycle('even', 'odd');
        buffer << template.content_tag(:tr, template.capture(record, index, &proc),
                     options[:html].merge({:class => template.add_class(options[:html][:class], cycle)}))
        buffer << template.content_tag(:tr, @extra,
                     options[:html].merge({:class => template.add_class(options[:html][:class], cycle)})) if @extra.present?
        @extra = nil
      end
      template.content_tag(:tbody, buffer, options.delete(:wrapper_html))
    end

    def column_group_foot(options = {}, &proc)
      buffer = template.content_tag(:tr, template.capture(collection.first, 0, &proc), options[:html])
      template.content_tag(:tfoot, buffer, options.delete(:wrapper_html))
    end

    def column(*args, &proc)
      options = args.extract_options!
      contents = options == args.first ? nil : args.first

      if @current_scope == :body
        contents = template.capture(self, &proc) if block_given? && collection.first.present?
      else
        contents = options[:title] || contents
      end

      @column_count = @column_count + 1
      self.send("#{@current_scope}_column", contents, options)
    end

    def full_column(contents = nil, options = {}, &proc)
      raise ArgumentError, "Must provide a string or a block" if !block_given? && contents.nil?
      contents ||= template.capture(self, &proc)

      options[:html] ||= {}
      options[:html][:colspan] ||= @column_count

      options[:wrapper_html] ||= {}
      options[:wrapper_html][:class] = template.add_class(options[:wrapper_html][:class], 'full-column')

      @extra = self.send("#{@current_scope}_column", contents, options)
    end

    def controls(contents = nil, options = {}, &proc)
      return unless @current_scope == :body
      raise ArgumentError, "Must provide a string or a block" if !block_given? && contents.nil?
      contents ||= template.capture(self, &proc)

      options[:html] ||= {}
      options[:html][:class] = template.add_class(options[:html][:class], 'controls')

      self.send("#{@current_scope}_column", contents, options)
    end

    def extra(contents = nil, options = {}, &proc)
      return unless @current_scope == :body
      raise ArgumentError, "Must provide a string or a block" if !block_given? && contents.nil?
      contents ||= template.capture(self, &proc)

      options[:html] ||= {}
      options[:html][:colspan] ||= @column_count

      options[:wrapper_html] ||= {}
      options[:wrapper_html][:class] = template.add_class(options[:wrapper_html][:class], 'extra')

      @extra = self.send("#{@current_scope}_column", contents, options)
      ''
    end

    def head_column(contents, options = {})
      options[:html] ||= {}
      options[:html][:width] ||= options[:width]
      
      contents = sortable_link(contents, options[:sort]) if options[:sort]

      template.content_tag(:th, contents, options.delete(:html))
    end

    def body_column(contents, options = {})
      template.content_tag(:td, contents, options.delete(:html))
    end

    def foot_column(contents, options = {})
      contents = sortable_link(contents, options[:sort]) if options[:sort]

      template.content_tag(:th, contents, options.delete(:html))
    end
    
  end
end