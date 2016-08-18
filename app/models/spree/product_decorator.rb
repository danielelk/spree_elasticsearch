# coding: utf-8
Spree::Product.class_eval do

  def self.import_products_to_es(all_products, batch_size = 4000)
    puts "start importing #{all_products.size} products.."
    all_products.find_in_batches(start: 0, batch_size: batch_size) do |products|
      bulk_products_index(products)
    end
  end

  def self.prepare_products(products)
    puts "converting to json.."
    products.map do |product|
      { index: { _id: product.id, data: product.as_indexed_json } }
    end
  end

  def self.bulk_products_index(products)
    puts "sending #{products.size} products in batch.."
    Spree::Product.__elasticsearch__.client.bulk({
      index: ::Spree::Product.__elasticsearch__.index_name,
      type: ::Spree::Product.__elasticsearch__.document_type,
      body: prepare_products(products)
    })
  end

end
