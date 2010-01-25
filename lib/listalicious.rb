# coding: utf-8
require File.join(File.dirname(__FILE__), *%w[builders generic_builder])
require File.join(File.dirname(__FILE__), *%w[builders table_builder])

module Listalicious #:nodoc:

  # Semantic list helper methods
  #
  # Example Usage:
  #
  module SemanticListHelper

    @@builder = ::Listalicious::TableBuilder
    mattr_accessor :builder

    def semantic_list_for(collection, *args, &proc)
      raise ArgumentError, "Missing block" unless block_given?

      options = args.extract_options!

      options[:html] ||= {}
      options[:html][:class] = add_class(options[:html][:class], 'semantic-list')
      options[:html][:id] ||= collection.first ? "#{collection.first.class.name.underscore}_list" : 'semantic_list'

      options[:html][:class] = add_class(options[:html][:class], 'actionable') if options[:actionable]
      options[:html][:class] = add_class(options[:html][:class], 'selectable') if options[:selectable]

      if options[:sort_url]
        options[:html][:class] = add_class(options[:html][:class], 'sortable')
        options[:html]['data-sorturl'] = url_for(options[:sort_url])
      end

      builder = options[:builder] || TableBuilder
      builder.new(@template, collection, options, &proc)
    end

    def add_class(classnames, classname)
      out = (classnames.is_a?(String) ? classnames.split(' ') : []) << classname
      out.join(' ')
    end

  end

  module ActiveRecordExtensions # :nodoc:

    def self.included(base) # :nodoc:
      return if base.kind_of?(::Listalicious::ActiveRecordExtensions::ClassMethods)
      base.class_eval do
        extend ClassMethods
      end
    end

    module ClassMethods

      attr_accessor :default_sort_field

      def sortable_fields(*args)
        options = args.extract_options!
        @acceptable_sort_fields = args
        @default_sort_field = options[:default]
      end

      def acceptable_sort_field?(column)
        column.present? ? @acceptable_sort_fields.include?(column.to_sym) : false
      end

      def sort_order_from(params)
        field = params["#{self.name.underscore}_sort_asc"] || params["#{self.name.underscore}_sort_desc"]
        field = @default_sort_field.to_s unless acceptable_sort_field?(field)

        method = (params["#{self.name.underscore}_sort_desc".to_sym] == field) ? 'DESC' : 'ASC'
        "#{field} #{method}" unless field.blank?
      end

    end

  end

end

ActionController::Base.helper Listalicious::SemanticListHelper
ActiveRecord::Base.class_eval { include ::Listalicious::ActiveRecordExtensions }