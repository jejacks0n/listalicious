module Listalicious
  class GenericBuilder

    attr_accessor :template, :collection

    def initialize(template, collection, options = {}, &proc)
      @template, @collection, @options = template, collection, options
      @object_name = "#{options[:as] || collection.first ? collection.first.class.name.underscore : ''}"
      @table_name = (options[:table_name] || @object_name.pluralize).to_s

      render(options.delete(:html), &proc)
    end

    def render(options, &proc); end

    # Creates the anchor tag for the orderable links.
    # It looks in the params for specificly styled query params:
    #
    # eg. order[users][]=login:asc&order[users][]=first_name:asc
    def orderable_link(contents, field)
      return contents if @object_name.empty?

      order_params = (template.params['order'] || {})[@table_name]
      fields = Hash[*order_params.to_a.collect { |field_and_dir| field_and_dir.split(':') }.flatten]

      order_params = (template.params['order'] || {}).clone.
          merge({@table_name => ["#{field}:#{"#{fields[field] == 'asc' ? 'desc' : 'asc'}"}"]})

      query = template.params.reject{ |param, value| ['action', 'controller'].include?(param) }
      query.merge!('order' => order_params)

      template.content_tag(:a, contents,
                :href => "?#{query.to_query}",
                :class => "#{fields[field] ? fields[field] == 'asc' ? 'ascending' : 'descending' : ''}")
    end
  end
end