# coding: utf-8
require 'builders/generic_builder'
require 'builders/table_builder'

module Listalicious #:nodoc:

  # Semantic list helper methods
  #
  # Example Usage:
  #
  module SemanticListHelper

    @@builder = ::Listalicious::TableBuilder
    mattr_accessor :builder

    def semantic_list_for(collection, options, &proc)
      raise ArgumentError, "Missing block" unless block_given?

      # TODO: should :as be required?

      options[:html] ||= {}
      options[:html][:class] = add_class(options[:html][:class], 'semantic-list')
      options[:html][:id] ||= "#{options[:as] || collection.first ? collection.first.class.name.underscore : 'semantic'}_list"

      if options[:sort_url]
        options[:html][:class] = add_class(options[:html][:class], 'sortable')
        options[:html]['data-sorturl'] = url_for(options[:sort_url])
      end

      options[:html][:class] = add_class(options[:html][:class], 'selectable') if options[:selectable]
      options[:html][:class] = add_class(options[:html][:class], 'expandable') if options[:expandable]

      builder = options[:builder] || TableBuilder
      builder.new(@template, collection, options, &proc)
    end

    def add_class(classnames, classname)
      out = (classnames.is_a?(String) ? classnames.split(' ') : []) << classname
      out.join(' ')
    end

  end

  module ActiveRecordExtensions # :nodoc:

    class OrderableConfiguration
      def initialize(target)
        @target = target
      end

      # Provide fields that are orderable in the configuration block.
      #
      # *Note*: If +only+ or +except+ aren't called from within the configuration block, all fields will be orderable.
      #
      # === Example
      #   only :last_name, :email_address
      def only(*args)
        @target.orderable_fields = args
      end

      # Provide fields that are not to be orderable, with the default list being all fields.
      #
      # *Note*: If +only+ or +except+ aren't called from within the configuration block, all fields will be orderable.
      #
      # === Example
      #   except :id, :password
      def except(*args)
        @target.orderable_fields - args
      end

      # Provide the default sort field, optionally a direction, and additional options.
      #
      # === Supported options
      # [:stable]
      #   Will force appending the default sort to the end of all sort requests.  Default is false.
      #
      # === Example
      #   default :first_name (direction defaults to :asc)
      #   default :first_name, :stable => true
      #   default :first_name, :desc, :stable => true
      def default(*args)
        options = args.extract_options!
        field = args.shift
        direction = args.shift || :asc

        @target.default_order = {:field => field, :direction => direction, :options => options}
      end
    end

    # Makes a given model orderable for lists
    #
    # To specify that a model behaves according to the Listalicious order style call orderable_fields.  The
    # orderable_fields method takes a configuration block.
    #
    # === Example
    # orderable_fields do
    #   only :first_name, :last_name
    #   default :last_name
    # end
    #
    # === Configuration Methods
    # [only]
    #   Provide fields that are orderable.
    # [except]
    #   Provide fields that are not orderable, with the default list being all fields.
    # [default]
    #   Provide the default sort field, optionally a direction, and additional options.
    #
    # *Notes*:
    # * If +only+ or +except+ are not called within the block, all fields on the model will be orderable, this includes
    #   things like id, and password/password salt columns.
    # * If +default+ isn't called, the first field will be considered the default, asc being the default direction.
    #
    def orderable_fields(&config_block)
      cattr_accessor :orderable_fields, :default_order

      # make all columns orderable, incase only or except aren't called in the configuration block
      self.orderable_fields = column_names.map { |column_name| column_name.to_s }

      OrderableConfiguration.new(self).instance_eval(&config_block)
      self.orderable_fields.collect!{ |field| field.to_s }

      self.default_order ||= {:field => self.orderable_fields.first, :direction => :desc}
      
      attach_orderable_scopes
    end

    # Attaches the ordered_from named scope to the model requesting it.  The named scope can be chained in the
    # controller by using:
    #
    # +Users.ordered_from(params).paginate :page => params[:page], :per_page => 2+
    #
    # The params are expected to be in a specific style:
    #
    # eg. order[table_name][]=last_name:desc&order[table_name][]=first_name:asc
    #
    # Which will generate the order clause +"last_name DESC, first_name ASC"+.
    def attach_orderable_scopes
      self.named_scope :ordered_from, lambda { |params|
        return unless params.include?(:order) and params[:order][self.table_name.to_sym]

        fields = params[:order][self.table_name.to_sym].collect do |field_and_dir|
          field, dir = field_and_dir.split(':')
          self.orderable_fields.include?(field) ? [field, dir.to_s.downcase] : nil
        end.compact

        fields.empty? ?
          nil :
          {:order => fields.map{ |field, dir| "#{field} #{dir.downcase == 'desc' ? 'DESC' : 'ASC'}" }.join(', ')}
      }
    end

  end

end

ActionController::Base.helper Listalicious::SemanticListHelper
ActiveRecord::Base.extend Listalicious::ActiveRecordExtensions
