module ApiBlueprint::Collect::SpecHook
  def self.included(base)
    base.before do
      data = {
        'title' => example.metadata.full_description,
        'title_parts' => example_description_parts
      }

      File.write(ApiBlueprint::Collect::Storage.spec_dump, data.to_yaml)
    end
  end

  private

  def example_description_parts
    parts = []
    at = example.metadata

    while at && at[:description_args]
      parts << at[:description_args].join(' ')
      at = at[:example_group]
    end

    parts.reverse!
  end
end
