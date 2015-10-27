module ApiBlueprint::Compile::Storage
  def self.root_join(*parts)
    File.join(File.dirname(__FILE__), *parts)
  end

  def self.index_html
    root_join('assets', 'index.html')
  end

  def self.javascripts
    Dir[root_join('assets', '*.js').to_s]
  end

  def self.stylesheets
    Dir[root_join('assets', '*.scss').to_s]
  end
end
