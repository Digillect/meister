module Meister
  class ComponentSnapshot
    attr_reader :name
    attr_accessor :sha, :ref

    def initialize(name, ref_or_hash, sha = nil)
      @name = name.to_s

      if ref_or_hash.is_a? Hash
        @ref = ref_or_hash[:ref].to_s
        @sha = ref_or_hash[:sha].to_s
      else
        @ref = ref_or_hash
        @sha = sha || 'master'
      end
    end

    def to_h
      { sha: @sha, ref: @ref }
    end
  end
end
