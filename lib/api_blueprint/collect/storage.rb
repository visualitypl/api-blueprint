module ApiBlueprint::Collect::Storage
  def self.request_dumps
    Dir[Rails.root.join('tmp', 'api_blueprint_request_*.yml').to_s]
  end

  def self.spec_dump
    Rails.root.join('tmp', 'api_blueprint_spec.yml')
  end

  def self.request_dump
    Rails.root.join('tmp',
      "api_blueprint_request_#{(Time.now.to_f * 1000).to_i}_#{sprintf("%09d", rand(1e9))}.yml")
  end
end
