require 'spec_helper'

describe 'Komerci Settings', type: :feature do
  before { create_admin_and_sign_in }

  context 'visit Komerci settings' do

    it 'should be a link to Komerci' do
      within('.sidebar') { page.find_link('Komerci Settings')['/admin/komerci_settings/edit'] }
    end

  end

  context 'show Komerci settings' do

    it 'should be the fields of Komerci settings' do
      visit spree.edit_admin_komerci_settings_path

      expect(page).to have_selector '#afiliation_key'
      expect(page).to have_selector '#test_mode'
      expect(page).to have_selector '#minimum_value'
      expect(page).to have_selector '#portion_without_tax'
      expect(page).to have_selector '#tax_value'
      expect(page).to have_selector '#max_portion'
      expect(page).to have_selector '[name=portions_type]'
    end

  end

  context 'edit Cielo cielo_settings' do

    before { visit spree.edit_admin_komerci_settings_path }

    it 'can edit test mode' do
      find(:css, '#test_mode').set true
      click_button 'Update'

      expect(Spree::KomerciConfig.test_mode).to be true
      expect(find_field('test_mode')).to be_checked

      # set default
      Spree::KomerciConfig.test_mode = false
    end

    it 'can edit portions type' do
      find(:css, '#portions_type_08').set true
      click_button 'Update'

      expect(Spree::KomerciConfig.portions_type).to eq '08'
      expect(find_field('portions_type_08')).to be_checked

      # set default
      Spree::KomerciConfig.portions_type = '06'
    end

    {komerci_user: 'test',
     komerci_password: '12345',
     afiliation_key: '12345678',
     minimum_value: '1',
     portion_without_tax: 1,
     tax_value: '1.5',
     max_portion: 12}.each do |key, value|

      it "can edit #{key.to_s.humanize}" do
        fill_in key.to_s, with: value
        click_button 'Update'

        expect(Spree::KomerciConfig[key]).to eq value
        expect(find_field(key).value).to eq value.to_s

        # set default
        Spree::KomerciConfig[key] = ''
      end
    end

  end
end