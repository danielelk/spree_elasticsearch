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
      attribute :remove_taxons, Array

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
            recently: recently,
            remove_taxons: remove_taxons
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
        @sorting = params[:search][:s] if params[:search] && params[:search][:s]

        # taxons
        @taxons = params[:taxon] unless params[:taxon].nil?
        @remove_taxons = params[:remove_taxons] unless params[:remove_taxons].nil?

        # price
        @price_range = convert_to_array(params[:search][:price_any]) if params[:search] && params[:search][:price_any]

        # properties
        if params[:search]
          @properties = Hash.new

          params[:search].each do |key, value|
	          next if key == 's' || key == 'price_any'

            case key
              when 'genre_any'
                @properties[:genero] = convert_to_array (value)
              when 'brand_any'
                value = convert_to_array (value).reject! { |c| c.blank? }
                @properties[:marca] = value unless value.nil? || value.empty?
              when 'condition_any'
                @properties[:condicao] = convert_to_array (value)
              when 'color_any'
                @properties[:cor] = convert_to_array (value)
              when 'size_any'
                @properties[:'tamanho-retroca'] = convert_to_array (value)
            end
          end
        end

        # pagination
        @per_page = (is_nil_or_negative? params[:per_page]) ? Spree::Config[:products_per_page] : params[:per_page].to_i
        @page = (is_nil_or_negative? params[:page]) ? 1 : params[:page].to_i
      end

      private

      def is_nil_or_negative? (number)
        (number.nil? || number.to_i <= 0) ? true : false
      end

      def convert_to_array (params)
        params.kind_of?(Hash) ? params.values : params
      end
    end
  end
end
