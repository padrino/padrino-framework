padrino_gemspec = ::Gem::Specification.load(File.expand_path(File.dirname(__FILE__) + "/padrino.gemspec"))
performance_gemspec = ::Gem::Specification.load(File.expand_path(File.dirname(__FILE__) + "/../padrino-performance/padrino-performance.gemspec"))

PADRINO_SUBGEMS ||= Hash[padrino_gemspec.dependencies.map{ |gem| [gem.name, gem.requirement.to_s] }]

PADRINO_GEMS ||= PADRINO_SUBGEMS.merge(
  'padrino' => padrino_gemspec.version.to_s,
  'padrino-performance' => performance_gemspec.version.to_s,
)
