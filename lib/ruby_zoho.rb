require 'zoho_api'
require 'api_utils'
require 'yaml'

module RubyZoho

  class Configuration
    attr_accessor :api, :api_key, :cache_fields, :crm_modules, :ignore_fields_with_bad_names, :cache_object

    def initialize
      self.api_key = nil
      self.api = nil
      self.cache_fields = false
      self.crm_modules = nil
      self.ignore_fields_with_bad_names = true
    end
  end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
    self.configuration.crm_modules ||= []
    self.configuration.cache_object ||= Class.new do
      def filename
        @filename ||= File.join(File.dirname(__FILE__), '..', 'spec', 'fixtures', 'fields.snapshot')
      end
      def get
        File.read(filename) if File.exists?(filename)
      end
      def set(data)
        File.open(filename, 'wb') { |file| file.write(data) }
      end
    end.new if self.configuration.cache_fields == true

    self.configuration.crm_modules = %w[Accounts Calls Contacts Events Leads Potentials Tasks].concat(
        self.configuration.crm_modules).uniq
    self.configuration.api = init_api(self.configuration.api_key,
                                      self.configuration.crm_modules,
                                      self.configuration.cache_object)
    RubyZoho::Crm.setup_classes()
  end

  def self.init_api(api_key, modules, cache_object)
    if val = cache_object && cache_object.get
      fields = YAML.load(val)
      zoho = ZohoApi::Crm.new(api_key, modules,
                              self.configuration.ignore_fields_with_bad_names, fields)
    else
      zoho = ZohoApi::Crm.new(api_key, modules, self.configuration.ignore_fields_with_bad_names)
      fields = zoho.module_fields
      cache_object && cache_object.set(fields.to_yaml)
    end
    zoho
  end

  require 'crm'

end
