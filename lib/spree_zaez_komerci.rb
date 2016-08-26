require 'spree_core'
require 'spree_zaez_komerci/engine'
require 'httparty'

Spree::PermittedAttributes.payment_attributes.push :portions
