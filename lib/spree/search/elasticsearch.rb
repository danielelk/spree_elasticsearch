module Spree
  module Search
    # The following search options are available.
    #   * taxon
    #   * keywords in name or description
    #   * properties values
    class Elasticsearch <  Spree::Core::Search::Base
      include ::Virtus.model

      attribute :query, String
      attribute :taxons, Array
      attribute :browse_mode, Boolean, default: true
      attribute :properties, Hash
      attribute :per_page, String
      attribute :page, String
      attribute :sorting, String
      attribute :price_range, Array
      attribute :promo, Boolean, default: false
      attribute :recently, Boolean, default: false

      def initialize(params)
        self.current_currency = Spree::Config[:currency]
        prepare(params)
      end

      def retrieve_products
        from = (@page - 1) * Spree::Config.products_per_page
        search_result = Spree::Product.__elasticsearch__.search(
          Spree::Product::ElasticsearchQuery.new(
            query: query,
            taxons: taxons,
            browse_mode: browse_mode,
            from: from,
            properties: properties,
            sorting: sorting,
            price_range: price_range,
            promo: promo,
            recently: recently
          ).to_hash
        )
        search_result.limit(per_page).page(page).records
      end

      protected

      # converts params to instance variables
      def prepare(params)
        # keywords
        @query = params[:keywords]
        @promo = params[:promo]
        @recently = params[:recently]

        # sorting
        if params[:search] && params[:search][:s]
          @sorting = params[:search][:s]
          params[:search].delete(:s)
        end

        # taxons
        @taxons = params[:taxon] unless params[:taxon].nil?
        @browse_mode = params[:browse_mode] unless params[:browse_mode].nil?

        # price
        if params[:search] && params[:search][:price_any]
          @price_range = params[:search][:price_any]
          params[:search].delete(:price_any)
        end

        # properties
        if params[:search]
          @properties = Hash.new

          params[:search].each do |key, value|
            value.reject! { |v| v.blank? }
            next if value.empty?

            if key == 'genre_any'
              @properties[:genero] = value
            elsif key == 'brand_any'
              @properties[:marca] = value
            elsif key == 'condition_any'
              @properties[:condicao] = value
            elsif key == 'color_any'
              @properties[:cor] = value
            elsif key == 'size_any'
              @properties[:'tamanho-retroca'] = value
            end
          end
        end

        # pagination
        @per_page = (params[:per_page].to_i <= 0) ? Spree::Config[:products_per_page] : params[:per_page].to_i
        @page = (params[:page].to_i <= 0) ? 1 : params[:page].to_i
      end
    end
  end
end
