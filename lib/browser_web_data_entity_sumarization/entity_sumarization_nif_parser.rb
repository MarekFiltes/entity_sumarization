# encoding: utf-8

###
# Core project module
module BrowserWebData

  ###
  # Project logic module
  module EntitySumarization

    ###
    # The class include helpers to retrieve structured nif data from nif lines.
    class NIFLineParser
      include BrowserWebData::EntitySumarizationConfig

      ###
      # The method apply scan to recognize resource uri from given nif dataset line.
      #
      # @param [String] line
      #
      # @return [String] resource_uri
      # @example resource_uri: "http://dbpedia.org/resource/Captain_EO"
      def self.parse_resource_uri(line)
        (line.scan(SCAN_REGEXP[:scan_resource])[0])[0].split('?').first
      end

      ###
      # The method apply scan to recognize link, anchor, indexes and section from given nif dataset group of 7 lines.
      #
      # @param [Array<String>] lines_group
      #
      # @return [Hash] nif_data
      # @example nif_data:
      # {
      #   link: "http://dbpedia.org/resource/Science_fiction_film",
      #   anchor: "science fiction film",
      #   indexes:  ["33", "53"],
      #   section: "paragraph_0_419"
      # }
      def self.parse_line_group(lines_group)
        begin_index = lines_group[2].scan(SCAN_REGEXP[:begin_index])[0]
        end_index = lines_group[3].scan(SCAN_REGEXP[:end_index])[0]
        target_resource_link = lines_group[5].scan(SCAN_REGEXP[:target_resource_link])[0]
        section = lines_group[4].scan(SCAN_REGEXP[:section])[0]
        anchor = lines_group[6].scan(SCAN_REGEXP[:anchor])[0]

        {
          link: target_resource_link[1].force_encoding('utf-8'),
          anchor: anchor[1].force_encoding('utf-8'),
          indexes: [begin_index[1], end_index[1]],
          section: section[0].split('=')[1]
        }
      end

    end

  end

end