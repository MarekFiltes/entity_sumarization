#encoding: utf-8

# Module CacheHelper
module CacheHelper

  def self.clear_cache(type = '.json')
    dir = "#{Dir.tmpdir}/#{BrowserWebData::TMP_DIR}/*#{type}"
    Dir.glob(dir).each { |path|
      FileUtils.rm_f(path)
    }
  end

  ##
  # The method helps to load cached json.
  # This cache is permanent and reload only if no exist or set demand_reload
  #
  # @param [UU::OS::UESURI] binary_ap_uri UU::OS::UESURI of property to load with caching.
  # @param [Hash] params Load parameters
  # @option params [Hash] :json Optional parameters. Json parse attributes. Default is {symbolize_names:true}.
  # @option params [Fixnum] :ttl Optional parameters. Time to live in second, for this time duration will be load property from json_cache file. Default is 10800.
  # @option params [Boolean] :demanded_reload Optional parameters. Flag to reload value from property. Default is false.
  #
  # @return [Hash] hash_value
  #
  # @yield return value must be Hash
  def self.load_cached(key, params = {}, &block)
    default_load_attrs = {
        update: false,
        json: {symbolize_names: true},
        ttl: 0,
        demanded_reload: false
    }
    params = default_load_attrs.merge(params)
    hash = {}

    cache_dir_path = "#{Dir.tmpdir}/#{BrowserWebData::TMP_DIR}"
    Dir.mkdir(cache_dir_path) unless Dir.exist?(cache_dir_path)
    cache_file_path = "#{cache_dir_path}/#{StringHelper.get_clear_file_path(key)}.json"

    if params[:demanded_reload] || !File.exists?(cache_file_path) || (params[:ttl] && Time.now - File.ctime(cache_file_path) > params[:ttl])

      if block_given?
        hash = yield hash
        File.open(cache_file_path, 'w') { |f| f.puts hash.to_json } unless hash.empty?
      end
    else
      hash = JSON.parse(File.read(cache_file_path).force_encoding('UTF-8'), params[:json])

    end

    HashHelper.recursive_symbolize_keys(hash)
  end

  def self.update_knowledge(type)
    dir_path = "#{File.dirname(File.expand_path('..', __FILE__))}/knowledge"
    file_path = "#{dir_path}/#{StringHelper.get_clear_file_path(type)}.json"

    hash = {}
    if !File.exists?(file_path)

      if block_given?
        hash = yield hash
        File.open(file_path, 'w') { |f| f.puts hash.to_json } unless hash.empty?
      end
    else
      old_hash = JSON.parse(File.read(file_path).force_encoding('UTF-8'), symbolize_names: true)
      hash = yield old_hash
      File.open(file_path, 'w') { |f| f.puts hash.to_json } unless hash.empty?
    end

    HashHelper.recursive_symbolize_keys(hash)
  end

  def self.load_knowledge(type)
    dir_path = "#{File.dirname(File.expand_path('..', __FILE__))}/knowledge"
    file_path = "#{dir_path}/#{StringHelper.get_clear_file_path(type)}.json"

    JSON.parse(File.read(file_path), symbolize_names: true)
  end

end