module SpreeZaezKomerci
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_zaez_komerci'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    initializer 'spree.zaez_komerci.preferences', after: :load_config_initializers do |app|
      # require file with the preferences of the Billet
      require 'spree/komerci_configuration'
      Spree::KomerciConfig = Spree::KomerciConfiguration.new
    end

    initializer 'spree.zaez_komerci.payment_methods', after: 'spree.register.payment_methods' do |app|
      app.config.spree.payment_methods << Spree::PaymentMethod::Komerci
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc
  end
end
