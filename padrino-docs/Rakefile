require 'bundler/setup'
require 'mongo'
require 'net/ssh/gateway'
require 'yaml'
require 'pandoc-ruby'

def on_remote(&block)
  gateway = Net::SSH::Gateway.new('lps2.lipsiasoft.com', 'root')

  # Open port 27018 to forward to 127.0.0.1:27017
  # on the remote host provided above
  gateway.open('127.0.0.1', 27017, 27018)

  # Connect to local port set in previous statement
  conn = Mongo::Connection.new('127.0.0.1', 27018)
  @_db = conn['padrino_www']

  # Invoke block with current db
  yield @_db

  # Just printing out stats to show that it works
  # p conn.db('padrino_www').stats
ensure
  gateway.shutdown!
end

def db
  @_db
end

def category_name(id)
  cat = db['categories'].find_one(_id: id)
  cat['name'] if cat
end

def convert(code, *args)
  args.push({ from: :html, to: 'markdown_github+fenced_code_blocks', columns: 110 }, 'atx-headers', 'normalize')
  PandocRuby.convert(code, *args)
end

def gen(kind, doc)
  account    = db['accounts'].find_one(_id: doc['author_id'])
  categories = doc['category_ids'] ? doc['category_ids'].map(&method(:category_name)) : []
  metadata   = {}
  metadata['date']       = Date.parse(doc['created_at'].to_s)
  metadata['author']     = account['name']
  metadata['email']      = account['email']
  metadata['categories'] = categories.join(', ') unless categories.empty?
  metadata['tags']       = doc['tags'] if doc['tags']
  metadata['title']      = doc['title'].strip.gsub(/\r|\n/, '')

  file = "./#{kind}/#{doc['permalink']}.md"
  puts "  writing #{file} ..."

  File.open(file, 'w') do |f|
    f.write YAML.dump(metadata)
    f.puts '---'
    f.puts
    if doc['summary_html'] && !doc['summary_html'].empty?
      f.write convert(doc['summary_html'])
      f.write "\n\n<break>\n\n" unless doc['body_html'].nil? || doc['body_html'].empty?
    end
    f.write convert(doc['body_html'])
  end
end

desc 'Download new stuff'
task :download do
  on_remote do
    %w[posts guides pages].each do |kind|
      puts "Downloading #{kind} ..."
      db[kind].find.each { |doc| gen(kind, doc) }
    end
  end
end
