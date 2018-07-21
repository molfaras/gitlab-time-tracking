class User
  extend AuthenticationHelper

  attr_reader :attributes

  def initialize(hash)
    @attributes = hash
  end

  def to_hash
    @attributes
  end

  def method_missing(meth, *args, &block)
    if attributes.has_key?(meth.to_s)
      attributes[meth.to_s]
    else
      super
    end
  end

  def api
    Api::Gitlab.new(private_token: self.private_token)
  end
end
