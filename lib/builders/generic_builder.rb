module Listalicious
  class GenericBuilder

    attr_accessor :template, :collection

    def initialize(template, collection, options = {}, &proc)
      @template, @collection, @options = template, collection, options
      @object_name = collection.first.class.name.underscore unless collection.empty?

      render(options.delete(:html), &proc)
    end

    def render(options, &proc); end







    def sortable_link(contents, field)
      sort_url, sort_direction = sortable_params(field)
      template.content_tag(:a, contents, :href => "?#{sort_url}", :class => "sort-#{sort_direction == 'descending' ? 'ascending' : 'descending'}")
    end

    def sortable_params(field)
      object_name = @object_name.nil? ? '' : "#{@object_name}_"

      params = template.params.reject { |param, value| ['action', 'controller', "#{object_name}sort_desc"].include?(param) }
      direction = params.delete("#{object_name}sort_asc") == field.to_s ? 'descending' : 'ascending'
      method = direction == 'descending' ? "#{object_name}sort_desc" : "#{object_name}sort_asc"
      params[method] = field

      [params.to_query, direction]
    end

  end
end