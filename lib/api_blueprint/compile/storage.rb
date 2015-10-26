module ApiBlueprint::Compile::Storage
  def self.root_join(*parts)
    File.join(File.dirname(__dir__), *parts)
  end

  def self.index_html
    root_join('lib', 'blueprint', 'compile', 'assets', 'index.html')
  end

  def self.javascripts
    Dir[root_join('lib', 'blueprint', 'compile', 'assets', '*.js').to_s]
  end

  def self.stylesheets
    Dir[root_join('lib', 'blueprint', 'compile', 'assets', '*.scss').to_s]
  end
end
