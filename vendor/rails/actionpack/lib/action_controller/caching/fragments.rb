module ActionController #:nodoc:
  module Caching
    # Fragment caching is used for caching various blocks within templates without caching the entire action as a whole. This is useful when
    # certain elements of an action change frequently or depend on complicated state while other parts rarely change or can be shared amongst multiple
    # parties. The caching is done using the cache helper available in the Action View. A template with caching might look something like:
    #
    #   <b>Hello <%= @name %></b>
    #   <% cache do %>
    #     All the topics in the system:
    #     <%= render :partial => "topic", :collection => Topic.find(:all) %>
    #   <% end %>
    #
    # This cache will bind to the name of the action that called it, so if this code was part of the view for the topics/list action, you would 
    # be able to invalidate it using <tt>expire_fragment(:controller => "topics", :action => "list")</tt>. 
    # 
    # This default behavior is of limited use if you need to cache multiple fragments per action or if the action itself is cached using 
    # <tt>caches_action</tt>, so we also have the option to qualify the name of the cached fragment with something like:
    #
    #   <% cache(:action => "list", :action_suffix => "all_topics") do %>
    #
    # That would result in a name such as "/topics/list/all_topics", avoiding conflicts with the action cache and with any fragments that use a 
    # different suffix. Note that the URL doesn't have to really exist or be callable - the url_for system is just used to generate unique 
    # cache names that we can refer to when we need to expire the cache. 
    # 
    # The expiration call for this example is:
    # 
    #   expire_fragment(:controller => "topics", :action => "list", :action_suffix => "all_topics")
    module Fragments
      def self.included(base) #:nodoc:
        base.class_eval do
          class << self
            def fragment_cache_store=(store_option) #:nodoc:
              ActiveSupport::Deprecation.warn('The fragment_cache_store= method is now use cache_store=')
              self.cache_store = store_option
            end
          
            def fragment_cache_store #:nodoc:
              ActiveSupport::Deprecation.warn('The fragment_cache_store method is now use cache_store')
              cache_store
            end
          end

          def fragment_cache_store=(store_option) #:nodoc:
            ActiveSupport::Deprecation.warn('The fragment_cache_store= method is now use cache_store=')
            self.cache_store = store_option
          end
        
          def fragment_cache_store #:nodoc:
            ActiveSupport::Deprecation.warn('The fragment_cache_store method is now use cache_store')
            cache_store
          end
        end
      end

      # Given a key (as described in <tt>expire_fragment</tt>), returns a key suitable for use in reading, 
      # writing, or expiring a cached fragment. If the key is a hash, the generated key is the return
      # value of url_for on that hash (without the protocol). All keys are prefixed with "views/" and uses
      # ActiveSupport::Cache.expand_cache_key for the expansion.
      def fragment_cache_key(key)
        ActiveSupport::Cache.expand_cache_key(key.is_a?(Hash) ? url_for(key).split("://").last : key, :views)
      end

      def fragment_for(buffer, name = {}, options = nil, &block) #:nodoc:
        if perform_caching
          if cache = read_fragment(name, options)
            buffer.concat(cache)
          else
            pos = buffer.length
            block.call
            write_fragment(name, buffer[pos..-1], options)
          end
        else
          block.call
        end
      end

      # Writes <tt>content</tt> to the location signified by <tt>key</tt> (see <tt>expire_fragment</tt> for acceptable formats)
      def write_fragment(key, content, options = nil)
        return unless cache_configured?

        key = fragment_cache_key(key)

        self.class.benchmark "Cached fragment miss: #{key}" do
          cache_store.write(key, content, options)
        end

        content
      end

      # Reads a cached fragment from the location signified by <tt>key</tt> (see <tt>expire_fragment</tt> for acceptable formats)
      def read_fragment(key, options = nil)
        return unless cache_configured?

        key = fragment_cache_key(key)

        self.class.benchmark "Cached fragment hit: #{key}" do
          cache_store.read(key, options)
        end
      end

      # Check if a cached fragment from the location signified by <tt>key</tt> exists (see <tt>expire_fragment</tt> for acceptable formats)
      def fragment_exist?(key, options = nil)
        return unless cache_configured?

        key = fragment_cache_key(key)

        self.class.benchmark "Cached fragment exists?: #{key}" do
          cache_store.exist?(key, options)
        end
      end

      # Name can take one of three forms:
      # * String: This would normally take the form of a path like "pages/45/notes"
      # * Hash: Is treated as an implicit call to url_for, like { :controller => "pages", :action => "notes", :id => 45 }
      # * Regexp: Will destroy all the matched fragments, example:
      #     %r{pages/\d*/notes}
      #   Ensure you do not specify start and finish in the regex (^$) because
      #   the actual filename matched looks like ./cache/filename/path.cache
      #   Regexp expiration is only supported on caches that can iterate over
      #   all keys (unlike memcached).
      def expire_fragment(key, options = nil)
        return unless cache_configured?

        key = key.is_a?(Regexp) ? key : fragment_cache_key(key)

        if key.is_a?(Regexp)
          self.class.benchmark "Expired fragments matching: #{key.source}" do
            cache_store.delete_matched(key, options)
          end
        else
          self.class.benchmark "Expired fragment: #{key}" do
            cache_store.delete(key, options)
          end
        end
      end
    end
  end
end
