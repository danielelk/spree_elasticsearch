namespace :spree_elasticsearch do
  # rake spree_elasticsearch:load_active_products
  desc "Load active products into the index."
  task :load_active_products => :environment do
    try_index
    products = Spree::Product.joins(:stock_items).joins(:master).where('spree_stock_items.count_on_hand > ? OR spree_variants.count_on_display > ?', 0, 0)
    Spree::Product.import_products_to_es(products)
  end

  # rake spree_elasticsearch:load_products
  desc "Load all products into the index."
  task :load_products => :environment do
    try_index
    products = Spree::Product.all
    Spree::Product.import_products_to_es(products)
  end

  # rake spree_elasticsearch:remove_product[id]
  desc "Remove product by id."
  task :remove_product, [:id] => :environment do |t, args|
    try_index
    begin
      Spree::Product.find_by_id(args[:id].to_i).__elasticsearch__.delete_document
    rescue
      puts "Product not found"
    end
  end

  # rake spree_elasticsearch:find_product[id]
  desc "Find product by id."
  task :find_product, [:id] => :environment do |t, args|
    try_index
    begin
      product = Spree::Product.get(args[:id].to_i)
      puts "product: #{product.inspect}"
    rescue
      puts "Product not found"
    end
  end

  def try_index
    unless Elasticsearch::Model.client.indices.exists index: Spree::ElasticsearchSettings.index
      Elasticsearch::Model.client.indices.create \
        index: Spree::ElasticsearchSettings.index,
        body: {
            settings: {
                number_of_shards: 1,
                number_of_replicas: 0,
                analysis: {
                    analyzer: {
                        nGram_analyzer: {
                            type: "custom",
                            filter: ["lowercase", "asciifolding", "nGram_filter"],
                            tokenizer: "whitespace"
                        },
                        snowball_analyzer: {
                            type: "custom",
                            filter: ["lowercase", "asciifolding", "snowball_filter"],
                            tokenizer: "whitespace"
                        },
                        whitespace_analyzer: {
                            type: "custom",
                            filter: ["lowercase", "asciifolding"],
                            tokenizer: "whitespace"
                        }
                    },
                    filter: {
                        nGram_filter: {
                            max_gram: "20",
                            min_gram: "3",
                            type: "nGram",
                            token_chars: ["letter", "digit", "punctuation", "symbol"]
                        },
                        snowball_filter: {
                            type: "snowball",
                            token_chars: ["letter", "digit", "punctuation", "symbol"]
                        }
                    }
                }
            },
            mappings: Spree::Product.mappings.to_hash}
    end
  end
end
