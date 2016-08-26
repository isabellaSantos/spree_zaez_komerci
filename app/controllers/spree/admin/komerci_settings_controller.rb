class Spree::Admin::KomerciSettingsController < Spree::Admin::BaseController

  def edit
    @config = Spree::KomerciConfiguration.new
  end

  def update
    config = Spree::KomerciConfiguration.new

    params.each do |name, value|
      next if !config.has_preference?(name)
      config[name] = value
    end

    config.test_mode = false unless params.include?(:test_mode)

    flash[:success] = Spree.t(:successfully_updated, resource: Spree.t(:komerci_settings))
    redirect_to edit_admin_komerci_settings_path
  end
end