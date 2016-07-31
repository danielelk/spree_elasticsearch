# coding: utf-8
Spree::Product.class_eval do


  def self.importing_products
    active_products = Spree::Product.joins(:master).where('spree_variants.count_on_display > ?', 0)
    puts "importing #{active_products.size} products.."

    # active_products.find_in_batches do |products|
      bulk_products_index(active_products)
    # end
  end

  def self.prepare_products(products)
    puts 'preparing..'
    products.map do |product|
      { index: { _id: product.id, data: product.as_indexed_json } }
    end
  end

  def self.bulk_products_index(products)
    puts "bulking products.."
    Spree::Product.__elasticsearch__.client.bulk({
      index: ::Spree::Product.__elasticsearch__.index_name,
      type: ::Spree::Product.__elasticsearch__.document_type,
      body: prepare_products(products)
    })
  end

end