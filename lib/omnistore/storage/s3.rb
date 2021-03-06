require 'aws-sdk'
require 'omnistore/storage/s3/mountpoint'

module OmniStore
  module Storage
    module S3
      extend self

      def mount!
        @@keys = {}
        case mountpoint = OmniStore::Config.mountpoint
        when Array
          mountpoint.each do |m|
            b = validate(m)
            @@keys[m] = {:name => m, :bucket => b}
          end
        when Hash
          mountpoint.each do |k,v|
            b = validate(v)
            @@keys[k] = {:name => k, :bucket => b}
          end
        else
          m = mountpoint.to_s
          b = validate(m)
          @@keys[m] = {:name => m, :bucket => b}
        end
      end

      def mountpoint(key = @@keys.keys.first)
        new_mountpoint(key)
      end

      def exist?(path, mp = mountpoint)
        mp.exist?(path)
      end
      alias :find :exist?

      def delete(path, options = {}, mp = mountpoint)
        mp.delete(path, options)
      end

      def read(path, options = {}, mp = mountpoint, &block)
        mp.read(path, options, &block)
      end

      def write(path, options_or_data = nil, options = {}, mp = mountpoint)
        mp.write(path, options_or_data, options)
      end

      def each(&block)
        if block_given?
          @@keys.each{|key| yield new_mountpoint(key) }
        else
          Enumerator.new(@@keys.map{|key| new_mountpoint(key)})
        end
      end

      private

      def validate(name)
        bucket = AWS::S3.new(options).buckets[name]
        raise OmniStore::Errors::InvalidMountpoint, "Bucket '#{name}' is not found." unless bucket.exists?
        bucket
      end

      def options
        opts = {}
        opts[:access_key_id]     = OmniStore::Config.access_key if OmniStore::Config.access_key
        opts[:secret_access_key] = OmniStore::Config.secret_key if OmniStore::Config.secret_key
        opts[:s3_endpoint]       = OmniStore::Config.endpoint   if OmniStore::Config.endpoint
        opts[:proxy_uri]         = OmniStore::Config.proxy_uri  if OmniStore::Config.proxy_uri
        opts
      end

      def new_mountpoint(key)
        return nil unless @@keys.key?(key)
        Mountpoint.new(@@keys[key][:name], @@keys[key][:bucket])
      end
    end
  end
end
