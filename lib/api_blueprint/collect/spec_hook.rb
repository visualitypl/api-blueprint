module ApiBlueprint::Collect::SpecHook
  def self.included(base)
    return unless ENV['API_BLUEPRINT_DUMP'] == '1'

    base.before(:each) do |example|
      data = {
        'title_parts' => example_description_parts(example)
      }

      File.write(ApiBlueprint::Collect::Storage.spec_dump, data.to_yaml)
    end
  end

  private

  def example_description_parts(example)
    parts = []
    parts << example.metadata[:description_args].join(' ')
    at = example.metadata[:example_group]

    while at && at[:description_args]
      parts << at[:description_args].join(' ')
      at = at[:parent_example_group]
    end

    parts.reverse!
  end
end
